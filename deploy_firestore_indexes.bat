@echo off
echo ========================================
echo Deploying Firestore Indexes (Rewards)
echo ========================================
echo.

echo Checking Firebase CLI...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found!
    echo Please install: npm install -g firebase-tools
    echo Then run: firebase login
    pause
    exit /b 1
)

echo.
echo Current directory: %cd%
echo.

echo Deploying Firestore indexes...
firebase deploy --only firestore:indexes

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! Firestore indexes deployed
    echo ========================================
    echo.
    echo The following index is now building:
    echo - Collection: rewards
    echo - Fields: userId (ASC), createdAt (DESC)
    echo.
    echo IMPORTANT: Index building takes 2-5 minutes
    echo.
    echo Check status:
    echo 1. Open Firebase Console
    echo 2. Go to Firestore Database
    echo 3. Click "Indexes" tab
    echo 4. Wait for "Building" to change to "Enabled"
    echo.
    echo Once enabled, refresh your app and rewards will load!
    echo.
) else (
    echo.
    echo ========================================
    echo ERROR: Deployment failed
    echo ========================================
    echo.
    echo Troubleshooting:
    echo 1. Run: firebase login
    echo 2. Run: firebase use --add
    echo 3. Select your project
    echo 4. Try deployment again
    echo.
    echo Alternative: Create index manually in Firebase Console
    echo See FIRESTORE_INDEX_REWARDS.md for instructions
    echo.
)

pause
