# =============================================================================
# SecurityChallenges.psm1
# =============================================================================
# Ansvar:
#   Den här modulen ansvarar för quizlogiken i spelet.
#   Frågorna laddas från data/questions.json, så de kan ändras eller
#   utökas utan att koden behöver röras.
#   Frågornas ordning och svarsalternativens ordning slumpas varje gång
#   quizet körs, så att spelet inte går att lösa genom att memorera
#   bokstäver eller positioner.
#   Modulen läser spelarens svar och avgör om svaret är rätt.
#
# Funktioner som GameEngine anropar utifrån:
#   Invoke-RansomwareQuiz     - kör hela quizet med alla frågor
#   Invoke-RansomwareQuestion - hanterar en enskild fråga
#
# Interna hjälpfunktioner som bara används i den här filen:
#   Get-RansomwareQuestions   - laddar frågorna från questions.json
#   Get-ShuffledQuestion      - slumpar ordningen på en frågas alternativ
#   Read-RansomwareChoice     - läser och validerar spelarens svar
# =============================================================================


# -----------------------------------------------------------------------------
# GET-RANSOMWAREQUESTIONS
# Laddar alla ransomware-frågor från data/questions.json och returnerar dem
# som en lista av objekt. Varje objekt innehåller frågetext, svarsalternativ,
# rätt svar och feedback.
# -----------------------------------------------------------------------------

