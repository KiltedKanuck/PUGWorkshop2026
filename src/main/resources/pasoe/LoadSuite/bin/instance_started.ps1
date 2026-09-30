# PowerShell script to start the watcher program for import batching

#
# Ensure that Powershell makes use of the full path name when needed
#
function Get-LongPath($shortPath) {
    $fileInfo = New-Object System.IO.FileInfo($shortPath)
    if ($fileInfo.Exists -or $fileInfo.Directory.Exists) {
        return $fileInfo.FullName
    } else {
        return $shortPath  # fallback if path doesn't exist
    }
}

if (-not $env:DLC) {
    Write-Host "DLC is not defined, using static path."
    $env:DLC = "@DLCHOME@"
} else {
    $env:DLC = Get-LongPath $env:DLC
}

if (-not $env:CATALINA_BASE) {
    Write-Host "CATALINA_BASE is not defined, using static path."
    $env:CATALINA_BASE = Get-LongPath "@PASPATH@"
} else {
    $env:CATALINA_BASE = Get-LongPath $env:CATALINA_BASE
}

if (-not $env:DBDIR) {
    $env:DBDIR = Get-LongPath "$env:CATALINA_BASE\db"
} else {
    $env:DBDIR = Get-LongPath $env:DBDIR
}

if (-not $env:TEMPDIR) {
    $env:TEMPDIR = "$env:CATALINA_BASE\temp"
}

#
# Set database parameters
#
$DBNAME = "@DBNAME@"
$DBHOST = "@DBHOST@"
$DBPORT = "@DBPORT@"
$MINPORT = "@MINPORT@"
$MAXPORT = "@MAXPORT@"
$CODEPAGE = "@CODEPAGE@"

# Load database startup options from the instance bin directory.
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$dbOptsConfigPath = Join-Path $scriptRoot "dboptions.properties"
$dbOptSpecs = @(
    @{ Name = "bibufs"; Switch = "-bibufs" },
    @{ Name = "B"; Switch = "-B" },
    @{ Name = "L"; Switch = "-L" },
    @{ Name = "Mm"; Switch = "-Mm" },
    @{ Name = "Ma"; Switch = "-Ma" },
    @{ Name = "Mpb"; Switch = "-Mpb" },
    @{ Name = "Mi"; Switch = "-Mi" },
    @{ Name = "Mn"; Switch = "-Mn" },
    @{ Name = "n"; Switch = "-n" },
    @{ Name = "spin"; Switch = "-spin" },
    @{ Name = "semsets"; Switch = "-semsets" },
    @{ Name = "Mxs"; Switch = "-Mxs" },
    @{ Name = "hash"; Switch = "-hash" },
    @{ Name = "aibufs"; Switch = "-aibufs" },
    @{ Name = "Bpmax"; Switch = "-Bpmax" },
    @{ Name = "aiarcinterval"; Switch = "-aiarcinterval" },
    @{ Name = "bithold"; Switch = "-bithold" },
    @{ Name = "Mf"; Switch = "-Mf" }
)
$dbFlagSpecs = @(
    @{ Name = "aistall"; Switch = "-aistall" },
    @{ Name = "bistall"; Switch = "-bistall" },
    @{ Name = "directio"; Switch = "-directio" }
)
$startupProcessSpecs = @(
    @{ Name = "bim"; CommandVariable = "probimCmd" },
    @{ Name = "aiw"; CommandVariable = "proaiwCmd" },
    @{ Name = "biw"; CommandVariable = "probiwCmd" }
)

$supportedPropertyNames = @{}
foreach ($spec in $dbOptSpecs) {
    $supportedPropertyNames[$spec.Name] = $true
}
foreach ($spec in $dbFlagSpecs) {
    $supportedPropertyNames[$spec.Name] = $true
}
foreach ($spec in $startupProcessSpecs) {
    $supportedPropertyNames[$spec.Name] = $true
}
$supportedPropertyNames["apw"] = $true

$propertyValues = @{}
$presentProperties = @{}

if (Test-Path $dbOptsConfigPath) {
    foreach ($line in Get-Content -Path $dbOptsConfigPath) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') {
            continue
        }

        if ($line -match '^\s*dbopt\.([A-Za-z0-9]+)\s*(?:=\s*(.*?))?\s*$') {
            $propertyName = $Matches[1]
            $propertyValue = $Matches[2]

            if ($supportedPropertyNames.ContainsKey($propertyName)) {
                $presentProperties[$propertyName] = $true
                if ($null -ne $propertyValue) {
                    $propertyValues[$propertyName] = $propertyValue.Trim()
                }
            } else {
                Write-Host "Ignoring unsupported db option property 'dbopt.$propertyName'."
            }
        }
    }

    Write-Host "Loaded DB options from $dbOptsConfigPath (unset keys are omitted)."
} else {
    Write-Host "DB options config not found at $dbOptsConfigPath. Optional db options and process startups are omitted."
}

