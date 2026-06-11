# =============================================================================
# SecurityChallenges.psm1
# =============================================================================
# Ansvar:
#   Den här modulen ansvarar för quizlogiken i spelet.
#   Den innehåller frågorna, läser spelarens svar och avgör om svaret är rätt.
#
# Funktioner som GameEngine anropar utifrån:
#   Invoke-RansomwareQuiz     - kör hela quizet med alla frågor
#   Invoke-RansomwareQuestion - hanterar en enskild fråga
#
# Interna hjälpfunktioner som bara används i den här filen:
#   Get-RansomwareQuestions   - returnerar alla frågor som objekt
#   Read-RansomwareChoice     - läser och validerar spelarens svar
# =============================================================================


# -----------------------------------------------------------------------------
# GET-RANSOMWAREQUESTIONS
# Returnerar alla ransomware-frågor som en lista av objekt.
# Varje objekt innehåller frågetext, svarsalternativ, rätt svar och feedback.
# -----------------------------------------------------------------------------
function Get-RansomwareQuestions {
    return @(
        # Fråga 1: Vad är ransomware?
        [PSCustomObject]@{
            Number      = 1
            Question    = "Vad är ransomware?"
            Options     = @(
                "A. Ett program som förbättrar datorns prestanda",
                "B. Skadlig kod som krypterar filer och kräver lösensumma",
                "C. Ett vanligt antivirusprogram"
            )
            Correct     = "B"
            # Texten som visas när spelaren svarar rätt
            CorrectText = "Rätt. Ransomware låser eller krypterar filer och försöker pressa offret på pengar."
            # Texten som visas när spelaren svarar fel
            WrongText   = "Fel. Ransomware är skadlig kod som krypterar filer och kräver lösensumma."
        }

        # Fråga 2: Vad gör man först vid misstänkt ransomware?
        [PSCustomObject]@{
            Number      = 2
            Question    = "Vad är det bästa första steget om du misstänker ransomware?"
            Options     = @(
                "A. Koppla bort datorn från nätverket och kontakta IT",
                "B. Betala lösensumman direkt",
                "C. Starta om datorn flera gånger"
            )
            Correct     = "A"
            CorrectText = "Rätt. Att koppla bort datorn kan bromsa spridning, och IT kan hjälpa till på rätt sätt."
            WrongText   = "Fel. Första steget är att isolera datorn från nätverket och kontakta IT eller ansvarig vuxen."
        }

        # Fråga 3: Vilket skydd minskar risken att förlora data?
        [PSCustomObject]@{
            Number      = 3
            Question    = "Vilket skydd minskar risken att förlora data vid ransomware?"
            Options     = @(
                "A. Regelbundna säkerhetskopior",
                "B. Att använda samma lösenord överallt",
                "C. Att ignorera säkerhetsuppdateringar"
            )
            Correct     = "A"
            CorrectText = "Rätt. Säkerhetskopior gör det möjligt att återställa filer utan att betala angriparen."
            WrongText   = "Fel. Regelbundna säkerhetskopior är ett av de viktigaste skydden mot dataförlust."
        }

        # Fråga 4: Hur sprids ransomware?
        [PSCustomObject]@{
            Number      = 4
            Question    = "Hur sprids ransomware ofta?"
            Options     = @(
                "A. Genom phishingmejl och skadliga bilagor",
                "B. Genom att skärmen är för ljus",
                "C. Genom att datorn är avstängd"
            )
            Correct     = "A"
            CorrectText = "Rätt. Phishingmejl, falska länkar och skadliga bilagor är vanliga vägar in."
            WrongText   = "Fel. Ransomware sprids ofta via phishingmejl, skadliga bilagor och osäkra länkar."
        }

        # Fråga 5: Varför ska man vara försiktig med okända bilagor?
        [PSCustomObject]@{
            Number      = 5
            Question    = "Varför bör man vara försiktig med okända bilagor?"
            Options     = @(
                "A. De kan innehålla skadlig kod",
                "B. De gör alltid datorn snabbare",
                "C. De uppdaterar automatiskt antivirus"
            )
            Correct     = "A"
            CorrectText = "Rätt. Okända bilagor kan innehålla skadlig kod och ska kontrolleras innan de öppnas."
            WrongText   = "Fel. Okända bilagor kan innehålla skadlig kod, även om mejlet ser trovärdigt ut."
        }
    )
}


# -----------------------------------------------------------------------------
# READ-RANSOMWARECHOICE
# Läser spelarens svar från terminalen och returnerar det som en bokstav.
# Accepterar både bokstäver (A, B, C) och siffror (1, 2, 3) (LOL)
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

        # Översätter spelarens svar till en bokstav
        # Siffror 1, 2, 3 accepteras som alternativ till A, B, C
        # Allt annat returneras som $null vilket betyder ogiltigt svar
        switch ($choice) {
            "1" { return "A" }
            "2" { return "B" }
            "3" { return "C" }
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

    # Hämtar alla frågor från hjälpfunktionen
    $questions = Get-RansomwareQuestions

    # Går igenom varje fråga i ordning
    foreach ($question in $questions) {

        # Kör en enskild fråga och väntar tills spelaren svarar rätt
        Invoke-RansomwareQuestion -Question $question -GameState $GameState -TotalQuestions $questions.Count

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
