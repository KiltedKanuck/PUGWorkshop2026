<#
.SYNOPSIS
    Generates a timeline table showing when ABL Sessions (worker threads) were spawned for each PASOE agent.

.DESCRIPTION
    Parses a PASOE Agent log file to extract session spawn events and creates a markdown table
    showing the timeline of when each session was created for each agent process (PID).

.PARAMETER LogFilePath
    Path to the PASOE agent log file (e.g., <ablapp>.agent.<date>.log)

.PARAMETER OutputPath
    Path where the markdown table will be saved. 
    Default: SessionTimeline.md in the same directory as the log file

.EXAMPLE
    .\Generate-SessionTimeline.ps1 -LogFilePath ".\<ablapp>.agent.<date>.log"

.EXAMPLE
    .\Generate-SessionTimeline.ps1 -LogFilePath ".\<ablapp>.agent.<date>.log" -OutputPath ".\MyTimeline.md"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Path to the PASOE Agent log file")]
    [string]$LogFilePath,

    [Parameter(Mandatory=$false, HelpMessage="Output path for the markdown table")]
    [string]$OutputPath
)

#region Functions

function Get-AgentPIDsFromLog {
    param([string]$LogFile)
    
    Write-Verbose "Auto-detecting agent PIDs from log file..."
    $pids = Select-String -Path $LogFile -Pattern "Spawning New Worker Thread" | 
        ForEach-Object { 
            $parts = $_.Line -split '\s+'
            [int]$parts[1]
        } | 
        Select-Object -Unique | 
        Sort-Object
    
    Write-Verbose "Found $($pids.Count) unique PIDs in log file"
    return $pids
}