function Read-LiveChoice {
    param(
        [int]$MaxOptions,
        [object]$GameState,
        [object]$Question,
        [int]$TotalQuestions
    )
    
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    try {
        # -------------------------------------------------------
        # ENGÅNGSRITNING – körs bara en gång innan loopen startar
        # -------------------------------------------------------
        [Console]::CursorVisible = $false
        Clear-Host

        $ct      = Get-CurrentRansomwareTime -GameState $GameState
        $elapsed = if ($null -ne $ct) { $ct.TotalSeconds }   else { 0 }
        $pen     = if ($null -ne $ct) { $ct.PenaltySeconds } else { 0 }

        # Rita statusbar manuellt och spara exakta radpositioner
        Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkGreen

        $timerRow   = [Console]::CursorTop
        $m          = [math]::Floor($elapsed / 60)
        $s          = $elapsed % 60
        $tColor     = if ($elapsed -lt 60) { "Green" } elseif ($elapsed -lt 120) { "Yellow" } else { "Red" }
        Write-Host ("| Tid: $($m.ToString().PadLeft(2,'0')):$($s.ToString().PadLeft(2,'0'))").PadRight(44) -ForegroundColor $tColor

        $ransomRow  = [Console]::CursorTop
        $ransom     = 10000 + ($elapsed * 1500) + ($pen * 500)
        $rFormatted = ("{0:N0}" -f $ransom) -replace ",", " "
        $rColor     = if ($ransom -lt 20000) { "Yellow" } elseif ($ransom -lt 50000) { "DarkYellow" } else { "Red" }
        Write-Host ("| Lösensumma: $rFormatted SEK").PadRight(44) -ForegroundColor $rColor

        Write-Host ("| Rum avklarade: $($GameState.completedQuestions) av $TotalQuestions").PadRight(44) -ForegroundColor Green
        Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
        Write-Host ""

        # Räkna ut vilken fråga vi faktiskt är på (Avklarade + 1)
        $currentNum = $GameState.completedQuestions + 1
        $headerText = "  RUM $currentNum (av $TotalQuestions):"

        $formattedOptions = @($headerText, "  $($Question.Question)")
        for ($i = 0; $i -lt $Question.Options.Length; $i++) {
            $formattedOptions += "  [$($i + 1)] $($Question.Options[$i])"
        }
        $width = ($formattedOptions | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host $headerText.PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  $($Question.Question)".PadRight($width) -ForegroundColor White
        Write-Host ""
        for ($i = 0; $i -lt $Question.Options.Length; $i++) {
            Write-Host "  [$($i + 1)] $($Question.Options[$i])".PadRight($width) -ForegroundColor Green
        }
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host -NoNewline "  Ditt svar: "

        # Spara exakt var inputraden är – används av timer-uppdateringen
        $inputRow  = [Console]::CursorTop
        $inputCol  = [Console]::CursorLeft

        [Console]::CursorVisible = $true

        # -------------------------------------------------------
        # LOOP – ingen Clear-Host, bara SetCursorPosition på rad 1+2
        # -------------------------------------------------------
        $inputBuffer = ""
        $lastUpdate  = [datetime]::MinValue

        while ($true) {

            # Uppdatera timern en gång per sekund utan att rensa skärmen
            $now = Get-Date
            if (($now - $lastUpdate).TotalSeconds -ge 1) {
                $lastUpdate = $now

                $ct      = Get-CurrentRansomwareTime -GameState $GameState
                $elapsed = if ($null -ne $ct) { $ct.TotalSeconds }   else { 0 }
                $pen     = if ($null -ne $ct) { $ct.PenaltySeconds } else { 0 }

                [Console]::CursorVisible = $false

                # Uppdatera timerrad (rad 1)
                [Console]::SetCursorPosition(0, $timerRow)
                $m      = [math]::Floor($elapsed / 60)
                $s      = $elapsed % 60
                $tColor = if ($elapsed -lt 60) { "Green" } elseif ($elapsed -lt 120) { "Yellow" } else { "Red" }
                Write-Host ("| Tid: $($m.ToString().PadLeft(2,'0')):$($s.ToString().PadLeft(2,'0'))").PadRight(44) `
                    -ForegroundColor $tColor -NoNewline

                # Uppdatera lösensummeraden (rad 2)
                [Console]::SetCursorPosition(0, $ransomRow)
                $ransom     = 10000 + ($elapsed * 1500) + ($pen * 500)
                $rFormatted = ("{0:N0}" -f $ransom) -replace ",", " "
                $rColor     = if ($ransom -lt 20000) { "Yellow" } elseif ($ransom -lt 50000) { "DarkYellow" } else { "Red" }
                Write-Host ("| Lösensumma: $rFormatted SEK").PadRight(44) `
                    -ForegroundColor $rColor -NoNewline

                # Flytta tillbaka markören till rätt position i inputraden
                [Console]::SetCursorPosition($inputCol + $inputBuffer.Length, $inputRow)
                [Console]::CursorVisible = $true
            }

            # Tangenthantering – skriver direkt till konsolen, ingen omritning
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)

                # ### ---> NYTT: Vi kollar om spelaren tryckte Ctrl + C
                if ($key.Key -eq [ConsoleKey]::C -and $key.Modifiers.HasFlag([ConsoleModifiers]::Control)) {
                    return -1  # Skicka signal om att spelet avbröts
                }

                if ($key.Key -eq [ConsoleKey]::Enter) {
                    $choice = 0
                    if ([int]::TryParse($inputBuffer, [ref]$choice) -and
                        $choice -ge 1 -and $choice -le $MaxOptions) {
                        Write-Host ""
                        return $choice
                    }
                    # Ogiltigt val – rensa buffern och inputraden
                    [Console]::SetCursorPosition($inputCol, $inputRow)
                    Write-Host (" " * $inputBuffer.Length) -NoNewline
                    [Console]::SetCursorPosition($inputCol, $inputRow)
                    $inputBuffer = ""
                }
                elseif ($key.Key -eq [ConsoleKey]::Backspace -and $inputBuffer.Length -gt 0) {
                    $inputBuffer = $inputBuffer.Substring(0, $inputBuffer.Length - 1)
                    [Console]::SetCursorPosition($inputCol + $inputBuffer.Length, $inputRow)
                    Write-Host " " -NoNewline
                    [Console]::SetCursorPosition($inputCol + $inputBuffer.Length, $inputRow)
                }
                elseif ($key.KeyChar -match '[1-9]') {
                    $num = [int]"$($key.KeyChar)"
                    if ($num -ge 1 -and $num -le $MaxOptions) {
                        $inputBuffer += $key.KeyChar
                        Write-Host $key.KeyChar -NoNewline
                    }
                }
            }

            Start-Sleep -Milliseconds 50
        }
    }
    finally {
        [Console]::CursorVisible = $true
    }
}

function Get-RansomwareQuestions {
    try {
        # $PSScriptRoot pekar på modules-mappen. Projektroten ligger en nivå upp.
        $projectRoot = Split-Path -Path $PSScriptRoot -Parent

        # Bygger sökvägen till questions.json i data-mappen.
        $path = Join-Path -Path $projectRoot -ChildPath "data\questions.json"

        # Kontrollerar att filen faktiskt finns innan vi försöker läsa den.
        if (-not (Test-Path -Path $path -PathType Leaf)) {
            throw "Frågefilen hittades inte: $path"
        }

        # Läser hela JSON-filen som en textsträng.
        # -Raw läser in hela filen som en enda sträng.
        # -Encoding UTF8 säkerställer att å, ä och ö visas rätt.
        $json = Get-Content -Path $path -Raw -Encoding UTF8 -ErrorAction Stop

        # Kontrollerar att filen inte är tom.
        if ([string]::IsNullOrWhiteSpace($json)) {
            throw "Frågefilen är tom: $path"
        }

        # Omvandlar JSON-texten till PowerShell-objekt.
        # Efter det här steget kan koden komma åt fälten med punktnotation,
        # till exempel $question.Question eller $question.Correct.
        $questions = $json | ConvertFrom-Json -ErrorAction Stop

        # Kontrollerar att vi faktiskt fick tillbaka minst en fråga.
        if ($null -eq $questions -or $questions.Count -eq 0) {
            throw "Inga frågor hittades i filen: $path"
        }

        return $questions
    }
    catch {
        # Skickar vidare felet med ett tydligt meddelande.
        # Invoke-RansomwareQuiz fångar felet och avbryter quizet på ett kontrollerat sätt.
        throw "Kunde inte ladda frågorna: $($_.Exception.Message)"
    }
}


