@echo off
title Push RAPID-WRITE to GitHub
cd /d "%~dp0"
echo ========================================================
echo   Pushing RAPID-WRITE to GitHub (Branch: main)
echo ========================================================
echo.
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================================
    echo   SUCCESS! Pushed to https://github.com/Akchith17/RAPID-WRITE
    echo ========================================================
) else (
    echo.
    echo If requested, please sign in with your GitHub account above.
)
echo.
pause
