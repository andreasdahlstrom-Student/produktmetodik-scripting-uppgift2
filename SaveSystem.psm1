# SaveSystem.psm1
# Den här modulen hanterar all filhantering för spelet:
#   - Spara och ladda pågående spelomgång  → data\savegame.json
#   - Spara avslutade resultat till historik → data\scoreboard.json
#   - Återställa sparfilen till ett tomt standardläge
#
# Används av:
#   GameEngine.psm1  – sparar och laddar speltillstånd under och efter en omgång
#   UI.psm1          – läser scoreboard-listan för att visa i terminalen

# ---------------------------------------------------------------------------
# HJÄLPFUNKTIONER – returnerar standardsökvägar till datafiler
# ---------------------------------------------------------------------------

function Get-DefaultSavePath {
    # Räknar ut sökvägen till savegame.json relativt till modulens plats.
    # PSScriptRoot pekar på modules-mappen; projektroten är ett steg upp.
    # Exempel på returvärde: C:\projekt\data\savegame.json
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    return Join-Path -Path $projectRoot -ChildPath "data\savegame.json"
}

function Get-DefaultScoreboardPath {
    # Samma logik som Get-DefaultSavePath men för scoreboard.json.
    # Den filen innehåller en JSON-array med ett objekt per avslutad omgång.
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    return Join-Path -Path $projectRoot -ChildPath "data\scoreboard.json"
}

# ---------------------------------------------------------------------------
# DATASTRUKTUR – standardvärden för en ny/tom spelomgång
# ---------------------------------------------------------------------------

function New-DefaultSaveData {
    # Skapar ett tomt speltillstånd som används vid ny start eller återställning.
    # Fälten speglar exakt vad GameEngine.psm1 fyller i under spelets gång:
    #
    #   playerName         – spelarens namn (sätts vid spelets start)
    #   startTime/endTime  – DateTime-objekt, sätts av Start/Stop-RansomwareTimer
    #   actualSeconds      – faktisk speltid utan strafftillägg
    #   wrongAnswers       – räknare för felaktiga svar
    #   penaltySeconds     – ackumulerade straffsekunder (10 sek per fel)
    #   totalSeconds       – actualSeconds + penaltySeconds = slutresultatet
    #   completedQuestions – antal frågor spelaren klarat av
    #   lastSaved          – ISO 8601-tidsstämpel, sätts automatiskt av Save-Game
    return [PSCustomObject]@{
        playerName         = ""
        startTime          = $null
        endTime            = $null
        actualSeconds      = 0
        wrongAnswers       = 0
        penaltySeconds     = 0
        totalSeconds       = 0
        completedQuestions = 0
        lastSaved          = ""
    }
}

# ---------------------------------------------------------------------------
# SCOREBOARD-HANTERING
# ---------------------------------------------------------------------------

function Initialize-Scoreboard {
    # Säkerställer att scoreboard-filen existerar och innehåller giltig JSON
    # innan någon annan funktion försöker läsa eller skriva till den.
    # Anropas automatiskt av Load-Scoreboard och Save-ScoreboardResult.
    #
    # Steg:
    #  1. Skapar data-mappen om den saknas.
    #  2. Skapar filen med en tom array "[]" om den inte finns.
    #  3. Ersätter filen med "[]" om den finns men är helt tom (korrupt skrivning).
    #  4. Returnerar sökvägen så anropande funktion kan kedja vidare.
    param(
        [string]$Path = (Get-DefaultScoreboardPath)
    )

    try {
        $folder = Split-Path -Path $Path -Parent

        if (-not (Test-Path -Path $folder -PathType Container)) {
            New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Set-Content -Path $Path -Value "[]" -Encoding UTF8 -ErrorAction Stop
        }

        $json = Get-Content -Path $Path -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($json)) {
            Set-Content -Path $Path -Value "[]" -Encoding UTF8 -ErrorAction Stop
        }

        return $Path
    }
    catch {
        throw "Kunde inte skapa scoreboard '$Path'. $($_.Exception.Message)"
    }
}