# -----------------------------------------------------------------------------
# GET-SHUFFLEDQUESTION
# Tar emot en fråga och returnerar en kopia där svarsalternativen ligger
# i slumpad ordning. Bokstäverna A, B och C skrivs om så att de matchar
# de nya positionerna, och Correct uppdateras så att den fortfarande
# pekar på rätt alternativ.
# -----------------------------------------------------------------------------
function Get-ShuffledQuestion {
    param(
        [Parameter(Mandatory)]
        [object]$Question
    )

    # Lösningen: Tvinga det att bli [string] istället för [char]
    $optionsCount = $Question.Options.Count
    $letters = for ($i = 0; $i -lt $optionsCount; $i++) {
        [string][char](65 + $i)
    }

    $plainOptions = foreach ($option in $Question.Options) {
        $option -replace '^[A-Z]\.\s*', ''
    }

    # Nu kommer IndexOf att hitta "A" eftersom båda är strängar
    $originalIndex = $letters.IndexOf([string]$Question.Correct)
    $correctText = $plainOptions[$originalIndex]

    $shuffledOptions = $plainOptions | Get-Random -Count $plainOptions.Count

    $newOptions = for ($i = 0; $i -lt $shuffledOptions.Count; $i++) {
        "$($letters[$i]). $($shuffledOptions[$i])"
    }

    $newCorrectIndex = [array]::IndexOf($shuffledOptions, $correctText)
    $newCorrect = $letters[$newCorrectIndex]

    return [PSCustomObject]@{
        Number      = $Question.Number
        Question    = $Question.Question
        Options     = $newOptions
        Correct     = $newCorrect
        CorrectText = $Question.CorrectText
        WrongText   = $Question.WrongText
    }
}


# -----------------------------------------------------------------------------
# INVOKE-RANSOMWAREQUIZ
# Kör hela quizet från första till sista frågan.
# Hämtar frågorna, kör dem en i taget och returnerar ett slutresultat.
# -----------------------------------------------------------------------------
function Invoke-RansomwareQuiz {
    param(
        # GameState håller reda på spelarens framsteg, fel och straffsekunder
        [Parameter(Mandatory)]
        [object]$GameState,
        [string]$SavePath = ""

    )

    # Hämtar alla frågor från hjälpfunktionen, som laddar dem från questions.json.
    # Om filen saknas eller är trasig kastas ett fel som fångas här,
    # och felet skickas vidare till GameEngine via Start-NewGame.
    try {
        $questions = Get-RansomwareQuestions
    }
    catch {
        throw "Quizet kunde inte starta: $($_.Exception.Message)"
    }

$questions  = $questions | Get-Random -Count $questions.Count

    # Spara totalt antal innan vi skär bort avklarade frågor
    $totalQuestions = $questions.Count

    if ([int]$GameState.currentQuestionIndex -eq 0) {
        $GameState.startTime       = Get-Date
        $GameState.actualStartTime = $GameState.startTime
    }

    $startIndex = [int]$GameState.currentQuestionIndex
    $questions  = $questions | Select-Object -Skip $startIndex

    foreach ($question in $questions) {
        $shuffledQuestion = Get-ShuffledQuestion -Question $question
        
        # ### ---> NYTT: Vi skickar med SavePath ner till Invoke-RansomwareQuestion och tar emot status
        $status = Invoke-RansomwareQuestion -Question $shuffledQuestion -GameState $GameState -TotalQuestions $totalQuestions -SavePath $SavePath

        # ### ---> NYTT: Om funktionen svarar "Aborted", skickar vi tillbaka att spelet avbröts
        if ($status -eq "Aborted") {
            return [PSCustomObject]@{
                Success            = $false
                Aborted            = $true
                CompletedQuestions = $GameState.completedQuestions
                WrongAnswers       = $GameState.wrongAnswers
                PenaltySeconds     = $GameState.penaltySeconds
            }
        }

        # Räknar upp antalet avklarade frågor efter varje godkänt svar
        $GameState.completedQuestions++

        # Spara progress automatiskt efter varje korrekt svar
        if ($SavePath -ne "") {
            $GameState.currentQuestionIndex = $GameState.completedQuestions
            $ct = Get-CurrentRansomwareTime -GameState $GameState
            $GameState.elapsedSeconds  = if ($null -ne $ct) { $ct.ActualSeconds }   else { 0 }
            $GameState.penaltySeconds  = if ($null -ne $ct) { $ct.PenaltySeconds }  else { $GameState.penaltySeconds }
            Save-Game -Path $SavePath -SaveData $GameState
        }
    }
    

    # Returnerar ett sammanfattningsobjekt när alla frågor är klara
    # GameEngine använder det här för att spara resultatet och visa slutskärmen
    return [PSCustomObject]@{
        Success            = $true
        Aborted            = $false
        CompletedQuestions = $GameState.completedQuestions
        WrongAnswers       = $GameState.wrongAnswers
        PenaltySeconds     = $GameState.penaltySeconds
    }
}


