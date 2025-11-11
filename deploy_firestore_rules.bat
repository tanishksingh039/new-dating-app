@echo off
echo Deploying Firestore Rules...
firebase deploy --only firestore:rules
echo.
echo Firestore rules deployed successfully!
pause