function Test-SaveFileExists {
    # Kontrollerar om en sparfil faktiskt finns på disk.
    # Används av Load-Game för att ge ett tydligt felmeddelande
    # istället för ett generellt "filen hittades ej"-undantag från PowerShell.
    # Returnerar $true om filen finns, annars $false.
    param(
        [string]$Path = (Get-DefaultSavePath)
    )

    try {
        return Test-Path -Path $Path -PathType Leaf -ErrorAction Stop
    }
    catch {
        Write-Host "Kunde inte kontrollera sparfilen: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Load-Scoreboard {
    # Läser in hela scoreboard-arrayen från JSON-filen.
    # Returnerar alltid en array (tom eller fylld) – aldrig $null –
    # så att anropande kod alltid kan loopa eller räkna element säkert.
    #
    # Om filen är skadad skrivs den över med en tom array och en
    # varning visas i konsolen – spelet kan fortsätta utan att krascha.
    param(
        [string]$Path = (Get-DefaultScoreboardPath)
    )

    try {
        Initialize-Scoreboard -Path $Path | Out-Null

        $json = Get-Content -Path $Path -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($json)) {
            return @()
        }

        $scoreboard = $json | ConvertFrom-Json -ErrorAction Stop

        if ($null -eq $scoreboard) {
            return @()
        }

        # @(...) garanterar att resultatet alltid är en array,
        # även om JSON-filen bara råkar innehålla ett enda objekt.
        return @($scoreboard)
    }
    catch {
        Write-Host "Scoreboard kunde inte läsas. En ny tom scoreboard skapas." -ForegroundColor Yellow
        try {
            Set-Content -Path $Path -Value "[]" -Encoding UTF8 -ErrorAction Stop
            return @()
        }
        catch {
            throw "Kunde inte återställa scoreboard '$Path'. $($_.Exception.Message)"
        }
    }
}

