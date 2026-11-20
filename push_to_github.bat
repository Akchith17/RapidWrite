@echo off
title Push RapidWrite to GitHub
cd /d "%~dp0"
echo ========================================================
echo   Pushing RapidWrite to GitHub (Branch: main)
echo   Repository: https://github.com/Akchith17/RapidWrite.git
echo ========================================================
echo.
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================================
    echo   SUCCESS! Pushed to https://github.com/Akchith17/RapidWrite
    echo ========================================================
) else (
    echo.
    echo If GitHub authentication is required:
    echo A browser window will open automatically asking you to
    echo sign in with your GitHub account (Akchith17).
    echo Please authorize the sign-in in your browser.
)
echo.
pause
