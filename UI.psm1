# UI.psm1
function Show-Header {
    param([string]$Title)
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
}