function Save-ScoreboardResult {
    # Lägger till ett avslutat spelresultat i scoreboard-filen.
    # Tar emot GameState-objektet från GameEngine.psm1 och plockar ut
    # de fält som är relevanta för historiken.
    #
    # OBS: completedQuestions sparas nu med för att UI.psm1 ska kunna
    # visa det fältet utan att det saknas i JSON-filen.
    #
    # Flöde:
    #  1. Läs in befintlig scoreboard-array.
    #  2. Bygg ett nytt resultatobjekt med aktuell tidsstämpel.
    #  3. Lägg till objektet i arrayen och skriv tillbaka hela filen.
    #  4. Returnera det sparade objektet (används av GameEngine för bekräftelse).
    param(
        [Parameter(Mandatory)]
        [object]$GameState,   # Skickas in från GameEngine när spelaren är klar

        [string]$Path = (Get-DefaultScoreboardPath)
    )

    try {
        $scoreboard = @(Load-Scoreboard -Path $Path)

        $result = [PSCustomObject]@{
            playerName         = [string]$GameState.playerName
            completedAt        = (Get-Date).ToString("s")   # ISO 8601, t.ex. 2025-06-01T14:32:00
            actualTimeSeconds  = [int]$GameState.actualSeconds
            wrongAnswers       = [int]$GameState.wrongAnswers
            penaltySeconds     = [int]$GameState.penaltySeconds
            totalTimeSeconds   = [int]$GameState.totalSeconds
            completedQuestions = [int]$GameState.completedQuestions   # TILLAGT: behövs av UI.psm1
        }

        $scoreboard += $result
        $json = ConvertTo-Json -InputObject $scoreboard -Depth 10 -ErrorAction Stop

        Set-Content -Path $Path -Value $json -Encoding UTF8 -ErrorAction Stop
        return $result
    }
    catch {
        throw "Kunde inte spara resultatet i scoreboard. $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# SPARFIL FÖR PÅGÅENDE SPELOMGÅNG
# ---------------------------------------------------------------------------

function Save-Game {
    # Skriver det aktuella speltillståndet till savegame.json.
    # Anropas av GameEngine.psm1 efter varje svar och när omgången är klar.
    #
    # PARAMETRAR: $Path kommer FÖRST för att matcha hur GameEngine anropar
    # funktionen med namngivna parametrar (-Path ... -SaveData ...).
    # Håll denna ordning för att undvika förvirring vid positionella anrop.
    #
    # Sätter automatiskt lastSaved till aktuell tid innan den skriver.
    # Skapar data-mappen om den inte finns ännu.
    param(
        [string]$Path = (Get-DefaultSavePath),   # Path FÖRST – matchar GameEngine

        [Parameter(Mandatory)]
        [object]$SaveData                          # Speltillståndsobjektet från GameEngine
    )

    try {
        $folder = Split-Path -Path $Path -Parent

        if (-not (Test-Path -Path $folder -PathType Container)) {
            New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $SaveData.lastSaved = (Get-Date).ToString("s")
        $json = $SaveData | ConvertTo-Json -Depth 10 -ErrorAction Stop

        Set-Content -Path $Path -Value $json -Encoding UTF8 -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        # Specifikt felmeddelande vid rättighetsproblem,
        # t.ex. på skoldatorer där data-mappen kan vara skrivskyddad.
        throw "Saknar behörighet att skriva till sparfilen '$Path'. Kontrollera filrättigheter."
    }
    catch {
        throw "Kunde inte spara spelet till '$Path'. $($_.Exception.Message)"
    }
}

function Load-Game {
    # Läser in ett tidigare sparat speltillstånd från savegame.json.
    # Anropas av GameEngine.psm1 vid start om spelaren väljer "Fortsätt".
    #
    # Kastar specifika undantag för de vanligaste felfallen så att
    # GameEngine kan ge spelaren ett begripligt felmeddelande:
    #   - Filen saknas       → ny installation eller raderad fil
    #   - Tom fil            → avbruten skrivning
    #   - Ogiltig JSON       → manuell redigering eller filkorruption
    #   - Behörighetsproblem → skrivskyddad mapp
    param(
        [string]$Path = (Get-DefaultSavePath)
    )

    try {
        if (-not (Test-SaveFileExists -Path $Path)) {
            throw "Sparfilen saknas: $Path"
        }

        $json = Get-Content -Path $Path -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($json)) {
            throw "Sparfilen är tom: $Path"
        }

        return $json | ConvertFrom-Json -ErrorAction Stop
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        throw "Sparfilen kunde inte hittas: $Path"
    }
    catch [System.UnauthorizedAccessException] {
        throw "Saknar behörighet att läsa sparfilen '$Path'. Kontrollera filrättigheter."
    }
    catch [System.ArgumentException] {
        # Kastas av ConvertFrom-Json när JSON-syntaxen är ogiltig.
        throw "Sparfilen innehåller trasig JSON. Återställ sparfilen eller kontrollera syntaxen i '$Path'."
    }
    catch {
        throw "Kunde inte ladda sparfilen. $($_.Exception.Message)"
    }
}

function Reset-SaveGame {
    # Återställer sparfilen till ett tomt standardtillstånd (New-DefaultSaveData).
    # Anropas av GameEngine.psm1 när spelaren startar en ny omgång
    # eller när en befintlig sparfil bedöms som oanvändbar.
    # Returnerar det nya tomma speltillståndet så GameEngine kan använda det direkt.
    param(
        [string]$Path = (Get-DefaultSavePath)
    )

    try {
        $defaultSave = New-DefaultSaveData
        Save-Game -Path $Path -SaveData $defaultSave
        return $defaultSave
    }
    catch {
        throw "Kunde inte återställa sparfilen. $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# ALIAS – bakåtkompatibilitet med äldre anrop i projektet
# ---------------------------------------------------------------------------

# Get-GameSave och Reset-GameSave är de namn som användes i ett tidigare skede.
# De pekar nu på Load-Game respektive Reset-SaveGame.
# Ta INTE bort dessa utan att stämma av med hela teamet.
Set-Alias -Name Get-GameSave   -Value Load-Game
Set-Alias -Name Reset-GameSave -Value Reset-SaveGame

# ---------------------------------------------------------------------------
# EXPORT – endast dessa funktioner och alias är synliga utanför modulen
# ---------------------------------------------------------------------------

# New-DefaultSaveData exporteras så att GameEngine eller SecurityChallenges
# kan skapa ett tomt speltillstånd direkt utan att gå via Reset-SaveGame.
Export-ModuleMember -Function `
    Save-Game, `
    Load-Game, `
    Test-SaveFileExists, `
    Reset-SaveGame, `
    Initialize-Scoreboard, `
    Load-Scoreboard, `
    Save-ScoreboardResult, `
    New-DefaultSaveData `
    -Alias Get-GameSave, Reset-GameSave
