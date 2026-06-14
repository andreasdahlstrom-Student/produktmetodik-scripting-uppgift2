# GameEngine.psm1
# Spelmotorn styr huvudmeny, timer, tidstillägg och slutresultat.

function New-RansomwareGameState {
    param(
        [Parameter(Mandatory)]
        [string]$PlayerName
    )

    # Skapar ett nytt spelobjekt där all information om spelet sparas.
    # Här sparas till exempel spelarens namn, tid, antal fel och vilken fråga spelaren är på.
    return [PSCustomObject]@{
        playerName           = $PlayerName
        currentQuestionIndex = 0
        actualStartTime      = $null
        startTime            = $null
        endTime              = $null
        elapsedSeconds       = 0
        actualSeconds        = 0
        wrongAnswers         = 0
        penaltySeconds       = 0
        totalSeconds         = 0
        completedQuestions   = 0
        isCompleted          = $false
        lastSaved            = ""
    }
}

function Start-SecurityEscapeRoom {
    param(
        [string]$ProjectRoot = (Split-Path -Path $PSScriptRoot -Parent)
    )

    # Startar spelet med det gamla funktionsnamnet.
    # Detta finns kvar så äldre filer fortfarande fungerar.
    Start-RansomwareEscapeRoom -ProjectRoot $ProjectRoot
}

function Start-RansomwareEscapeRoom {
    param(
        [string]$ProjectRoot = (Split-Path -Path $PSScriptRoot -Parent)
    )

    # Bestämmer var sparfilen ska ligga.
    $savePath = Join-Path -Path $ProjectRoot -ChildPath "data\savegame.json"

    # Så länge detta är sant visas huvudmenyn.
    $isRunning = $true

    while ($isRunning) {
        # Visar introduktionen till spelet.
        Show-RansomwareIntro

        # Visar huvudmenyn med olika val.
        Show-Menu -Options @(
            "1. Nytt spel",
            "2. Visa scoreboard",
            "3. Fortsätt sparat spel",
            "4. Avsluta"
        )

        # Läser in spelarens val.
        $choice = Read-Host "Välj ett alternativ"

        switch ($choice) {
            "1" {
                # Startar ett nytt spel.
                Start-NewGame -SavePath $savePath
            }
            "2" {
                # Visar scoreboarden.
                Show-ScoreboardMenu
            }
            "3" {
                # Försöker fortsätta från ett sparat spel.
                Start-SavedGame -SavePath $savePath
            }
            "4" {
                # Avslutar spelet och lämnar menyn.
                Show-Message "Du stänger terminalen. Håll dig säker där ute." "Cyan"
                $isRunning = $false
            }
            default {
                # Visas om spelaren skriver något annat än 1, 2, 3 eller 4.
                Show-FailureMessage "Ogiltigt val. Skriv 1, 2, 3 eller 4."
                Pause-Game
            }
        }
    }
}

function Show-ScoreboardMenu {
    try {
        # Läser in scoreboarden och sorterar resultaten.
        # Bäst tid kommer först, och vid samma tid jämförs antal fel.
        $results = @(Load-Scoreboard | Sort-Object -Property @{ Expression = { [int]$_.totalTimeSeconds } }, @{ Expression = { [int]$_.wrongAnswers } })

        # Visar resultaten på skärmen.
        Show-Scoreboard -Results $results
        Pause-Game
    }
    catch {
        # Visar felmeddelande om scoreboarden inte kunde visas.
        Show-Error "Kunde inte visa scoreboard: $($_.Exception.Message)"
        Pause-Game
    }
}

