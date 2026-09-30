OpenEdge Load Suite - Server Installation

This package contains the server-side installation and management utility for creating
and maintaining a PASOE instance and its database-backed test environment.


Prerequisites:

- A 64-bit operating system is required.
- OpenEdge 12.8.11 or later is required.
- A PAS for OpenEdge license is required, either Dev or Prod.
- An OpenEdge RDBMS installation is required, Workgroup or higher.
- Run the utility from a PROENV session so the OpenEdge environment is available:
    - The OpenEdge DLC path must be available in the environment.
    - The WRKDIR path must be available in the environment.


Usage:

- Run `bin/oels.[bat|sh] help` to view the available commands and options.
- Run `bin/oels.[bat|sh] <task>` to execute specific actions:
    - Use `install` to create and tailor the PASOE instance.
    - Use `startup` or `start` to start the instance.
    - Use `shutdown` or `stop` to stop the instance.
    - Use `restart` to restart the instance.
    - Use `query` or `status` to inspect the instance state.
    - Use `delete` or `uninstall` to remove the instance.
    - Use `generate` to seed the database with synthetic data.
    - Use `backup` to create an offline backup of the database (run `stop` prior to use).
    - Use `restore` to restore a backup file to the database (run `stop` prior to use).

Most values used by the utility come from `conf/config.properties` and can be overridden
for specific tasks when needed. See `conf/config.properties.README` for more information.

Note: A safeguard exists in the `install` task to check the total available system memory
available, and will skip or alter certain tuning parameters if below an acceptable threshold.
This prevents initial tailoring of the PASOE instance beyond what is physically possible for
the local machine. eg. Tomcat threads and heap memory will not be configured, MSAgents will
be capped at a maximum of 2 (min/max/initial). The threshold for this action is set at 14GB.


Installation:

The install process will create a new PASOE instance using the `-f` option to include the
Tomcat manager and OEManager webapps for management. Defaults for path and naming will be
reported as part of the usage information and execution of the tasks. Once created, the
following actions will be taken within the new PASOE instance:

- A new OpenEdge Application aRchive (.oear) will be imported into the PASOE instance.
- Tailoring of the OEAR (LoadSuite) will perform the following significant actions:
    - Remove the default ROOT webapp and replace with a non-OEABL version which serves
      only static content, redirecting users to the OpenAPI catalog for the application.
    - Generate a new default username and password for Tomcat/OEManager access.
    - Create the required "thrasher" database within the `CATALINA_BASE/db` directory.


Post-Install Configuration:

The installation process will use default values for several PASOE and RDBMS parameters,
all of which can be modified post-install via the followng respective files:

PASOE - OELS Instance:
    - `CATALINA_BASE/conf/openedge.properties`  - Standard PASOE configuration file
    - `CATALINA_BASE/ablapps/LoadSuite/openedge/startup.pf`  - AVM startup params
    - `CATALINA_BASE/bin/oels_setenv.[bat|sh]`  - Application environment variables
        - `USE_ORIGINAL_CONTEXT_LOGIC=[true|false]`  - Opt in (true) or out (false) of using customer-specific user context logic

RDBMS - "thrasher" Database:
    - `CATALINA_BASE/bin/dboptions.properties`  - Used by the instance_startup.* scripts
    - `CATALINA_BASE/ablapps/LoadSuite/openedge/startup.pf`  - DB client params

NOTE: The actual database connecton is controlled via the `sessionStartupProcParam`
within the `openedge.properties` file. This should ONLY set either the database name
and either a direct path (shared memory) or host and port (client-server).

