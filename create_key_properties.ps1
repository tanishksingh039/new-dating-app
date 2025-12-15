# PowerShell Script to Create key.properties File
# Run this script to create the key.properties file

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Create key.properties File" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get password from user
$password = Read-Host "Enter your keystore password (will be used for both storePassword and keyPassword)" -AsSecureString
$passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))

# Verify password
$passwordConfirm = Read-Host "Confirm your keystore password" -AsSecureString
$passwordConfirmPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($passwordConfirm))

if ($passwordPlain -ne $passwordConfirmPlain) {
    Write-Host "Passwords do not match!" -ForegroundColor Red
    exit 1
}

# Create the content
$content = @"
storePassword=$passwordPlain
keyPassword=$passwordPlain
keyAlias=campusbound
storeFile=../campusbound.jks
"@

# File path
$filePath = "android/key.properties"

# Create the file
try {
    $content | Out-File -FilePath $filePath -Encoding UTF8 -Force
    Write-Host ""
    Write-Host "✅ File created successfully!" -ForegroundColor Green
    Write-Host "Location: $filePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "File contents:" -ForegroundColor Yellow
    Get-Content $filePath
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter clean" -ForegroundColor White
    Write-Host "2. Run: flutter pub get" -ForegroundColor White
    Write-Host "3. Run: flutter build appbundle --release" -ForegroundColor White
} catch {
    Write-Host "❌ Error creating file: $_" -ForegroundColor Red
    exit 1
}
