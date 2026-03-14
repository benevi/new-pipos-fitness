# Install Flutter SDK to C:\flutter and add to user PATH
# Run in PowerShell (no admin required for C:\flutter and user PATH)

$ErrorActionPreference = "Stop"
$flutterRoot = "C:\flutter"
$zipPath = "$env:TEMP\flutter_sdk.zip"
# Official stable URL (adjust version if needed)
$flutterZipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"

if (Test-Path "$flutterRoot\bin\flutter.bat") {
    Write-Host "Flutter already installed at $flutterRoot"
} else {
    if (Test-Path $flutterRoot) { Remove-Item $flutterRoot -Recurse -Force }
    Write-Host "Downloading Flutter SDK (~1GB)..."
    Invoke-WebRequest -Uri $flutterZipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath "C:\" -Force
    Remove-Item $zipPath -Force
    $extracted = Get-ChildItem "C:\" -Filter "flutter*" -Directory | Select-Object -First 1
    if ($extracted.Name -ne "flutter") {
        Rename-Item $extracted.FullName $flutterRoot
    }
}

$binPath = "$flutterRoot\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$binPath", "User")
    Write-Host "Added $binPath to user PATH. Close and reopen PowerShell."
}
Write-Host "Done. Run: flutter doctor"
