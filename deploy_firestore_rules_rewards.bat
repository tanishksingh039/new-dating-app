@echo off
echo ========================================
echo Deploying Firestore Rules (Rewards System)
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

echo Deploying Firestore rules...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! Firestore rules deployed
    echo ========================================
    echo.
    echo The following rules are now active:
    echo - Rewards collection: Admin bypass enabled
    echo - Users can read their own rewards
    echo - Admins can send rewards without auth
    echo.
    echo Test the deployment:
    echo 1. Open admin dashboard
    echo 2. Go to Bulk Leaderboard
    echo 3. Click "Send Reward" on any user
    echo 4. Verify reward is created
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
)

pause