function Get-SessionSpawnEvents {
    param(
        [string]$LogFile,
        [int[]]$AgentPIDs
    )
    
    Write-Host "Parsing log file for session spawn and completion events..."
    
    # Two separate simple searches - much faster than complex regex
    Write-Progress -Activity "Parsing Log File" -Status "Reading session start events..." -PercentComplete 20
    $startLines = Select-String -Path $LogFile -Pattern "Starting MSAS Session" | 
        Where-Object { $_.Line -notmatch '\s(AS-Listener|AS-ResourceMgr|AS-Admin)\s' }
    
    Write-Progress -Activity "Parsing Log File" -Status "Reading completion events..." -PercentComplete 60
    $completeLines = Select-String -Path $LogFile -Pattern "ABL Session successfully started" | 
        Where-Object { $_.Line -notmatch '\s(AS-Listener|AS-ResourceMgr|AS-Admin)\s' }
    
    Write-Progress -Activity "Parsing Log File" -Status "Processing events..." -PercentComplete 85
    
    $allEvents = @{}
    $sessionStartTimes = @{}  # Track session start times: Key = PID-SessionNum, Value = StartTime
    $sessionsByPidNum = @{}   # Track spawn events: Key = PID-SessionNum, Value = spawn event info
    $totalEvents = 0
    
    # Build PID lookup for faster filtering
    $pidSet = @{}
    foreach ($apid in $AgentPIDs) {
        $pidSet[$apid] = $true
    }
    
    $allEvents = @{}
    $sessionsByPidNum = @{}
    $totalEvents = 0
    
    # Collect ALL start events from "Starting MSAS Session"
    foreach ($line in $startLines) {
        # Pattern: "AS-X ... Starting MSAS Session" 
        if ($line.Line -match '^(\S+)\s+(\d+)\s+\d+\s+\d+\s+AS-(\d+)\s+.*Starting MSAS Session') {
            $timestamp = $matches[1]
            $agentPid = [int]$matches[2]
            $sessionNum = $matches[3]
            
            if ($pidSet.ContainsKey($agentPid)) {
                $key = "$agentPid-$sessionNum"
                
                # Only add if not already added (first event wins)
                if (-not $sessionsByPidNum.ContainsKey($key)) {
                    # Store in timeline
                    if (-not $allEvents.ContainsKey($timestamp)) {
                        $allEvents[$timestamp] = @{}
                    }
                    $allEvents[$timestamp][$agentPid] = @{
                        'SessionNum' = $sessionNum
                        'SpawnTime' = $timestamp
                        'Duration' = $null
                    }
                    
                    $sessionsByPidNum[$key] = $allEvents[$timestamp][$agentPid]
                    $totalEvents++
                }
            }
        }
    }
    
    Write-Host "  - Found $totalEvents total start events"
    
    # Now remove auxiliary threads when we encounter them in start/complete events
    $auxiliaryThreads = @{}
    foreach ($line in $startLines + $completeLines) {
        if ($line.Line -match '^\S+\s+(\d+)\s+\d+\s+\d+\s+(AS-\S+)\s+') {
            $agentPid = [int]$matches[1]
            $sessionName = $matches[2]
            
            if ($pidSet.ContainsKey($agentPid)) {
                # If it's NOT a numeric worker session, it's auxiliary
                if ($sessionName -notmatch '^AS-\d+$') {
                    # Extract session number from auxiliary threads like AS-Aux-5, AS-Aux-9
                    if ($sessionName -match 'AS-\S+-(\d+)$') {
                        $sessionNum = $matches[1]
                        $key = "$agentPid-$sessionNum"
                        $auxiliaryThreads[$key] = $true
                    }
                }
            }
        }
    }
    
    # Remove auxiliary threads from our timeline
    $removedCount = 0
    foreach ($key in $auxiliaryThreads.Keys) {
        if ($sessionsByPidNum.ContainsKey($key)) {
            $parts = $key -split '-'
            $agentPid = [int]$parts[0]
            
            # Find and remove from allEvents
            foreach ($timestamp in $allEvents.Keys) {
                if ($allEvents[$timestamp].ContainsKey($agentPid)) {
                    $sessionInfo = $allEvents[$timestamp][$agentPid]
                    if ("$agentPid-$($sessionInfo.SessionNum)" -eq $key) {
                        $allEvents[$timestamp].Remove($agentPid)
                        if ($allEvents[$timestamp].Count -eq 0) {
                            $allEvents.Remove($timestamp)
                        }
                        break
                    }
                }
            }
            
            $sessionsByPidNum.Remove($key)
            $removedCount++
        }
    }
    
    Write-Host "  - Removed $removedCount auxiliary threads"
    Write-Host "  - Remaining worker sessions: $($sessionsByPidNum.Count)"
    
    # Process completion events and calculate durations
    foreach ($line in $completeLines) {
        if ($line.Line -match '^(\S+)\s+(\d+)\s+\d+\s+\d+\s+AS-(\d+)\s+') {
            $timestamp = $matches[1]
            $agentPid = [int]$matches[2]
            $sessionNum = $matches[3]
            
            if ($pidSet.ContainsKey($agentPid)) {
                $key = "$agentPid-$sessionNum"
                
                # Calculate duration if we have the start event AND haven't already calculated it
                if ($sessionsByPidNum.ContainsKey($key) -and $sessionsByPidNum[$key].Duration -eq $null) {
                    $endTime = [DateTime]::Parse($timestamp)
                    $startTime = [DateTime]::Parse($sessionsByPidNum[$key].SpawnTime)
                    
                    if ($startTime -ne $null) {
                        $duration = ($endTime - $startTime).TotalMilliseconds
                        $sessionsByPidNum[$key].Duration = [math]::Round($duration)
                    }
                }
            }
        }
    }
    
    Write-Progress -Activity "Parsing Log File" -Completed
    
    # Diagnostic info
    $spawnsWithDuration = ($sessionsByPidNum.Values | Where-Object { $_.Duration -ne $null }).Count
    $spawnsWithoutDuration = ($sessionsByPidNum.Values | Where-Object { $_.Duration -eq $null }).Count
    
    Write-Host "Found $($sessionsByPidNum.Count) worker sessions across $($allEvents.Count) unique timestamps"
    Write-Host "  - Completed sessions: $spawnsWithDuration"
    Write-Host "  - Incomplete sessions: $spawnsWithoutDuration"
    
    if ($spawnsWithoutDuration -gt 0) {
        Write-Host "`nWarning: $spawnsWithoutDuration sessions started but no completion found" -ForegroundColor Yellow
        Write-Host "(These sessions may have crashed, timed out, or were still running when logging ended)" -ForegroundColor Gray
        
        # Show first few examples
        $missingDurations = @()
        foreach ($key in $sessionsByPidNum.Keys) {
            if ($sessionsByPidNum[$key].Duration -eq $null) {
                $missingDurations += $key
            }
        }
        
        $missingDurations | Select-Object -First 5 | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Yellow
        }
        if ($missingDurations.Count -gt 5) {
            Write-Host "  ... and $($missingDurations.Count - 5) more" -ForegroundColor Yellow
        }
    }
    
    return $allEvents
}

