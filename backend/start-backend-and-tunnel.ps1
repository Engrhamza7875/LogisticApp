# Start SabCargo backend and open a temporary public tunnel for testing.
# Usage:
#   1. Open PowerShell as Administrator.
#   2. Run: .\start-backend-and-tunnel.ps1
#   3. Keep this PowerShell window open while the tunnel is active.

Set-Location -Path $PSScriptRoot

function Ensure-Command {
    param(
        [string]$Name,
        [string]$InstallHint
    )
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Write-Warning "$Name is not installed. $InstallHint"
        return $false
    }
    return $true
}

Write-Host '=== SabCargo Backend + Tunnel Launcher ===' -ForegroundColor Cyan

$hasNode = Ensure-Command -Name node -InstallHint 'Install Node.js from https://nodejs.org if needed.'
$hasNpm = Ensure-Command -Name npm -InstallHint 'Install Node.js to get npm.'

$backendFolder = Join-Path $PSScriptRoot '.'
$serverPort = 5000

if ($hasNpm) {
    Write-Host 'Installing backend dependencies if missing...' -ForegroundColor Yellow
    npm install | Out-Null
}

Write-Host "Starting backend server on port $serverPort..." -ForegroundColor Green
$backendProcess = Start-Process -FilePath npm -ArgumentList 'start' -WorkingDirectory $backendFolder -NoNewWindow -PassThru
Start-Sleep -Seconds 5

if (-not $backendProcess.HasExited) {
    Write-Host 'Backend started successfully.' -ForegroundColor Green
} else {
    Write-Error 'Backend failed to start. Check the server logs in this PowerShell window.'
    exit 1
}

$useNgrok = Ensure-Command -Name ngrok -InstallHint 'Install ngrok from https://ngrok.com/download.'

if ($useNgrok) {
    Write-Host 'Opening ngrok tunnel on port 5000...' -ForegroundColor Green
    Write-Host 'After ngrok opens, copy the HTTPS URL and use it as your BASE_URL.' -ForegroundColor Yellow
    Start-Process -FilePath ngrok -ArgumentList 'http 5000' -NoNewWindow
    Write-Host 'ngrok is running in a separate window.' -ForegroundColor Green
    Write-Host 'Example BASE_URL: https://xxxxxx.ngrok.io/api'
    Write-Host 'Then build your APK with:' -ForegroundColor Cyan
    Write-Host "flutter build apk --release --dart-define=BASE_URL=https://xxxxxx.ngrok.io/api"
} else {
    Write-Warning 'ngrok is not available. Using npx localtunnel if it is available.'
    if (Ensure-Command -Name npx -InstallHint 'Install Node.js to use npx.') {
        Write-Host 'Starting localtunnel for port 5000...' -ForegroundColor Green
        Start-Process -FilePath npx -ArgumentList 'localtunnel --port 5000' -NoNewWindow
        Write-Host 'localtunnel is running in a separate window. Copy the public URL from it.' -ForegroundColor Yellow
        Write-Host 'Then build your APK with:' -ForegroundColor Cyan
        Write-Host "flutter build apk --release --dart-define=BASE_URL=https://your-tunnel-url/api"
    } else {
        Write-Error 'Neither ngrok nor npx localtunnel is available. Install one and rerun this script.'
    }
}

Write-Host 'If you want, keep this window open and use the public URL as BASE_URL.' -ForegroundColor Cyan
