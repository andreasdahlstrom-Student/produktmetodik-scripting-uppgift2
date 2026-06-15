﻿﻿# =============================================================================
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
# READ-RANSOMWARECHOICE
# Läser spelarens svar från terminalen och returnerar det som en bokstav.
# Accepterar endast bokstäverna A, B eller C.
# Returnerar $null om svaret är ogiltigt så att frågan kan visas igen.
# -----------------------------------------------------------------------------
function Read-RansomwareChoice {
    param(
        # Texten som visas i terminalen när spelaren ska skriva sitt svar
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    try {
        # Tömmer buffrade tangenttryckningar så att tidigare Enter-tryckningar
        # inte skickas in automatiskt som svar på nästa fråga
        $host.UI.RawUI.FlushInputBuffer()

        # Väntar på att spelaren skriver något och trycker Enter
        $choice = Read-Host $Prompt

        # Om spelaren bara tryckte Enter utan att skriva något returneras $null
        if ([string]::IsNullOrWhiteSpace($choice)) {
            return $null
        }

        # Tar bort mellanslag och gör om till versaler så att "a" och "A" behandlas lika
        $choice = $choice.Trim().ToUpper()

        # Accepterar endast A, B eller C
        # Allt annat returneras som $null vilket betyder ogiltigt svar
        switch ($choice) {
            "A" { return "A" }
            "B" { return "B" }
            "C" { return "C" }
            default { return $null }
        }
    }
    catch {
        # Om något oväntat gick fel vid inläsningen visas ett felmeddelande
        # och $null returneras så att frågan visas igen utan tidstillägg
        Write-Host "Terminalen kunde inte läsa ditt svar. Försök igen." -ForegroundColor Red
        return $null
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
        # Den ursprungliga frågan, med Options i den ordning de står i questions.json
        [Parameter(Mandatory)]
        [object]$Question
    )

    # Bokstäverna som ska stå framför varje alternativ, i ordning
    $letters = @("A", "B", "C")

    # Tar bort "A. ", "B. " och "C. " från varje alternativ så att vi har kvar
    # bara den rena texten. Annars hade den gamla bokstaven följt med
    # och hamnat på fel plats efter omslumpningen.
    $plainOptions = foreach ($option in $Question.Options) {
        $option -replace '^[ABC]\.\s*', ''
    }

    # Hittar vilken ren text som var det rätta svaret innan omslumpningen,
    # genom att slå upp Correct-bokstaven mot den ursprungliga listan.
    $originalIndex = $letters.IndexOf($Question.Correct)
    $correctText = $plainOptions[$originalIndex]

    # Slumpar ordningen på de rena alternativen.
    $shuffledOptions = $plainOptions | Get-Random -Count $plainOptions.Count

    # Sätter tillbaka A, B och C framför alternativen i den nya ordningen.
    $newOptions = for ($i = 0; $i -lt $shuffledOptions.Count; $i++) {
        "$($letters[$i]). $($shuffledOptions[$i])"
    }

    # Hittar den nya bokstaven för det rätta svaret genom att leta upp
    # var den korrekta texten hamnade efter omslumpningen.
    $newCorrectIndex = [array]::IndexOf($shuffledOptions, $correctText)
    $newCorrect = $letters[$newCorrectIndex]

    # Returnerar en ny fråga med samma text och feedback,
    # men med omslumpade alternativ och uppdaterat rätt svar.
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
        [object]$GameState
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

    # Slumpar ordningen på frågorna så att de inte kommer i samma ordning varje gång.
    # Get-Random -Count $questions.Count returnerar alla element men i slumpad ordning.
    $questions = $questions | Get-Random -Count $questions.Count

    # Går igenom varje fråga i den slumpade ordningen
    foreach ($question in $questions) {

        # Slumpar även ordningen på svarsalternativen för den här frågan.
        # Annars hade rätt svar alltid legat på samma plats i listan.
        $shuffledQuestion = Get-ShuffledQuestion -Question $question

        # Kör en enskild fråga och väntar tills spelaren svarar rätt
        Invoke-RansomwareQuestion -Question $shuffledQuestion -GameState $GameState -TotalQuestions $questions.Count

        # Räknar upp antalet avklarade frågor efter varje godkänt svar
        $GameState.completedQuestions++
    }

    # Returnerar ett sammanfattningsobjekt när alla frågor är klara
    # GameEngine använder det här för att spara resultatet och visa slutskärmen
    return [PSCustomObject]@{
        Success            = $true
        CompletedQuestions = $GameState.completedQuestions
        WrongAnswers       = $GameState.wrongAnswers
        PenaltySeconds     = $GameState.penaltySeconds
    }
}


# -----------------------------------------------------------------------------
# INVOKE-RANSOMWAREQUESTION
# Hanterar en enskild fråga.
# Visar frågan, läser spelarens svar och ger feedback.
# Loopar tills spelaren svarar rätt - fel svar ger tidstillägg men spelaren
# får försöka igen på samma fråga.
# -----------------------------------------------------------------------------
function Invoke-RansomwareQuestion {
    param(
        # Question innehåller frågetext, svarsalternativ, rätt svar och feedback
        [Parameter(Mandatory)]
        [object]$Question,

        # GameState används för att hämta aktuell tid och lägga till straffsekunder
        [Parameter(Mandatory)]
        [object]$GameState,

        # TotalQuestions används för att visa "Fråga X av Y" i frågehuvudet
        [Parameter(Mandatory)]
        [int]$TotalQuestions
    )

    # Sätts till $false i början och blir $true när spelaren svarar rätt
    # While-loopen fortsätter så länge den är $false
    $answeredCorrectly = $false

    while (-not $answeredCorrectly) {

        # Hela frågans logik ligger i ett try/catch så att ett oväntat fel
        # inte kraschar spelet utan istället visar ett felmeddelande och loopar om
        try {

            # Försöker hämta och visa aktuell tid för spelaren
            try {
                # Hämtar aktuell tid från GameEngine
                $currentTime = Get-CurrentRansomwareTime -GameState $GameState

                # Visar frågenummer och ackumulerade straffsekunder högst upp
                Show-QuestionHeader -QuestionNumber $Question.Number -TotalQuestions $TotalQuestions -PenaltySeconds $currentTime.PenaltySeconds

                # Visar den löpande timern med total tid, antal fel och straffsekunder
                Show-CurrentTimer -TotalSeconds $currentTime.TotalSeconds -WrongAnswers $currentTime.WrongAnswers -PenaltySeconds $currentTime.PenaltySeconds
            }
            catch {
                # Om timern inte kan visas fortsätter spelet ändå med den info vi har
                Show-QuestionHeader -QuestionNumber $Question.Number -TotalQuestions $TotalQuestions -PenaltySeconds $GameState.penaltySeconds
                Show-Error "Kunde inte visa aktuell tid: $($_.Exception.Message)"
            }

            # Visar frågetexten i vitt så den syns tydligt
            Write-Host $Question.Question -ForegroundColor White
            Write-Host ""

            # Visar alla svarsalternativ, till exempel:
            # A. Koppla bort datorn från nätverket och kontakta IT
            # B. Betala lösensumman direkt
            # C. Starta om datorn flera gånger
            foreach ($option in $Question.Options) {
                Write-Host $option -ForegroundColor Gray
            }

            Write-Host ""

            # Läser och validerar spelarens svar via hjälpfunktionen
            # Returnerar A, B eller C om giltigt - annars $null
            $choice = Read-RansomwareChoice -Prompt "Ditt svar (A, B eller C)"

            # Ogiltigt svar ger inget tidstillägg, bara ett meddelande och loopen börjar om
            if ($null -eq $choice) {
                Show-FailureMessage "Ogiltig input. Skriv A, B eller C."
                continue
            }

            # Jämför spelarens svar med det korrekta svaret
            if ($choice -eq $Question.Correct) {

                # Rätt svar - visar positiv feedback och avslutar loopen
                Show-CorrectAnswerMessage -Message $Question.CorrectText
                $answeredCorrectly = $true
            }
            else {
                # Fel svar - lägger till 10 sekunders tidstillägg och visar förklaring
                # Spelaren får försöka igen på samma fråga
                Add-TimePenalty -GameState $GameState -Seconds 10
                Show-WrongAnswerMessage -Message $Question.WrongText -PenaltySeconds 10
            }
        }
        catch {
            # Om något helt oväntat kraschar inne i frågeloopen
            # visas ett felmeddelande och loopen börjar om istället för att spelet kraschar
            Show-Error "Ett oväntat fel uppstod i frågan: $($_.Exception.Message)"
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
Export-ModuleMember -Function Invoke-RansomwareQuiz, Invoke-RansomwareQuestion