# PowerShell script to install Visual Studio Build Tools with required components
# Run as Administrator

Write-Host "Downloading Visual Studio Build Tools installer..." -ForegroundColor Green

# Download the installer
$url = "https://aka.ms/vs/17/release/vs_buildtools.exe"
$output = "$env:TEMP\vs_buildtools.exe"
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "Installing Visual Studio Build Tools with required components..." -ForegroundColor Green

# Install with required workloads and components
& $output --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.Windows10SDK.19041 --add Microsoft.VisualStudio.Component.VC.ATL --add Microsoft.VisualStudio.Component.VC.CMake.Project

Write-Host "Installation completed!" -ForegroundColor Green
Write-Host "Please restart your command prompt and try building again." -ForegroundColor Yellow

# Clean up
Remove-Item $output -Force