#
# Set common variables for utilities
#
$proutilCmd = Join-Path $env:DLC "bin\proutil.bat"
$proservCmd = Join-Path $env:DLC "bin\proserve.bat"
$prowdogCmd = Join-Path $env:DLC "bin\prowdog.bat"
$probimCmd = Join-Path $env:DLC "bin\probim.bat"
$proaiwCmd = Join-Path $env:DLC "bin\proaiw.bat"
$probiwCmd = Join-Path $env:DLC "bin\probiw.bat"
$proapwCmd = Join-Path $env:DLC "bin\proapw.bat"

$dbOptsParts = @()
foreach ($spec in $dbOptSpecs) {
    if ($propertyValues.ContainsKey($spec.Name) -and $propertyValues[$spec.Name] -ne "") {
        $dbOptsParts += "$($spec.Switch) $($propertyValues[$spec.Name])"
    }
}

foreach ($spec in $dbFlagSpecs) {
    if ($presentProperties.ContainsKey($spec.Name)) {
        $dbOptsParts += $spec.Switch
    }
}

$dbOptsParts += "-minport $MINPORT"
$dbOptsParts += "-maxport $MAXPORT"
$DBOPTS = ($dbOptsParts -join " ")

$apwCount = 0
if ($propertyValues.ContainsKey("apw") -and $propertyValues["apw"] -ne "") {
    if ($propertyValues["apw"] -match '^\d+$') {
        $apwCount = [int]$propertyValues["apw"]
    } else {
        Write-Host "Ignoring invalid dbopt.apw value '$($propertyValues["apw"])' (expected integer)."
    }
}

# Common parameters
$dbPath = Join-Path $env:DBDIR "$DBNAME.db"
$errPath = Join-Path $env:TEMPDIR "dbstart.err"
$logPath = Join-Path $env:TEMPDIR "dbstart.log"
$codepageArgs = "-cpinternal $CODEPAGE -cpstream $CODEPAGE"
$holderArgs = "`"$dbPath`" -C holder"
$dbArgs = "`"$dbPath`" $codepageArgs"

#
# Check if the database is already in use (run synchronously and obtain the process object)
#
Write-Host "Running: $proutilCmd $holderArgs"
$initialCheck = Start-Process -FilePath $proutilCmd -ArgumentList $holderArgs -NoNewWindow -Wait -PassThru

if ($initialCheck.ExitCode -eq 0) {
    Write-Host "Starting database $DBNAME on port $DBPORT."
    $startArgs = "`"$dbPath`" -H $DBHOST -S $DBPORT -N TCP -ipver IPv4 $DBOPTS $codepageArgs"
    Write-Host "Running: $proservCmd $startArgs"
    Start-Process -WindowStyle Minimized -FilePath $proservCmd -ArgumentList $startArgs -RedirectStandardOutput $logPath -RedirectStandardError $errPath

    #
    # Retry Block: Check database status up to 5 times with 1-second intervals
    #
    $retryCount = 0
    $maxRetries = 5
    $exitCode = -1

    Write-Host "Waiting for database to reach ready state (return code 16)..."
    while ($retryCount -lt $maxRetries) {
        #
        # Check if the database has started yet (run synchronously and obtain the process object)
        #
        $postStartCheck = Start-Process -FilePath $proutilCmd -ArgumentList $holderArgs -NoNewWindow -Wait -PassThru
        $exitCode = $postStartCheck.ExitCode

        Write-Host "Attempt $($retryCount + 1)/$($maxRetries): proutil returned code $exitCode"

        if ($exitCode -eq 16) {
            Write-Host "Database is ready - Starting watchdog and AIW/BIW/APW processes for $DBNAME"
            Start-Process -WindowStyle Minimized -FilePath $prowdogCmd -ArgumentList $dbArgs

            foreach ($spec in $startupProcessSpecs) {
                if ($presentProperties.ContainsKey($spec.Name)) {
                    Start-Process -WindowStyle Minimized -FilePath (Get-Variable -Name $spec.CommandVariable -ValueOnly) -ArgumentList $dbArgs
                }
            }

            if ($apwCount -gt 0) {
                for ($i = 0; $i -lt $apwCount; $i++) {
                    Start-Process -WindowStyle Minimized -FilePath $proapwCmd -ArgumentList $dbArgs
                }
            }
            break
        } elseif ($exitCode -eq 0) {
            Write-Host "Return code 0: Database has not been started (will retry)"
        } else {
            Write-Host "proutil -C holder returned an unexpected code: $exitCode (will retry)"
        }

        $retryCount++

        # If we haven't reached the desired state and have more retries left, wait
        if (($exitCode -ne 16) -and ($retryCount -lt $maxRetries)) {
            Write-Host "Waiting 1 second before retry..."
            Start-Sleep -Seconds 1
        }
    }

    # Handle final state if we didn't achieve success
    if ($exitCode -ne 16) {
        if ($exitCode -eq 0) {
            Write-Host "The database could not be started after $maxRetries attempts"
        } elseif ($exitCode -eq 14) {
            Write-Host "The database is in single-user mode after $maxRetries attempts"
        } else {
            Write-Host "proutil -C holder failed after $maxRetries attempts with error code $exitCode"
        }
        Write-Host "Unable to start $DBNAME database. Final exit code: $exitCode"
    }
}

# Explicitly exit, gracefully
exit 0
