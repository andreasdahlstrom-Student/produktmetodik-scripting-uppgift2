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
    Start-RansomwareEscapeRoom -ProjectRoot $ProjectRoot
}

function Start-RansomwareEscapeRoom {
    param(
        [string]$ProjectRoot = (Split-Path -Path $PSScriptRoot -Parent)
    )

    $savePath = Join-Path -Path $ProjectRoot -ChildPath "data\savegame.json"
    $isRunning = $true

    # Encodings... (behåll som du har det)
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null

    Write-SplashScreen -DelayMs 100

    while ($isRunning) {
        Write-Title
        Write-Menu -Options @(
            "Nytt spel",
            "Visa scoreboard",
            "Fortsätt sparat spel",
            "Avsluta"
        )

        $playerAnswer = Read-Host "  Ditt val"
        $choice = 0
        [int]::TryParse($playerAnswer, [ref]$choice) | Out-Null

        switch ($choice) {
            1 { 
                # Instruktioner och start sker nu inuti Start-NewGame 
                Start-NewGame -SavePath $savePath 
            }
            2 { Show-ScoreboardMenu }
            3 { Start-SavedGame -SavePath $savePath }
            4 {
                Write-Notification -Message "Du stänger terminalen. Håll dig säker där ute." -Type Info
                $isRunning = $false
            }
            default {
                Write-Notification -Message "Ogiltigt val." -Type Error
                Wait-Game
            }
        }
    }
}

function Show-ScoreboardMenu {
    try {
        $results = @(Load-Scoreboard | Sort-Object -Property @{ Expression = { [int]$_.totalTimeSeconds } }, @{ Expression = { [int]$_.wrongAnswers } })
        Write-Scoreboard -Scores $results
    }
    catch {
        Write-Notification -Message "Kunde inte visa scoreboard: $($_.Exception.Message)" -Type Error
        Wait-Game
    }
}

function Start-NewGame {
    param(
        [Parameter(Mandatory)]
        [string]$SavePath
    )

    # 1. Spelaren får skriva in sitt namn först av allt
    while ($true) {
        $playerName = Read-Host "Skriv ditt namn (max 15 tecken)"
        if ([string]::IsNullOrWhiteSpace($playerName)) {
            $playerName = "Elev"
            break
        }
        elseif ($playerName.Length -gt 15) {
            Write-Host "  Namnet är för långt! Max 15 tecken, du skrev $($playerName.Length)." -ForegroundColor Red
            Write-Host ""
        }
        else {
            break
        }
    }

    # 2. Hämta antal frågor och visa instruktionerna
    $allQuestions = Get-RansomwareQuestions
    Write-Instructions -TotalKeys $allQuestions.Count

    # 3. Initiera spelet och STARTA klockan (efter att spelaren tryckt Enter i instruktionerna)
    $gameState = New-RansomwareGameState -PlayerName $playerName
    $gameState.actualStartTime = Get-Date
    $gameState.startTime       = $gameState.actualStartTime

    # Spara spelet och kör igång introduktionen
    Save-Game -Path $SavePath -SaveData $gameState
    Write-HackerIntro -PlayerName $playerName
    
    # Kör själva quizet
    $quizResult = Invoke-RansomwareQuiz -GameState $gameState -SavePath $SavePath
    
    # Kolla om spelaren avbröt (Ctrl+C)
    if ($null -ne $quizResult -and $quizResult.Aborted) {
        return
    }

    # Visa resultatskärmen om spelet slutfördes
    Show-FinalResult -GameState $gameState -SavePath $SavePath
}

