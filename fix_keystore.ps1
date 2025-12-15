# PowerShell Script to Fix Keystore Configuration

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Keystore Configuration Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if keystore file exists
$keystorePath = "c:\CampusBound\frontend\campusbound.jks"
if (Test-Path $keystorePath) {
    Write-Host "[OK] Keystore file found: $keystorePath" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Keystore file NOT found at: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create it with this command:" -ForegroundColor Yellow
    Write-Host "keytool -genkey -v -keystore c:\CampusBound\frontend\campusbound.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campusbound" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Get password from user
Write-Host ""
Write-Host "Enter your keystore password:" -ForegroundColor Yellow
$password = Read-Host -AsSecureString "Password"
$passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))

# Create key.properties content
$content = @"
storePassword=$passwordPlain
keyPassword=$passwordPlain
keyAlias=campusbound
storeFile=../campusbound.jks
"@

# File path
$filePath = "android\key.properties"

# Create the file
try {
    $content | Out-File -FilePath $filePath -Encoding UTF8 -Force
    Write-Host ""
    Write-Host "[OK] key.properties created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "File contents:" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Get-Content $filePath
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter clean" -ForegroundColor White
    Write-Host "2. Run: flutter pub get" -ForegroundColor White
    Write-Host "3. Run: flutter build appbundle --release" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "[ERROR] Error creating file: $_" -ForegroundColor Red
    exit 1
}
