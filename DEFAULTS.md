# Build Defaults and Overrides

Gradle utilizes properties which may be set at various levels and are applied in a heirarchical manner:

1. Command Line Properties: `-P` flags
2. System Properties: eg. `system.<property_name>`
3. Properties File: `gradle.properties` file

This document explains the properties expected by the Gradle build process and values defined within the `gradle.properties` file.

## Tomcat Properties

In order to provide enough throughput for high-load testing, the default limits in Tomcat need to be increased. Notably the default of 300 executor threads is too low for high concurrency, and should be increased to a value which would allow enough requests to the configured ABL Applications, static content, and management webapps.

The Tomcat JVM heap must be sized in relation to the executor thread count, as each active thread retains live request/response objects estimated at 256KB-512KB. The JVM requires roughly 2-2.5x the live data size as total heap to allow garbage collection to operate without constant full GCs. The default Xmx is only 1024MB.

A practical baseline formula is:

    [tomcat_executor_threads] * [per_thread_estimate_mb] * [gc_headroom_multiplier] = Minimum Xmx (MB)

Example:

    2000 threads * 0.5MB * 2.5 = ~2,500MB minimum; round up generously for production loads.

Setting Xms=Xmx avoids heap-resize pauses under load. The young generation (NewSize) at ~20-25% of Xmx efficiently handles the high volume of short-lived request objects typical in a load-testing workload.

Control the executor threads for Tomcat based on the expected concurrent user load.
eg. `tomcat_executor_threads`=5000

Default the minimum spare threads to ~10% of `tomcat_executor_threads`
eg. `tomcat_min_spare_threads`=500

Adjust the Tomcat JVM options for memory as based on the executor threads and expected load:

* Xmx sized for 5K concurrent user load (5000 threads * 0.5MB * 2.5x GC headroom = ~6,250MB minimum)
eg. `tomcat_jvm_xmx_mb`=8192
* Xms avoids heap-resize pauses under load. Default: equal to `tomcat_jvm_xmx_mb`
eg. `tomcat_jvm_xms_mb`=4096
* NewSize sized for short-lived request objects. Default: ~20% of `tomcat_jvm_xmx_mb`
eg. `tomcat_jvm_new_size_mb`=768

