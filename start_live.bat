@echo off
title RAPID WRITE 24/7 Live Server & Tunnel
echo ===================================================
echo     RAPID WRITE - Stylus Handwriting Evaluator
echo ===================================================
echo.
echo [1/2] Starting Node.js Web Server on port 8080...
start "RAPID WRITE Server" /min cmd /c "node server.js"
timeout /t 2 /nobreak >nul

echo [2/2] Starting Cloudflare Live Tunnel...
echo Look for your trycloudflare.com link below:
echo.
cloudflared.exe tunnel --url http://127.0.0.1:8080
pause
