<#
.SYNOPSIS
    Extracts JSON data from Grafana k6 dashboard HTML files.

.DESCRIPTION
    k6 HTML dashboards contain base64-encoded, gzipped JSON data embedded in a script tag.
    This script extracts, decodes, and decompresses that data to raw JSON.
    If no OutputPath is specified, the JSON will be saved in the same folder as the HTML file
    with the name [basename]-data.json.

.PARAMETER HtmlPath
    Path to the k6 dashboard HTML file

.PARAMETER OutputPath
    Optional path for the output JSON file. If not specified, saves to the same folder as
    the HTML file with the name [basename]-data.json.

.EXAMPLE
    .\Extract-K6Data.ps1 "dashboard.html"
    .\Extract-K6Data.ps1 -HtmlPath "dashboard.html"
    Extracts data and auto-saves to "dashboard-data.json" in the same folder

.EXAMPLE
    .\Extract-K6Data.ps1 -HtmlPath "dashboard.html" -OutputPath "data.json"
    Extracts data and saves to the specified path
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$HtmlPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

# Show usage if no HTML file provided
if (-not $HtmlPath) {
    Write-Host "`nk6 Dashboard Data Extractor" -ForegroundColor Cyan
    Write-Host "============================`n" -ForegroundColor Cyan
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\Extract-K6Data.ps1 -HtmlPath `"<path-to-dashboard.html>`"`n"
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\Extract-K6Data.ps1 -HtmlPath `"dashboard.html`""
    Write-Host "  .\Extract-K6Data.ps1 -HtmlPath `"dashboard.html`" -OutputPath `"data.json`"`n"
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -HtmlPath   : Path to the k6 dashboard HTML file (required)"
    Write-Host "  -OutputPath : Output path for JSON file (default: [basename]-data.json in same directory)`n"
    exit 0
}

# Validate HTML file exists
if (-not (Test-Path $HtmlPath -PathType Leaf)) {
    Write-Error "HTML file not found: $HtmlPath"
    exit 1
}

function Extract-K6Data {
    param([string]$Path)
    
    # Read the HTML file
    $content = Get-Content -Path $Path -Raw
    
    # Extract the base64 data from the script tag
    if ($content -match '<script id="data"[^>]*>([^<]+)</script>') {
        $base64Data = $matches[1]
        Write-Verbose "Found base64 data (length: $($base64Data.Length) characters)"
        
        # Decode from base64
        $compressedBytes = [System.Convert]::FromBase64String($base64Data)
        Write-Verbose "Decoded to $($compressedBytes.Length) bytes"
        
        # Decompress the gzip data
        $inputStream = New-Object System.IO.MemoryStream(,$compressedBytes)
        $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $outputStream = New-Object System.IO.MemoryStream
        
        $gzipStream.CopyTo($outputStream)
        $gzipStream.Close()
        $inputStream.Close()
        
        # Convert to string
        $jsonBytes = $outputStream.ToArray()
        $outputStream.Close()
        
        $jsonString = [System.Text.Encoding]::UTF8.GetString($jsonBytes)
        Write-Verbose "Decompressed to $($jsonString.Length) characters of JSON"
        
        return $jsonString
    }
    else {
        throw "Could not find data script tag in HTML file"
    }
}

# Extract the data
$jsonData = Extract-K6Data -Path $HtmlPath -Verbose

# Determine output path if not specified
if (-not $OutputPath) {
    $htmlFile = Get-Item $HtmlPath
    $directory = $htmlFile.DirectoryName
    $baseName = $htmlFile.BaseName
    $OutputPath = Join-Path $directory "$baseName-data.json"
}

# Output to file
$jsonData | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "JSON data extracted to: $OutputPath" -ForegroundColor Green

# Show file size
$fileInfo = Get-Item $OutputPath
Write-Host "File size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -ForegroundColor Cyan