function Invoke-RansomwareQuestion {
    param(
        [Parameter(Mandatory)][object]$Question,
        [Parameter(Mandatory)][object]$GameState,
        [Parameter(Mandatory)][int]$TotalQuestions,
        [string]$SavePath = "" # ### ---> NYTT: Parametern för att kunna spara vid Ctrl-C
    )

    $answeredCorrectly = $false

    # Registrera Ctrl-C hanterare så strafftiden sparas vid avbrott
    [Console]::TreatControlCAsInput = $true

    while (-not $answeredCorrectly) {
        try {
            # Read-LiveChoice ritar statusbar + fråga + hanterar input
            $choiceInt = Read-LiveChoice `
                -MaxOptions     $Question.Options.Length `
                -GameState      $GameState `
                -Question       $Question `
                -TotalQuestions $TotalQuestions

            # ### ---> NYTT: Hantera om vi fick tillbaka -1 (Ctrl-C) från Read-LiveChoice
            if ($choiceInt -eq -1) {
                if ($SavePath -ne "") {
                    # Spara aktuell strafftid och tid mitt i frågan innan vi hoppar ut
                    $GameState.currentQuestionIndex = $GameState.completedQuestions
                    $ct = Get-CurrentRansomwareTime -GameState $GameState
                    $GameState.elapsedSeconds  = if ($null -ne $ct) { $ct.ActualSeconds }   else { 0 }
                    $GameState.penaltySeconds  = if ($null -ne $ct) { $ct.PenaltySeconds }  else { $GameState.penaltySeconds }
                    
                    Save-Game -Path $SavePath -SaveData $GameState
                }
                return "Aborted" # Skickar tillbaka signalen till Quiz-loopen
            }

            # Skapa bokstäverna dynamiskt här också för rättningen
            $optionsCount = $Question.Options.Count
            $letters = for ($i = 0; $i -lt $optionsCount; $i++) {
                [string][char](65 + $i)
            }
            $correctInt = $letters.IndexOf([string]$Question.Correct) + 1

            if ($choiceInt -eq $correctInt) {
                $ct     = Get-CurrentRansomwareTime -GameState $GameState
                $actual = if ($null -ne $ct) { $ct.TotalSeconds } else { 0 }
                Write-SuccessMessage `
                    -Message    $Question.CorrectText `
                    -KeyNumber  ($GameState.completedQuestions + 1) `
                    -TotalKeys  $TotalQuestions `
                    -ElapsedSeconds $actual
                $answeredCorrectly = $true
            }
            else {
                Add-TimePenalty -GameState $GameState -Seconds 10
                Write-FailureMessage -Message $Question.WrongText -PenaltySeconds 10
            }
        }
        catch {
            Write-Notification -Message "Ett oväntat fel uppstod: $($_.Exception.Message)" -Type Error
            continue
        }
    }
}


# -----------------------------------------------------------------------------
# EXPORT
# Gör Invoke-RansomwareQuiz och Invoke-RansomwareQuestion tillgängliga
# för GameEngine när modulen laddas med Import-Module.
# Get-RansomwareQuestions och Read-RansomwareChoice exporteras inte
# eftersom de bara används internt i den här filen.
# -----------------------------------------------------------------------------
Export-ModuleMember -Function Invoke-RansomwareQuiz, Invoke-RansomwareQuestion, Read-LiveChoice, Get-RansomwareQuestions