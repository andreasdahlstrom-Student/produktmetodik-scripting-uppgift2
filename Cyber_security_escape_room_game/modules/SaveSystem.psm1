# SaveSystem.psm1
# Den här modulen hanterar all filhantering för spelet:
#   - Spara och ladda pågående spelomgång  → data\savegame.json
#   - Spara avslutade resultat till historik → data\scoreboard.json
#   - Återställa sparfilen till ett tomt standardläge

# ---------------------------------------------------------------------------
# HJÄLPFUNKTIONER – returnerar standardsökvägar till datafiler
# ---------------------------------------------------------------------------

function Get-DefaultSavePath {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    return Join-Path -Path $projectRoot -ChildPath "data\savegame.json"
}

function Get-DefaultScoreboardPath {
    $projectRoot = Split-Path -Path $PSScriptRoot -Parent
    return Join-Path -Path $projectRoot -ChildPath "data\scoreboard.json"
}

# ---------------------------------------------------------------------------
# DATASTRUKTUR – standardvärden för en ny/tom spelomgång
# ---------------------------------------------------------------------------

function New-DefaultSaveData {
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
    param(
        [string]$Path = (Get-DefaultSavePath)
    )

    try {
        return Test-Path -Path $Path -PathType Leaf -ErrorAction Stop
    }
    catch {
        return $false
    }
}

function Load-Scoreboard {
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

        return @($scoreboard)
    }
    catch {
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
    param(
        [Parameter(Mandatory)]
        [object]$GameState,

        [string]$Path = (Get-DefaultScoreboardPath)
    )

    try {
        $scoreboard = @(Load-Scoreboard -Path $Path)

        $result = [PSCustomObject]@{
            playerName         = [string]$GameState.playerName
            completedAt        = (Get-Date).ToString("s")
            actualTimeSeconds  = [int]$GameState.actualSeconds
            wrongAnswers       = [int]$GameState.wrongAnswers
            penaltySeconds     = [int]$GameState.penaltySeconds
            totalTimeSeconds   = [int]$GameState.totalSeconds
            completedQuestions = [int]$GameState.completedQuestions
            savedMoney         = 10000 + ([int]$GameState.actualSeconds * 1500) + ([int]$GameState.penaltySeconds * 500)
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
    param(
        [string]$Path = (Get-DefaultSavePath),
        [Parameter(Mandatory)]
        [object]$SaveData
    )

    try {
        $folder = Split-Path -Path $Path -Parent
        if (-not (Test-Path -Path $folder -PathType Container)) {
            New-Item -Path $folder -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $saves = @()
        if (Test-Path -Path $Path -PathType Leaf) {
            $existing = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($existing)) {
                $parsed = $existing | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($null -ne $parsed) {
                    $saves = @($parsed)
                }
            }
        }

        $SaveData.lastSaved = (Get-Date).ToString("s")

        $found = $false
        for ($i = 0; $i -lt $saves.Count; $i++) {
            if ($saves[$i].playerName -eq $SaveData.playerName -and -not $saves[$i].isCompleted) {
                $saves[$i] = $SaveData
                $found = $true
                break
            }
        }
        if (-not $found) {
            $saves += $SaveData
        }

        $json = ConvertTo-Json -InputObject $saves -Depth 10 -ErrorAction Stop
        Set-Content -Path $Path -Value $json -Encoding UTF8 -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException] {
        throw "Saknar behörighet att skriva till sparfilen '$Path'."
    }
    catch {
        throw "Kunde inte spara spelet till '$Path'. $($_.Exception.Message)"
    }
}

function Load-Game {
    param(
        [string]$Path = (Get-DefaultSavePath)
    )

    try {
        if (-not (Test-SaveFileExists -Path $Path)) {
            return @()
        }

        $json = Get-Content -Path $Path -Raw -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($json)) {
            return @()
        }

        $parsed = $json | ConvertFrom-Json -ErrorAction Stop

        if ($null -eq $parsed) {
            return @()
        }

        return @($parsed)
    }
    catch {
        throw "Kunde inte ladda sparfilen. $($_.Exception.Message)"
    }
}

function Reset-SaveGame {
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
Set-Alias -Name Get-GameSave   -Value Load-Game
Set-Alias -Name Reset-GameSave -Value Reset-SaveGame

# ---------------------------------------------------------------------------
# EXPORT – endast dessa funktioner och alias är synliga utanför modulen
# ---------------------------------------------------------------------------
Export-ModuleMember -Function Save-Game,
    Load-Game,
    Test-SaveFileExists,
    Reset-SaveGame,
    Initialize-Scoreboard,
    Load-Scoreboard,
    Save-ScoreboardResult,
    New-DefaultSaveData -Alias Get-GameSave, Reset-GameSave