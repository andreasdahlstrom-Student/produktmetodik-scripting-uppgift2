# SaveSystem.psm1
# Skapad av mig för vårt Escape Room-projekt.
# Den här modulen sköter all hantering av sparfiler via JSON.

# ==========================================
# FUNKTION: Hitta rätt till sparfilen
# ==========================================
function Get-DefaultSavePath {
    # Vi utgår från där denna modul ligger och backar upp ett steg till projektmappen
    $mainFolder = Split-Path -Path $PSScriptRoot -Parent
    
    # Sätter ihop sökvägen till filen i data-mappen utan svenska tecken i koden
    $fileRoute = Join-Path -Path $mainFolder -ChildPath "data\savegame.json"
    return $fileRoute
}

# ==========================================
# FUNKTION: Skapa nystart (Tom spelarprofil)
# ==========================================
function New-DefaultSaveData {
    # Här sätter vi grundreglerna för hur en helt ny spelare startar spelet
    $startProfile = [PSCustomObject]@{
        playerName     = ""       # Spelarens namn (fylls i vid start)
        currentRoom    = 0        # Börjar alltid i rum noll
        score          = 0        # Startpoäng är noll
        completedRooms = @()      # Array för att spara rummen man klarat av
        lastSaved      = ""       # Tidstämpel som uppdateras vid sparning
    }
    return $startProfile
}

# ==========================================
# FUNKTION: Kolla om sparfilen existerar
# ==========================================
function Test-SaveFileExists {
    param(
        [string]$TargetPath = (Get-DefaultSavePath)
    )

    try {
        # Kollar om filen finns på datorn. Stop gör att vi hoppar till catch om något strular.
        $fileCheck = Test-Path -Path $TargetPath -PathType Leaf -ErrorAction Stop
        return $fileCheck
    }
    catch {
        Write-Host "Fel vid sökning efter sparfil: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ==========================================
# FUNKTION: Spara spelarens framsteg
# ==========================================
function Save-Game {
    param(
        [Parameter(Mandatory=$true)]
        [object]$PlayerData,

        [string]$TargetPath = (Get-DefaultSavePath)
    )

    try {
        # Hämta mappen där filen ska ligga (data-mappen)
        $destinationFolder = Split-Path -Path $TargetPath -Parent

        # Om mappen saknas så skapar vi den direkt
        if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
            New-Item -Path $destinationFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        # Sätt aktuell tid på sparningen
        $PlayerData.lastSaved = (Get-Date).ToString("s")
        
        # Gör om objektet till läsbar JSON-text
        $jsonOutput = $PlayerData | ConvertTo-Json -Depth 10 -ErrorAction Stop

        # Skriv texten till sparfilen
        Set-Content -Path $TargetPath -Value $jsonOutput -Encoding UTF8 -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        throw "Antivirus eller systemrättigheter blockerar sparning till: '$TargetPath'."
    }
    catch {
        throw "Det gick inte att spara spelet: $($_.Exception.Message)"
    }
}

# ==========================================
# FUNKTION: Ladda tidigare sparat spel
# ==========================================
function Load-Game {
    param(
        [string]$TargetPath = (Get-DefaultSavePath)
    )

    try {
        # Kontrollera först så att filen faktiskt finns där
        if (-not (Test-SaveFileExists -Path $TargetPath)) {
            throw "Hittade ingen sparfil på: $TargetPath"
        }

        # Läs in all text från filen
        $rawText = Get-Content -Path $TargetPath -Raw -ErrorAction Stop

        # Kolla så att filen inte råkar vara helt tom
        if ([string]::IsNullOrWhiteSpace($rawText)) {
            throw "Sparfilen är tom eller skadad."
        }

        # Översätt JSON-texten tillbaka till ett objekt spelet förstår
        $loadedObject = $rawText | ConvertFrom-Json -ErrorAction Stop
        return $loadedObject
    }
    catch [System.UnauthorizedAccessException] {
        throw "Du saknar behörighet att läsa filen på '$TargetPath'."
    }
    catch [System.ArgumentException] {
        throw "Sparfilen innehåller felaktig JSON-kod. Kontrollera syntaxen."
    }
    catch {
        throw "Kunde inte ladda spelet: $($_.Exception.Message)"
    }
}

# ==========================================
# FUNKTION: Nollställ sparfilen (Börja om)
# ==========================================
function Reset-SaveGame {
    param(
        [string]$TargetPath = (Get-DefaultSavePath)
    )

    try {
        # Skapa ny tom data och skriv över den gamla filen
        $freshStart = New-DefaultSaveData
        Save-Game -PlayerData $freshStart -TargetPath $TargetPath
        return $freshStart
    }
    catch {
        throw "Nollställning misslyckades: $($_.Exception.Message)"
    }
}

# ==========================================
# ALIAS & EXPORT (Gör funktionerna synliga för spelet)
# ==========================================
Set-Alias -Name Get-GameSave -Value Load-Game
Set-Alias -Name Reset-GameSave -Value Reset-SaveGame

# Exportera funktionerna så att de kan anropas utifrån
Export-ModuleMember -Function Save-Game, Load-Game, Test-SaveFileExists, Reset-SaveGame -Alias Get-GameSave, Reset-GameSave