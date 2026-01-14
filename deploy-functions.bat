@echo off
echo Deploying Firebase Cloud Functions...
echo.
echo Step 1: Setting project...
firebase use hallify-df669
echo.
echo Step 2: Deploying functions...
firebase deploy --only functions
echo.
echo Done!
pause
