# PowerShell script to stop any background processes

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
    $env:DLC = "@DLCHOME@"
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

#
# Stop the database for the PAS instance.
#
Write-Host "Shutting down $DBNAME database."
$proshutPath = Join-Path $env:DLC "bin\proshut.bat"
$dbPath = Join-Path $env:DBDIR "$DBNAME.db"
$args = "-by `"$dbPath`""
Write-Host "Running: $proshutPath $args"
$process = Start-Process -FilePath $proshutPath -ArgumentList $args -NoNewWindow -Wait -PassThru
Write-Host "Exit code from proshut: $($process.ExitCode)"

# Explicitly exit, gracefully
exit 0
