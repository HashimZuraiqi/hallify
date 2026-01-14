@echo off
REM Script to remove secrets from Git history (Windows)
REM WARNING: This will rewrite Git history!

echo ================================================================
echo    Hallify - Secret Removal Script (Windows)
echo ================================================================
echo.
echo WARNING: This will rewrite Git history!
echo WARNING: Backup your repository before proceeding!
echo.
set /p confirm="Do you want to continue? (yes/no): "

if not "%confirm%"=="yes" (
    echo Aborted.
    exit /b 1
)

echo.
echo Checking for BFG Repo-Cleaner...
where bfg >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo BFG Repo-Cleaner not found!
    echo Please download from: https://rtyley.github.io/bfg-repo-cleaner/
    echo.
    echo Usage: java -jar bfg.jar --delete-files firebase_options.dart
    exit /b 1
)

echo.
echo Removing sensitive files from history...
bfg --delete-files firebase_options.dart
bfg --delete-files google-services.json
bfg --delete-files GoogleService-Info.plist
bfg --delete-files .env

echo.
echo Cleaning up Git repository...
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo.
echo ===============================================
echo Done! Now you need to:
echo   1. Rotate all exposed API keys immediately
echo   2. Force push: git push --force --all
echo   3. Notify team members to re-clone
echo.
echo Don't forget to rotate these keys:
echo   - Firebase API keys
echo   - Cloudinary credentials  
echo   - Google Maps API keys
echo ===============================================
echo.
pause