function Start-SavedGame {
    param(
        [Parameter(Mandatory)]
        [string]$SavePath
    )

    try {
        $allSaves       = @(Load-Game -Path $SavePath)
        $totalQuestions = (Get-RansomwareQuestions).Count

        # Filtrera bort avklarade och ogiltiga saves
        $activeSaves = @($allSaves | Where-Object {
            $null -ne $_ -and
            -not [string]::IsNullOrWhiteSpace($_.playerName) -and
            -not $_.isCompleted -and
            [int]$_.currentQuestionIndex -lt $totalQuestions
        })

        if ($activeSaves.Count -eq 0) {
            Write-Notification -Message "Inga aktiva sparade spel hittades." -Type Warning
            Wait-Game
            return
        }

        # Bygg listan som Write-LoadPrompt förväntar sig
        $savedGames = @($activeSaves | ForEach-Object {
            $elapsed = [int]$_.elapsedSeconds
            $penalty = [int]$_.penaltySeconds
            [PSCustomObject]@{
                PlayerName     = $_.playerName
                CompletedRooms = [int]$_.currentQuestionIndex
                TotalRooms     = $totalQuestions
                ElapsedSeconds = $elapsed
                PenaltySeconds = $penalty
                Ransom         = 10000 + ($elapsed * 1500) + ($penalty * 500)
            }
        })

        $chosen = Write-LoadPrompt -SavedGames $savedGames
        if ($chosen -eq -1) { return }

        $gameState = $activeSaves[$chosen]

        $elapsedSeconds = [int]$gameState.elapsedSeconds
        if ($elapsedSeconds -eq 0 -and [int]$gameState.actualSeconds -gt 0) {
            $elapsedSeconds = [int]$gameState.actualSeconds
        }

        $nextQ = [int]$gameState.currentQuestionIndex + 1
        Write-Notification -Message "Laddar spel för $($gameState.playerName)... Fortsätter på fråga $nextQ." -Type Success
        Wait-Game

        # Sätt starttiden EFTER att spelaren tryckt Enter
        $gameState.startTime       = (Get-Date).AddSeconds(-1 * $elapsedSeconds)
        $gameState.actualStartTime = $gameState.startTime

        # ### ---> NYTT: Fånga resultatet från quizet här också
        $quizResult = Invoke-RansomwareQuiz -GameState $gameState -SavePath $SavePath
        
        # ### ---> NYTT: Kolla om spelaren tryckte Ctrl-C (Aborted)
        if ($null -ne $quizResult -and $quizResult.Aborted) {
            # Gå tillbaka till menyn direkt
            return
        }

        Show-FinalResult -GameState $gameState -SavePath $SavePath
    }
    catch {
        Write-Notification -Message "Kunde inte fortsätta sparat spel: $($_.Exception.Message)" -Type Error
        Wait-Game
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

    # Spara resultatet – ett fel här ska inte blockera vinst-skärmen
    try {
        Stop-RansomwareTimer -GameState $GameState
        $GameState.currentQuestionIndex = [int]$GameState.completedQuestions
        $GameState.isCompleted          = $true
        Save-Game -Path $SavePath -SaveData $GameState
        Save-ScoreboardResult -GameState $GameState | Out-Null
    }
    catch {
        Write-Notification -Message "Resultatet kunde inte sparas: $($_.Exception.Message)" -Type Error
        Wait-Game
    }

    # Vinst-skärmen visas alltid – oavsett om sparandet lyckades
    Write-Host "DEBUG före HackerOutro" -ForegroundColor Magenta
    Write-HackerOutro -PlayerName $GameState.playerName
    Write-Host "DEBUG före Victory – seconds=$($GameState.actualSeconds) completed=$($GameState.completedQuestions)" -ForegroundColor Magenta
    Write-Victory `
        -ElapsedSeconds $GameState.actualSeconds `
        -PenaltySeconds $GameState.penaltySeconds `
        -KeysFound      $GameState.completedQuestions `
        -Mistakes       $GameState.wrongAnswers
    Write-Host "DEBUG efter Victory" -ForegroundColor Magenta
}

# Bestämmer vilka funktioner som ska kunna användas utanför denna modul.
Export-ModuleMember -Function Start-SecurityEscapeRoom, Start-RansomwareEscapeRoom, Show-ScoreboardMenu, Start-NewGame, Start-SavedGame, Start-RansomwareTimer, Stop-RansomwareTimer, Get-CurrentRansomwareTime, Add-TimePenalty, Show-FinalResult