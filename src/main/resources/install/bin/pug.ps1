<#
.NOTES
===========================================================================
Created on:       03/05/2026
Updated on:       03/05/2026
Created by:       dugrau
Organization:     Progress Software Corp. | OpenEdge
===========================================================================
.DESCRIPTION
This Powershell script is a called by the batch script to execute the
Ant utility in the DLC installation directory (DLC/ant). It utilizes
the XML file to configure all tasks and parameters available.
#>

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

# Define the filename and construct the full path
$CheckFile = "servers/pasoe/conf/instances.windows"
$FilePath = Join-Path -Path $env:DLC -ChildPath $CheckFile

# Ensure that the user has write access to file(s) required for PASOE tailoring.
function Test-WriteAccess {
    param ([string]$Path)

    try {
        $stream = [System.IO.File]::Open($Path, 'Open', 'Write')
        $stream.Close()
        return $true
    } catch {
        return $false
    }
}

# Initialize variable to track write access warning state
$writeAccessWarning = $false

# Provide a suitable explanation for why the script may not complete as expected due to insufficient file permissions.
if (-not (Test-WriteAccess -Path $FilePath)) {
    Write-Host "WARNING: You do not have write access to '$FilePath' which is required for registering the PASOE instance." -ForegroundColor Red
    Write-Host "SOLUTION: Please request that your system administrator add read/write access for 'Authenticated Users', or run PROENV as Administrator." -ForegroundColor Green

    # Update a variable to indicate warning was triggered.
    $writeAccessWarning = $true

    # Do not exit, but allow the script to continue with the info above. If you do want to exit just uncomment the line below:
    #exit 1
}

#---- Local Variables ----#
[string]$script:_antPath="$env:DLC\ant\bin\ant.bat"
[string]$script:_taskFilePath = Join-Path $PSScriptRoot "$([System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)).xml"
[string]$script:_taskArgs=""

# Prefix arguments with a "-D" as necessary. This allows the user to pass parameters
# without the prefix (if they forgot) and allows the task name to be anywhere within
# the list of arguments passed to this script. Note that multiple tasks may be run,
# in the order by which they are given.
foreach ($arg in $args) {
    if ($arg.Contains("=") -and $arg -notlike "-D*") {
        # Split on the first '=' to separate key and value
        $splitIndex = $arg.IndexOf('=')
        $key = $arg.Substring(0, $splitIndex)
        $value = $arg.Substring($splitIndex + 1)

        # If value contains spaces and isn't already quoted, add quotes
        if ($value.Contains(' ') -and -not (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $thisArg = " -D$key=`"$value`""
        } else {
            $thisArg = " -D$arg"
        }
    }
    else {
        $thisArg = " $arg"
    }
    $script:_taskArgs += $thisArg
}

# Set a local variable for the default WRKDIR if present, expanding to the full Windows path.
if ($env:WRKDIR) {
    $WrkDir = Get-LongPath $env:WRKDIR
}

# Check if wrkDir argument was passed, if not add it with the local $WrkDir variable value.
$wrkDirArgPassed = $false
foreach ($arg in $args) {
    if ($arg -like "*wrkDir=*" -or $arg -like "-DwrkDir=*") {
        $wrkDirArgPassed = $true
        break
    }
}

# If no wrkDir argument was passed and we have a $WrkDir value, add it.
if (-not $wrkDirArgPassed -and $WrkDir) {
    $script:_taskArgs += " -DwrkDir=`"$WrkDir`""
}

# Add a special writeAccessWarning parameter if write access warning was detected at the OS level.
if ($writeAccessWarning) {
    $script:_taskArgs += " -DwriteAccessWarning=true"
}

# Detect hardware resources and pass them as properties to the Ant tasks.

# CPU count: use the built-in env var (always set on Windows), fall back to 1.
$cpuCount = try { [int]$env:NUMBER_OF_PROCESSORS } catch { 1 }
if (-not $cpuCount -or $cpuCount -lt 1) { $cpuCount = 1 }

# Total memory: query WMI for total physical memory in MB, fall back to 0.
$totalMemoryMB = try {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    [math]::Floor($cs.TotalPhysicalMemory / 1MB)
} catch { 0 }

# Hostname: use the built-in env var, always set on Windows.
$systemHostname = $env:COMPUTERNAME

# Append detected values to the task arguments for Ant.
$script:_taskArgs += " -DsystemCpuCount=$cpuCount -DsystemMemorySize=$totalMemoryMB -DsystemHostname=$systemHostname"

# Run the ant utility from DLC/ant as previously discovered.
Invoke-Expression "& `"$script:_antPath`" -f `"$script:_taskFilePath`" $script:_taskArgs"

# SIG # Begin signature block
# SIG # End signature block
