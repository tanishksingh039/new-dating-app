@echo off
REM Verify and Fix Keystore Configuration

echo.
echo ========================================
echo Keystore Configuration Verification
echo ========================================
echo.

REM Check if keystore file exists
if exist "c:\CampusBound\frontend\campusbound.jks" (
    echo [OK] Keystore file found: c:\CampusBound\frontend\campusbound.jks
) else (
    echo [ERROR] Keystore file NOT found at: c:\CampusBound\frontend\campusbound.jks
    echo.
    echo You need to create the keystore file first.
    echo Run this command:
    echo.
    echo keytool -genkey -v -keystore c:\CampusBound\frontend\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound
    echo.
    pause
    exit /b 1
)

REM Check if key.properties exists
if exist "android\key.properties" (
    echo [OK] key.properties file found: android\key.properties
    echo.
    echo File contents:
    echo ----------------------------------------
    type android\key.properties
    echo ----------------------------------------
    echo.
) else (
    echo [ERROR] key.properties file NOT found at: android\key.properties
    echo.
    echo Creating key.properties file...
    echo.
    echo Enter your keystore password (the one you used when creating campusbound.jks):
    set /p PASSWORD="Password: "
    
    (
        echo storePassword=%PASSWORD%
        echo keyPassword=%PASSWORD%
        echo keyAlias=campusbound
        echo storeFile=../campusbound.jks
    ) > android\key.properties
    
    echo.
    echo [OK] key.properties created!
    echo.
    echo File contents:
    echo ----------------------------------------
    type android\key.properties
    echo ----------------------------------------
    echo.
)

echo.
echo ========================================
echo Ready to build!
echo ========================================
echo.
echo Run this command:
echo flutter clean
echo flutter pub get
echo flutter build appbundle --release
echo.
pause
