# PASOE Tuning

## Installed Defaults

When creating the OELS instance using the provided defaults the following values will be set automatically.

| Property | Default Value |
|----------|---------------|
| minAgents | 2 |
| maxAgents | 2 |
| numInitialAgents | 2 |
| maxABLSessionsPerAgent | 120 |
| maxConnectionsPerAgent | 120 |
| numInitialSessions | 10 |
| minAvailableABLSessions | 1 |
| psc.as.executor.maxthreads | 600 |

## Customer Example

Based on one customer application configuration for the replicated customer environment the following settings may be used.

| Property | Default Value |
|----------|---------------|
| minAgents | 1  |
| maxAgents | 20 |
| numInitialAgents | 1 |
| maxABLSessionsPerAgent | 50 |
| maxConnectionsPerAgent | 50 |
| numInitialSessions | 5 |
| minAvailableABLSessions | 1 |
| psc.as.executor.maxthreads | 1500 |

* Min Port: 61002
* Max Port: 64202
