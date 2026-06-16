# Security Escape Room - startfil

$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot\Modules\GameEngine.psm1",
    [ref]$null,
    [ref]$errors
)
if ($errors) { $errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red } }

$modulesPath = "$PSScriptRoot\modules"

try {
    Import-Module "$modulesPath\UI.psm1" -Force
    Import-Module "$modulesPath\SaveSystem.psm1" -Force -DisableNameChecking
    Import-Module "$modulesPath\SecurityChallenges.psm1" -Force
    Import-Module "$modulesPath\GameEngine.psm1" -Force

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    $OutputEncoding           = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null

    Start-SecurityEscapeRoom -ProjectRoot $PSScriptRoot
}
catch {
    Write-Host ""
    Write-Host "Något gick fel när spelet skulle startas:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Write-Host "Kolla att alla filer ligger i modules-mappen." -ForegroundColor Yellow
}
