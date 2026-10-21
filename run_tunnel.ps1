while ($true) {
    Write-Host "[TunnelWatchdog] Launching tunnel..."
    cmd.exe /c npx -y localtunnel --port 8080 --subdomain rapid-write-app
    Start-Sleep -Seconds 2
}
