# UI.psm1
# =============================================================================
# UI-MODUL FÖR CYBER SECURITY ESCAPE ROOM
# =============================================================================
# Syfte:
#   Denna modul hanterar all visuell output i spelet (menyer, status, meddelanden).
#   Den importeras av andra skript via: Import-Module ./Modules/UI.psm1
#
# PowerShell-konvention:
#   Funktionsnamn följer mönstret GodkäntVerb-Substantiv.
#   "Write" används för utskrift, "Wait" för pausning.
#
# Teckenkodning:
#   Windows PowerShell 5.1 kräver UTF-8-inställning för å, ä, ö.
#   Spara denna fil som UTF-8 with BOM i VS Code.
# =============================================================================

# -----------------------------------------------------------------------------
# KONSOLKODNING
# Körs automatiskt när modulen laddas så svenska tecken visas rätt
# -----------------------------------------------------------------------------
function Set-UIConsoleEncoding {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        return
    }
    try {
        chcp 65001 | Out-Null
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
        $script:OutputEncoding    = [System.Text.Encoding]::UTF8
    }
    catch {
        Write-Warning "Kunde inte ställa in UTF-8. Svenska tecken kan visas fel."
    }
}

Set-UIConsoleEncoding

# -----------------------------------------------------------------------------
# HP-BAR
# Visar spelarens hälsa som en visuell stapel med Unicode-blocktecken
# -----------------------------------------------------------------------------
function Write-HPBar {
    param(
        [Parameter(Mandatory)]
        [int]$CurrentHP,
        [int]$MaxHP = 100
    )

    try {
        # Beräknar hur många av 20 block som ska vara ifyllda
        $barLength = 20
        $filled    = [math]::Round(($CurrentHP / $MaxHP) * $barLength)
        $empty     = $barLength - $filled

        # █ = fyllt, ░ = tomt
        $bar = ("█" * $filled) + ("░" * $empty)

        # Färg ändras efter hur mycket HP som återstår
        if ($CurrentHP -gt 60) {
            $color = "Green"
        }
        elseif ($CurrentHP -gt 30) {
            $color = "Yellow"
        }
        else {
            $color = "Red"
        }

        Write-Host "| HP: [$bar] $CurrentHP/$MaxHP" -ForegroundColor $color
    }
    catch {
        Write-Host "| HP: [fel vid rendering] $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# STATUSBAR
# Samlar HP, poäng och rum-progress i en ruta
# -----------------------------------------------------------------------------
function Write-StatusBar {
    param(
        [Parameter(Mandatory)][int]$CurrentHP,
        [int]$MaxHP = 100,
        [Parameter(Mandatory)][int]$Score,
        [int]$CompletedRooms = 0,
        [int]$TotalRooms = 3
    )

    try {
        Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkGreen
        Write-HPBar -CurrentHP $CurrentHP -MaxHP $MaxHP
        Write-Host "| Poäng: $Score" -ForegroundColor Green
        Write-Host "| Rum avklarade: $CompletedRooms av $TotalRooms" -ForegroundColor Green
        Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa statusbar: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# GAME OVER
# Visas när spelarens HP når 0
# -----------------------------------------------------------------------------
function Write-GameOver {
    try {
        $lines = @(
            "  GAME OVER",
            "  Du tog för mycket skada och systemet stängde.",
            "  Starta om och försök igen..."
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Clear-Host
        Write-Host ""
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  GAME OVER".PadRight($width) -ForegroundColor Red
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  Du tog för mycket skada och systemet stängde.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Starta om och försök igen...".PadRight($width) -ForegroundColor Gray
        Write-Host $line -ForegroundColor DarkRed
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa Game Over: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# VINST
# Visas när spelaren klarat alla rum
# -----------------------------------------------------------------------------
function Write-Victory {
    param(
        [Parameter(Mandatory)][int]$FinalScore
    )

    try {
        $lines = @(
            "  DU KLARADE DET!",
            "  Alla säkerhetsrum är upplåsta.",
            "  Slutpoäng: $FinalScore"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Clear-Host
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  DU KLARADE DET!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  Alla säkerhetsrum är upplåsta.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Slutpoäng: $FinalScore".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa Victory: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# TITELSKÄRM
# Första skärmen när spelet startar (ASCII-art + titel)
# -----------------------------------------------------------------------------
function Write-Title {
    try {
        Clear-Host
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "     ░█████╗░██╗░░░██╗██████╗░███████╗██████╗   " -ForegroundColor Green
        Write-Host "     ██╔══██╗╚██╗░██╔╝██╔══██╗██╔════╝██╔══██╗  " -ForegroundColor Green
        Write-Host "     ██║░░╚═╝░╚████╔╝░██████╦╝█████╗░░██████╔╝  " -ForegroundColor Green
        Write-Host "     ██║░░██╗░░╚██╔╝░░██╔══██╗██╔══╝░░██╔══██╗  " -ForegroundColor Green
        Write-Host "     ╚█████╔╝░░░██║░░░██████╦╝███████╗██║░░██║  " -ForegroundColor Green
        Write-Host "     ░╚════╝░░░░╚═╝░░░╚═════╝░╚══════╝╚═╝░░╚═╝  " -ForegroundColor Green
        Write-Host "                                                  " -ForegroundColor Green
        Write-Host "           CYBER SECURITY ESCAPE ROOM            " -ForegroundColor Green
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host "     Samla nycklarna. Lås upp rummen. Fly.       " -ForegroundColor DarkGreen
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa titelskärm: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# HUVUDMENY
# Tar emot en lista med alternativ och skriver ut dem numrerade
# -----------------------------------------------------------------------------
function Write-Menu {
    param(
        [Parameter(Mandatory)]
        [string[]]$Options
    )

    try {
        $formattedOptions = @()
        for ($i = 0; $i -lt $Options.Length; $i++) {
            $num = $i + 1
            $formattedOptions += "  [$num] $($Options[$i])"
        }

        $width  = ($formattedOptions | Measure-Object -Property Length -Maximum).Maximum + 4
        $line   = "+" + ("-" * ($width - 2)) + "+"
        $header = "  HUVUDMENY"

        Write-Host $line -ForegroundColor DarkGreen
        Write-Host $header.PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen

        foreach ($option in $formattedOptions) {
            Write-Host $option.PadRight($width) -ForegroundColor Green
        }

        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa meny: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# SPELINSTRUKTIONER
# Visas innan spelet börjar så spelaren förstår reglerna
# -----------------------------------------------------------------------------
function Write-Instructions {
    try {
        $lines = @(
            "  SPELINSTRUKTIONER",
            "  Du har 100 HP att börja med.",
            "  Varje fel svar kostar dig 25 HP.",
            "  Når HP 0 är spelet över.",
            "  Svara rätt för att tjäna poäng och låsa upp rum.",
            "  Klara alla 3 rum för att vinna!"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  SPELINSTRUKTIONER".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  Du har 100 HP att börja med.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Varje fel svar kostar dig 25 HP.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Når HP 0 är spelet över.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Svara rätt för att tjäna poäng och låsa upp rum.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Klara alla 3 rum för att vinna!".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""

        # Pausar tills spelaren är redo
        try {
            Read-Host "  Tryck Enter för att fortsätta"
        }
        catch {
            Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Kunde inte visa instruktioner: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# RUM-INTRO
# Visas när spelaren går in i ett nytt rum
# -----------------------------------------------------------------------------
function Write-RoomIntro {
    param(
        [Parameter(Mandatory)][string]$RoomName,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][int]$RoomNumber,
        [int]$TotalRooms = 3,
        [int]$Points = 100
    )

    try {
        $lines = @(
            "  [RUM $RoomNumber AV $TotalRooms]",
            "  $RoomName",
            "  $Description",
            "  Säkerhetsnycklar att vinna: $Points p"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Clear-Host
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  [RUM $RoomNumber AV $TotalRooms]".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  $RoomName".PadRight($width) -ForegroundColor Green
        Write-Host ""
        Write-Host "  $Description".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Säkerhetsnycklar att vinna: $Points p".PadRight($width) -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""

        try {
            Read-Host "  Tryck Enter för att börja"
        }
        catch {
            Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Kunde inte visa rumintro: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# RÄTT SVAR
# Visas när spelaren svarar korrekt
# -----------------------------------------------------------------------------
function Write-SuccessMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [int]$PointsEarned = 100
    )

    try {
        $lines = @(
            "  [KORREKT] SÄKERHETSNYCKEL UPPLÅST!",
            "  $Message",
            "  + $PointsEarned poäng tillagda!"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  [KORREKT] SÄKERHETSNYCKEL UPPLÅST!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  $Message".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host "  + $PointsEarned poäng tillagda!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""

        try {
            Read-Host "  Tryck Enter för att fortsätta"
        }
        catch {
            Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Kunde inte visa success-meddelande: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# FEL SVAR
# Visas när spelaren svarar fel — HP dras av
# -----------------------------------------------------------------------------
function Write-FailureMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [int]$HPLost = 25
    )

    try {
        $lines = @(
            "  [FEL] ÅTKOMST NEKAD!",
            "  $Message",
            "  - $HPLost HP förlorat!"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  [FEL] ÅTKOMST NEKAD!".PadRight($width) -ForegroundColor Red
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  $Message".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host "  - $HPLost HP förlorat!".PadRight($width) -ForegroundColor Red
        Write-Host $line -ForegroundColor DarkRed
        Write-Host ""

        try {
            Read-Host "  Tryck Enter för att försöka igen"
        }
        catch {
            Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Kunde inte visa felmeddelande: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# VISA FRÅGA
# Visar en fråga med svarsalternativ och returnerar spelarens val (siffra)
# Använder rekursion för att fråga om vid ogiltigt svar
# -----------------------------------------------------------------------------
function Write-Question {
    param(
        [Parameter(Mandatory)][string]$Question,
        [Parameter(Mandatory)][string[]]$Options
    )

    try {
        $formattedOptions = @("  FRÅGA:", "  $Question")
        for ($i = 0; $i -lt $Options.Length; $i++) {
            $num = $i + 1
            $formattedOptions += "  [$num] $($Options[$i])"
        }

        $width = ($formattedOptions | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  FRÅGA:".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  $Question".PadRight($width) -ForegroundColor White
        Write-Host ""

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $num = $i + 1
            Write-Host "  [$num] $($Options[$i])".PadRight($width) -ForegroundColor Green
        }

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""

        # Läser spelarens svar — $input är reserverat i PS, använder $playerAnswer
        $playerAnswer = Read-Host "  Ditt svar"
        $choice       = [int]$playerAnswer

        if ($choice -lt 1 -or $choice -gt $Options.Length) {
            Write-Host ""
            Write-Host "  Ogiltigt val! Ange en siffra mellan 1 och $($Options.Length)." -ForegroundColor Red
            Write-Host ""
            return Write-Question -Question $Question -Options $Options
        }

        return $choice
    }
    catch {
        # Hamnar här om spelaren skriver en bokstav istället för siffra
        Write-Host ""
        Write-Host "  Ogiltigt svar! Ange endast en siffra." -ForegroundColor Red
        Write-Host ""
        return Write-Question -Question $Question -Options $Options
    }
}

# -----------------------------------------------------------------------------
# PAUSA SPELET
# Väntar på att spelaren trycker Enter
# -----------------------------------------------------------------------------
function Wait-Game {
    try {
        Read-Host "  Tryck Enter för att fortsätta"
    }
    catch {
        Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# NEDRÄKNING
# Dramatisk nedräkning innan ett rum startar
# -----------------------------------------------------------------------------
function Write-Countdown {
    param(
        [int]$Seconds = 3,
        [string]$Message = "INTRÅNG DETEKTERAT!"
    )

    try {
        Write-Host ""
        Write-Host "  Systemet initieras..." -ForegroundColor DarkGreen
        Write-Host ""

        for ($i = $Seconds; $i -gt 0; $i--) {
            Write-Host "         $i..." -ForegroundColor Green
            Start-Sleep -Seconds 1
        }

        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Green
        Write-Host ""
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Host "  Startar rummet..." -ForegroundColor DarkGreen
    }
}

# -----------------------------------------------------------------------------
# SPARAT
# Visas när spelarens spel sparas till JSON
# -----------------------------------------------------------------------------
function Write-SaveConfirmation {
    try {
        Write-Host ""
        Write-Host "  [SPARAT] Ditt spel har sparats!" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa sparbekräftelse: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# LADDAT
# Visas när ett sparat spel laddas från JSON
# -----------------------------------------------------------------------------
function Write-LoadConfirmation {
    try {
        Write-Host ""
        Write-Host "  [LADDAT] Välkommen tillbaka!" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa laddbekräftelse: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# EXPORTERA FUNKTIONER
# Gör alla funktioner tillgängliga när modulen importeras med Import-Module
# -----------------------------------------------------------------------------
Export-ModuleMember -Function `
    Write-HPBar, Write-StatusBar, Write-GameOver, Write-Victory, `
    Write-Title, Write-Menu, Write-Instructions, Write-RoomIntro, `
    Write-SuccessMessage, Write-FailureMessage, Write-Question, `
    Wait-Game, Write-Countdown, Write-SaveConfirmation, Write-LoadConfirmation