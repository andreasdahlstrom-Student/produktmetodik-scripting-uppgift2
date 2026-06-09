# Security Escape Room - startfil

$modulesPath = "$PSScriptRoot\modules"

try {
    Import-Module "$modulesPath\UI.psm1" -Force
    Import-Module "$modulesPath\SaveSystem.psm1" -Force
    Import-Module "$modulesPath\SecurityChallenges.psm1" -Force
    Import-Module "$modulesPath\GameEngine.psm1" -Force

    Start-SecurityEscapeRoom -ProjectRoot $PSScriptRoot
}
catch {
    Write-Host ""
    Write-Host "Något gick fel när spelet skulle startas:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Write-Host "Kolla att alla filer ligger i modules-mappen." -ForegroundColor Yellow
}
