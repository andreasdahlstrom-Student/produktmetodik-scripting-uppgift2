Import-Module ".\SecurityChallenges.psm1" -Force

$score = 0

Write-Host "=== SECURITY ESCAPE ROOM START ===" -ForegroundColor Cyan

$result = Invoke-PhishingChallenge
$score += $result.Points

$result = Invoke-PasswordChallenge
$score += $result.Points

$result = Invoke-MfaChallenge
$score += $result.Points

$result = Invoke-UsbChallenge
$score += $result.Points

$result = Invoke-IncidentChallenge
$score += $result.Points

Write-Host ""
Write-Host "=== GAME OVER ===" -ForegroundColor Cyan
Write-Host "Final score: $score"