function Start-NewGame {
    param(
        [Parameter(Mandatory)]
        [string]$SavePath
    )

    try {
        # Frågar spelaren efter namn.
        $playerName = Read-Host "Skriv ditt namn"

        # Om spelaren inte skriver något används standardnamnet "Elev".
        if ([string]::IsNullOrWhiteSpace($playerName)) {
            $playerName = "Elev"
        }

        # Skapar ett nytt spel och startar timern.
        $gameState = New-RansomwareGameState -PlayerName $playerName
        $gameState.actualStartTime = Get-Date
        $gameState.startTime = $gameState.actualStartTime

        # Sparar spelet direkt så det går att fortsätta senare.
        Save-Game -Path $SavePath -SaveData $gameState

        # Visar startmeddelande för spelaren.
        Show-HackerMessage -PlayerName $playerName
        Pause-Game

        # Startar quizet.
        Invoke-RansomwareQuiz -GameState $gameState -SavePath $SavePath | Out-Null

        # När quizet är klart visas slutresultatet.
        Show-FinalResult -GameState $gameState -SavePath $SavePath
    }
    catch {
        # Visar fel om spelet inte kunde startas.
        Show-Error "Kunde inte starta ransomware-spelet: $($_.Exception.Message)"
    }
}

function Start-SavedGame {
    param(
        [Parameter(Mandatory)]
        [string]$SavePath
    )

    try {
        # Läser in sparat spel från fil.
        $gameState = Load-Game -Path $SavePath

        # Hämtar hur många frågor spelet har totalt.
        $totalQuestions = (Get-RansomwareQuestions).Count

        # Kontrollerar om det finns ett giltigt sparat spel.
        # Om spelet redan är klart eller saknar namn går det inte att fortsätta.
        if ($null -eq $gameState -or [string]::IsNullOrWhiteSpace($gameState.playerName) -or $gameState.isCompleted -or [int]$gameState.currentQuestionIndex -ge $totalQuestions) {
            Show-FailureMessage "Inget sparat spel hittades."
            Wait-ForReturnToMenu
            return
        }

        # Hämtar tidigare speltid.
        $elapsedSeconds = [int]$gameState.elapsedSeconds

        # Om elapsedSeconds saknas men actualSeconds finns används actualSeconds istället.
        if ($elapsedSeconds -eq 0 -and [int]$gameState.actualSeconds -gt 0) {
            $elapsedSeconds = [int]$gameState.actualSeconds
        }

        # Justerar starttiden så timern fortsätter där spelaren slutade.
        $gameState.startTime = (Get-Date).AddSeconds(-1 * $elapsedSeconds)
        $gameState.actualStartTime = $gameState.startTime

        # Visar en kort sammanfattning av det sparade spelet.
        Show-SavedGameSummary -GameState $gameState
        Pause-Game

        # Fortsätter quizet från rätt fråga.
        Invoke-RansomwareQuiz -GameState $gameState -SavePath $SavePath -StartQuestionIndex ([int]$gameState.currentQuestionIndex) | Out-Null

        # När quizet är klart visas slutresultatet.
        Show-FinalResult -GameState $gameState -SavePath $SavePath
    }
    catch {
        # Visar fel om det sparade spelet inte kunde fortsätta.
        Show-Error "Kunde inte fortsätta sparat spel: $($_.Exception.Message)"
        Wait-ForReturnToMenu
    }
}

function Start-RansomwareTimer {
    # Returnerar nuvarande tid.
    # Den används som starttid för timern.
    return Get-Date
}

function Stop-RansomwareTimer {
    param(
        [Parameter(Mandatory)]
        [object]$GameState
    )

    # Sätter sluttiden till nu.
    $GameState.endTime = Get-Date

    # Räknar ut hur lång tid spelet tog.
    $elapsed = New-TimeSpan -Start $GameState.startTime -End $GameState.endTime

    # Sparar tiden i sekunder.
    $GameState.actualSeconds = [int][Math]::Round($elapsed.TotalSeconds)
    $GameState.elapsedSeconds = $GameState.actualSeconds

    # Total tid är riktig tid plus tidstillägg från fel svar.
    $GameState.totalSeconds = $GameState.actualSeconds + $GameState.penaltySeconds
}

