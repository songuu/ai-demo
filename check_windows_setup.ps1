# PowerShell script to check Windows development environment
Write-Host "Checking Flutter Windows development environment..." -ForegroundColor Green

# Check Flutter doctor
Write-Host "`n1. Running Flutter doctor..." -ForegroundColor Yellow
flutter doctor -v

# Check for Visual Studio installation
Write-Host "`n2. Checking for Visual Studio installations..." -ForegroundColor Yellow
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
    ForEach-Object { Get-ItemProperty $_.PSPath } | 
    Where-Object { $_.DisplayName -like "*Visual Studio*" -or $_.DisplayName -like "*Build Tools*" } | 
    Select-Object DisplayName, DisplayVersion

# Check for Windows SDK
Write-Host "`n3. Checking for Windows SDK..." -ForegroundColor Yellow
Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows" -ErrorAction SilentlyContinue | 
    ForEach-Object { Get-ItemProperty $_.PSPath } | 
    Select-Object PSChildName, ProductVersion, InstallationFolder

# Check for ATL headers
Write-Host "`n4. Checking for ATL headers..." -ForegroundColor Yellow
$possiblePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\*\atlmfc\include",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\atlmfc\include",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC\*\atlmfc\include",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\atlmfc\include"
)

$foundATL = $false
foreach ($path in $possiblePaths) {
    $atlFiles = Get-ChildItem -Path $path -Filter "atlstr.h" -Recurse -ErrorAction SilentlyContinue
    if ($atlFiles) {
        Write-Host "✅ Found ATL headers at: $($atlFiles.Directory.FullName)" -ForegroundColor Green
        $foundATL = $true
        break
    }
}

if (-not $foundATL) {
    Write-Host "❌ ATL headers not found. Please install Visual Studio with C++ ATL components." -ForegroundColor Red
    Write-Host "   解决步骤: 打开 Visual Studio Installer -> 修改 -> 单个组件 -> 搜索 ATL -> 勾选 C++ ATL" -ForegroundColor Yellow
    Write-Host "   详细说明: 参见 docs/WINDOWS_BUILD_FIX.md" -ForegroundColor Yellow
}

Write-Host "`nSetup check completed!" -ForegroundColor Green