function Build-TimelineTable {
    param(
        [hashtable]$Events,
        [int[]]$AgentPIDs,
        [string]$OutputFile
    )
    
    Write-Host "Building timeline table..."
    
    # Sort timestamps
    $sortedTimes = $Events.Keys | Sort-Object
    
    # Build the markdown table
    $sb = New-Object System.Text.StringBuilder
    
    # Header section
    [void]$sb.AppendLine("# Worker Thread Spawn Timeline Table")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("<style>")
    [void]$sb.AppendLine("table { white-space: nowrap; }")
    [void]$sb.AppendLine("td, th { white-space: nowrap; }")
    [void]$sb.AppendLine("</style>")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("This table shows when each ABL Session (worker thread) was spawned for each PASOE agent process.")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Summary")
    [void]$sb.AppendLine("- **Total Agents:** $($AgentPIDs.Count)")
    [void]$sb.AppendLine("- **Total Spawn Events:** $(($Events.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)")
    [void]$sb.AppendLine("- **Unique Timestamps:** $($sortedTimes.Count)")
    
    if ($sortedTimes.Count -gt 0) {
        # Extract time strings directly to avoid timezone conversion
        # Timestamp format: 2026-07-29T13:11:38.056+0000
        if ($sortedTimes[0] -match '^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})') {
            $startDate = $matches[1]
            $startTimeStr = $matches[2]
        }
        if ($sortedTimes[-1] -match '^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})') {
            $endDate = $matches[1]
            $endTimeStr = $matches[2]
        }
        
        # Calculate duration using DateTime
        $startTime = [DateTime]::Parse($sortedTimes[0], [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $endTime = [DateTime]::Parse($sortedTimes[-1], [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $duration = $endTime - $startTime
        
        # Format the time range using extracted strings
        $startFormatted = "$startDate $startTimeStr"
        $endFormatted = $endTimeStr
        
        # If different days, show full date for end time too
        if ($startDate -ne $endDate) {
            $endFormatted = "$endDate $endTimeStr"
        }
        
        # Format duration nicely
        if ($duration.TotalHours -ge 1) {
            $durationStr = "{0:hh\:mm\:ss}" -f $duration
        } elseif ($duration.TotalMinutes -ge 1) {
            $durationStr = "{0:mm\:ss}" -f $duration
        } else {
            $durationStr = "{0:ss\.fff}s" -f $duration
        }
        
        [void]$sb.AppendLine("- **Time Range (UTC):** $startFormatted to $endFormatted (Duration: $durationStr)")
    }
    
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("## Table Key")
    [void]$sb.AppendLine("- Columns = MSAgent Process (PID)")
    [void]$sb.AppendLine("- Rows = Timestamp (UTC) when a session was spawned")
    [void]$sb.AppendLine("- Cell format = Session ID (startup duration in ms)")
    [void]$sb.AppendLine("- Empty cells = No session spawned by agent at time")
    [void]$sb.AppendLine("")
    
    # Table header
    $headerRow = "| Time |"
    $separatorRow = "|------|"
    
    foreach ($apid in $AgentPIDs) {
        $headerRow += " $apid |"
        $separatorRow += "-------|"
    }
    
    [void]$sb.AppendLine($headerRow)
    [void]$sb.AppendLine($separatorRow)
    
    # Table rows
    $rowCount = 0
    foreach ($timestamp in $sortedTimes) {
        $rowCount++
        
        if ($rowCount % 100 -eq 0) {
            Write-Progress -Activity "Building Table" -Status "Processing row $rowCount of $($sortedTimes.Count)" -PercentComplete (($rowCount / $sortedTimes.Count) * 100)
        }
        
        # Extract time directly from timestamp string to avoid timezone conversion
        # Timestamp format: 2026-07-29T13:11:38.056+0000
        if ($timestamp -match 'T(\d{2}:\d{2}:\d{2}\.\d{3})') {
            $formattedTime = $matches[1]
        } else {
            # Fallback if pattern doesn't match
            $formattedTime = $timestamp
        }
        
        $row = "| **$formattedTime** |"
        
        foreach ($apid in $AgentPIDs) {
            if ($Events[$timestamp].ContainsKey($apid)) {
                $sessionInfo = $Events[$timestamp][$apid]
                $sessionNum = $sessionInfo.SessionNum
                
                # Format with duration if available
                if ($sessionInfo.Duration -ne $null) {
                    $row += " $sessionNum ($($sessionInfo.Duration)ms) |"
                }
                else {
                    $row += " $sessionNum |"
                }
            }
            else {
                $row += " |"
            }
        }
        
        [void]$sb.AppendLine($row)
    }
    
    Write-Progress -Activity "Building Table" -Completed
    
    # Write to file
    $sb.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "Table generation complete!" -ForegroundColor Green
}

#endregion

#region Main Script

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "PASOE Session Timeline Generator" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Show usage if no log file provided
    if (-not $LogFilePath) {
        Write-Host "USAGE:" -ForegroundColor Yellow
        Write-Host "  .\Generate-SessionTimeline.ps1 -LogFilePath `"<path-to-agent-log>`"`n"
        Write-Host "EXAMPLES:" -ForegroundColor Yellow
        Write-Host "  .\Generate-SessionTimeline.ps1 -LogFilePath `".\<ablapp>.agent.<date>.log`""
        Write-Host "  .\Generate-SessionTimeline.ps1 -LogFilePath `".\<ablapp>.agent.<date>.log`" -OutputPath `".\MyTimeline.md`"`n"
        Write-Host "PARAMETERS:" -ForegroundColor Yellow
        Write-Host "  -LogFilePath : Path to the PASOE agent log file (required)"
        Write-Host "  -OutputPath  : Output path for timeline table (default: SessionTimeline.md in same directory as log file)`n"
        exit 0
    }
    
    # Validate log file exists
    if (-not (Test-Path $LogFilePath -PathType Leaf)) {
        throw "Log file not found: $LogFilePath"
    }
    
    # Set default output path to same directory as log file if not specified
    if (-not $OutputPath) {
        $logDir = Split-Path -Parent $LogFilePath
        $OutputPath = Join-Path $logDir "SessionTimeline.md"
    }
    
    # Auto-detect PIDs from log file
    $agentPIDs = Get-AgentPIDsFromLog -LogFile $LogFilePath
    Write-Host "Auto-detected $($agentPIDs.Count) agent PIDs from log file"
    
    if ($agentPIDs.Count -eq 0) {
        throw "No agent PIDs found. Please check your log file or specify PIDs manually."
    }
    
    Write-Verbose "Agent PIDs: $($agentPIDs -join ', ')"
    
    # Parse log for spawn events
    $spawnEvents = Get-SessionSpawnEvents -LogFile $LogFilePath -AgentPIDs $agentPIDs
    
    if ($spawnEvents.Count -eq 0) {
        throw "No spawn events found in log file. Please check the log file format."
    }
    
    # Build and save the table
    Build-TimelineTable -Events $spawnEvents -AgentPIDs $agentPIDs -OutputFile $OutputPath
    
    Write-Host "`nOutput saved to: $(Resolve-Path $OutputPath)" -ForegroundColor Green
    Write-Host "`nStats:" -ForegroundColor Cyan
    Write-Host "  - Agents: $($agentPIDs.Count)"
    Write-Host "  - Timestamps: $($spawnEvents.Count)"
    Write-Host "  - Total Events: $(($spawnEvents.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)"
}
catch {
    Write-Error "Error generating timeline: $_"
    exit 1
}

#endregion