function Get-CurrentRansomwareTime {
    param(
        [Parameter(Mandatory)]
        [object]$GameState
    )

    try {
        # Om spelet inte har någon starttid räknas bara strafftiden.
        if ($null -eq $GameState.startTime) {
            return [PSCustomObject]@{
                ActualSeconds  = 0
                PenaltySeconds = [int]$GameState.penaltySeconds
                TotalSeconds   = [int]$GameState.penaltySeconds
                WrongAnswers   = [int]$GameState.wrongAnswers
            }
        }

        # Räknar ut hur lång tid som har gått sedan spelet startade.
        $elapsed = New-TimeSpan -Start $GameState.startTime -End (Get-Date)
        $actualSeconds = [int][Math]::Round($elapsed.TotalSeconds)
        $penaltySeconds = [int]$GameState.penaltySeconds

        # Returnerar aktuell tid, strafftid, totaltid och antal fel.
        return [PSCustomObject]@{
            ActualSeconds  = $actualSeconds
            PenaltySeconds = $penaltySeconds
            TotalSeconds   = $actualSeconds + $penaltySeconds
            WrongAnswers   = [int]$GameState.wrongAnswers
        }
    }
    catch {
        # Om något går fel visas ett felmeddelande och standardvärden returneras.
        Show-Error "Kunde inte räkna ut aktuell tid: $($_.Exception.Message)"

        return [PSCustomObject]@{
            ActualSeconds  = 0
            PenaltySeconds = [int]$GameState.penaltySeconds
            TotalSeconds   = [int]$GameState.penaltySeconds
            WrongAnswers   = [int]$GameState.wrongAnswers
        }
    }
}

function Add-TimePenalty {
    param(
        [Parameter(Mandatory)]
        [object]$GameState,

        [int]$Seconds = 10
    )

    # Ökar antal fel med 1.
    $GameState.wrongAnswers++

    # Lägger till straffsekunder på spelarens tid.
    $GameState.penaltySeconds += $Seconds
}

function Show-FinalResult {
    param(
        [Parameter(Mandatory)]
        [object]$GameState,

        [Parameter(Mandatory)]
        [string]$SavePath
    )

    try {
        # Stoppar timern och räknar ut sluttiden.
        Stop-RansomwareTimer -GameState $GameState

        # Uppdaterar spelstatusen så spelet markeras som klart.
        $GameState.currentQuestionIndex = [int]$GameState.completedQuestions
        $GameState.isCompleted = $true

        # Sparar färdigt spel.
        Save-Game -Path $SavePath -SaveData $GameState

        # Sparar resultatet till scoreboarden.
        Save-ScoreboardResult -GameState $GameState | Out-Null

        # Visar avslutningsmeddelanden.
        Show-HackerVictoryMessage -PlayerName $GameState.playerName
        Show-RansomwareSuccessEnding -GameState $GameState

        # Väntar tills spelaren vill tillbaka till menyn.
        Wait-ForReturnToMenu
    }
    catch {
        # Om resultatet inte kunde sparas visas ett fel.
        Show-Error "Spelet är klart, men resultatet kunde inte sparas: $($_.Exception.Message)"
        Wait-ForReturnToMenu
    }
}

function Show-SavedGameSummary {
    param(
        [Parameter(Mandatory)]
        [object]$GameState
    )

    # Hämtar aktuell speltid.
    $currentTime = Get-CurrentRansomwareTime -GameState $GameState

    # Räknar ut vilken fråga/rum spelaren är på.
    $nextQuestion = [int]$GameState.currentQuestionIndex + 1

    # Visar information om det sparade spelet.
    Show-Title
    Write-Host "Sparat spel hittades." -ForegroundColor Green
    Write-Host ""
    Write-Host "Spelare: $($GameState.playerName)" -ForegroundColor White
    Write-Host "Aktuell fråga/rum: $nextQuestion" -ForegroundColor Cyan
    Write-Host "Tid just nu: $(Format-ClockTime -Seconds $currentTime.TotalSeconds)" -ForegroundColor Cyan
    Write-Host "Fel: $($currentTime.WrongAnswers)" -ForegroundColor Yellow
    Write-Host "Tidstillägg: $($currentTime.PenaltySeconds) sekunder" -ForegroundColor Yellow
    Write-Host ""
}

# Bestämmer vilka funktioner som ska kunna användas utanför denna modul.
Export-ModuleMember -Function Start-SecurityEscapeRoom, Start-RansomwareEscapeRoom, Show-ScoreboardMenu, Start-NewGame, Start-SavedGame, Start-RansomwareTimer, Stop-RansomwareTimer, Get-CurrentRansomwareTime, Add-TimePenalty, Show-FinalResult