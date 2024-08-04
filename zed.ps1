$current_pos = Get-Location
Write-Host "Current Location: $current_pos"

# Dependency: https://github.com/jborean93/PSToml
Import-Module PSToml

Write-Host "Zed build script"
Write-Host "by shenjackyuanjie"
$_version_ = "1.2.0"
Write-Host "Version: $_version_"

$zed_repo_path = "C:\Users\Marcel\Desktop\zed-main"
$work_path = "D:\GRRRRR"

Set-Location $zed_repo_path
Write-Host "Updating Zed repository"
git pull | Tee-Object -Variable git_result
# If command line arguments include -f, then continue building
if ($git_result -eq "Already up to date." -and -not ($args -contains "-f")) {
    Write-Host "Zed repository is already up to date"
    Set-Location $current_pos
    return
}
Write-Host "Zed repository update complete"

# Prepare build information
$date = Get-Date -Format "yyyy-MM-dd-HH_mm_ss"
Write-Host "Update Time: $date"
$commit = git log -1 --pretty=format:"%h"
$full_commit = git log -1 --pretty=format:"%H"
$cargo_info = Get-Content ".\crates\zed\Cargo.toml" | ConvertFrom-Toml
$zed_version = $cargo_info.package.version
Write-Host "Zed Version: $zed_version"
Write-Host "Latest Commit: $commit($full_commit)"
$zip_name = "zed-$zed_version-$commit.zip"
$zip_namex = "zed-$zed_version-$commit.zipx"
Write-Host "ZIP Name: $zip_name"
Write-Host "ZIPX Name: $zip_namex"
# After constructing this information, it will be output again

# Build!
$start_time = Get-Date
if (-not ($args -contains "-skip")) {
    Write-Host "Starting build"
    cargo build --release
    Write-Host "Build complete, duration: $((Get-Date) - $start_time)"
}

# Copy the latest build to D:\path-scripts
Copy-Item -Path ".\target\release\Zed.exe" -Destination "$work_path\Zed.exe" -Force

# Go to the D:\path-scripts directory
Set-Location $work_path
if (Test-Path $zip_name) {
    Write-Host "Deleting old ZIP"
    Remove-Item -Path $zip_name -Force
}
Write-Host "Starting to package"

# Create a zed-zip folder
if (-not (Test-Path ".\zed-zip")) {
    New-Item -ItemType Directory -Name "zed-zip" -Force
}

# Ignore output
bz.exe c -l:9 -y -fmt:zip -t:14 -cp:65001 .\zed-zip\$zip_name .\Zed.exe
bz.exe c -l:9 -y -fmt:zipx -t:14 -cp:65001 .\zed-zip\$zip_namex .\Zed.exe
bz.exe t .\zed-zip\$zip_name
bz.exe t .\zed-zip\$zip_namex

$zip_file = Get-Item ".\zed-zip\$zip_name"
$zipx_file = Get-Item ".\zed-zip\$zip_namex"

Write-Host "tag: $zed_version+$commit-$_version_"
# https://github.com/zed-industries/zed/commit/f6fa6600bc0293707457f27f5849c3ce73bd985f
Write-Host "commit url: https://github.com/zed-industries/zed/commit/$full_commit"
Write-Host "Packaging Information:"
Write-Host "  - Script Version: $_version_"
Write-Host "  - Commit ID: $commit"
Write-Host "  - Zed Version: $zed_version"
Write-Host "  - ZIP File: $zip_file"
Write-Host "  - ZIPX File: $zipx_file"
Write-Host "  - Build Time: $date"
Write-Host "  - Build Duration: $((Get-Date) - $start_time)"

Write-Host "``````"
# Calculate hash
Write-Host "blake3sum:"
b3sum.exe .\zed-zip\$zip_name
b3sum.exe .\zed-zip\$zip_namex

($zip_file, $zipx_file) | Get-FileHash -Algorithm SHA256
Write-Host "``````"
Write-Host "ZIP Compression Complete"

# Return to the original location
Set-Location $current_pos