> NOTE: At some point we may need to consider impelmenting timeout values for the Tomcat server according to this KB article: [How to configure PASOE to clean up idle resources automatically](https://community.progress.com/s/article/How-to-configure-PASOE-to-clean-up-idle-resources-automatically)

## ABL Runtime Properties

### MSAS Agents

Calculating the number of min/max MSAgents and connections should be subject to the intended installation environment and available memory, the intended number of concurrent users, and available executor threads. This requires obtaining metrics.

For example, a dedicated Linux system likely needs at least 2GB for the OS, plus 2GB for a local database server, and around 4GB for Tomcat itself (see `tomcat_jvm_xmx_mb`). Subtract this from the total available memory to determine the remainder for ABL Sessions.

Additionally, plan for a minimum buffer of 5% free memory to avoid swapping, or triggering an OOM killer watchdog when available.

A practical baseline formula is:

    [Total RAM] - 5% - [OS] - [DB] - [JAVA] = [Available Memory for ABL Sessions]

Examples (in Gigabytes):

* 64GB of RAM = 64 - 3.2 (5%) - 2 (OS) - 2 (DB) - 8 (Java) = 48.8GB available for ABL Sessions
* 128GB of RAM = 128 - 6.4 (5%) - 2 (OS) - 2 (DB) - 8 (Java) = 109.6GB available for ABL Sessions
* 256GB of RAM = 256 - 12.8 (5%) - 2 (OS) - 2 (DB) - 8 (Java) = 231.2GB available for ABL Sessions

It is crucial to know the "steady state" memory footprint for a typical ABL Session under load, in order to calculate and then size the instance appropriately. Calculate using either a formula of total desired ABL Sessions to determine system memory or divide the calculated available memory (above) by the memory footprint per ABL Session to determine the maximum numberthat can be supported.

    [Desired ABL Sessions] * [Memory Footprint per ABL Session] = [Minimum Required Memory]
    or
    [Available System Memory] / [Memory Footprint per ABL Session] = [Maximum Number of ABL Sessions]

Examples for an application with a known peak of 90MB per ABL Session:

* 200 x 90MB = Min. Required 18GB
* 300 x 90MB = Min. Required 27GB
* 400 x 90MB = Min. Required 36GB
* 500 x 90MB = Min. Required 45GB
* 1000 x 90MB = Min. Required 90GB
* 2000 x 90MB = Min. Required 180GB

Allocating these the total sessions should be accomplished by balancing the number of MSAgents and connections per agent. Just remember that each MSAgent has its own overhead, and killing an agent will kill all of its ABL Sessions.

Examples as based on the scenarios above:

* 100 = 2 MSAgents with 50 connections each, or 4 MSAgents with 25 connections each, etc.
* 200 = 4 MSAgents with 50 connections each, or 8 MSAgents with 25 connections each, etc.
* 300 = 4 MSAgents with 75 connections each, or 6 MSAgents with 50 connections each, etc.
* 400 = 8 MSAgents with 50 connections each, or 20 MSAgents with 20 connections each, etc.
* 500 = 10 MSAgents with 50 connections each, or 20 MSAgents with 25 connections each, etc.
* 1000 = 20 MSAgents with 50 connections each, or 40 MSAgents with 25 connections each, etc.
* 2000 = 40 MSAgents with 50 connections each, or consider load-balancing between multiple instances.

At a minimum there should be at least 2 MSAgents (minimum) to allow for failover, and set initial equal to the minimum.

### !!! NOTICE !!!

It has been observed that the PASOE instance may have a potential race condition when starting more than the initial number of MSAgents, causing a burst of new agents starting at once instead of 1 at a time (honoring the `agentStartLimit` property).

There is a suspicion that this property is not being honored, and is contributing to delays during this startup phase and is responsible for some of the wait times experienced by clients/requests. In order to combat this we will explicitly set the minimum/initial/maximum number of agents to the same value, preventing the race condition--but only as a workaround.

### ABL Sessions

The `minAvailableABLSessions` parameter controls how many idle ABL sessions each agent keeps ready as a proactive buffer. It is one of the most impactful tuning parameters for high-concurrency workloads and should never be left at the out-of-box default of `1`.

**Why `1` fails under load:** This application requires ~275–350ms to spawn a new ABL Session. With only one idle session per agent, the moment that session is taken the pool must spawn reactively — and every request that arrives during those 275–350ms **queues**. Under sustained concurrency the queue accumulates faster than sessions spawn, causing the session manager to hunt across all agents in desperation, prematurely activating agents and spreading sessions inefficiently. Measured at 5,000 VUs with `minAvailableABLSessions=1`: max queue wait reached **6,068ms** and the test was unable to complete successfully.

**Why `3` is the default:** Three idle sessions per agent means spawning begins in the background while two sessions are still available to absorb incoming requests. The spawn completes before the buffer is exhausted, eliminating the queue window entirely. Tested under the same conditions with `minAvailableABLSessions=3`: max queue wait dropped to **755ms** and 1.5M+ requests completed successfully.

**When to increase it:** When the duration for requests begins to climb significantly while user concurrency is increased. This can be checked via the session request average/max wait times reported by the `status` output of the OELS tooling or the similar API within the monitoring webapp. Additionally, the longer each request holds a session (read: executes application code) the faster the buffer depletes, so applications with longer average request durations require a larger buffer to absorb incoming traffic during the spawn window.

**When to leave it alone:** A value of `3` is a sufficient starting point for heavier workloads but will always vary by application needs and server capacity. Increasing it beyond what load patterns require wastes memory by holding idle sessions that will never be needed.
