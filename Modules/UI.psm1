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
# TIMER
# Visar spelarens nuvarande tid i MM:SS-format
# Tar emot antal sekunder och formaterar det snyggt
# -----------------------------------------------------------------------------
function Write-Timer {
    param(
        [Parameter(Mandatory)][int]$ElapsedSeconds,  # Totalt antal sekunder spelaren spelat
        [int]$PenaltySeconds = 0                     # Ackumulerade straffsekunder
    )

    try {
        # Räknar om sekunder till minuter och sekunder
        $minutes = [math]::Floor($ElapsedSeconds / 60)
        $seconds = $ElapsedSeconds % 60

        # Formaterar som MM:SS med ledande nolla (t.ex. 01:05)
        $timeFormatted = "$($minutes.ToString().PadLeft(2,'0')):$($seconds.ToString().PadLeft(2,'0'))"

        # Väljer färg baserat på hur lång tid som gått
        if ($ElapsedSeconds -lt 60) {
            $color = "Green"   # Under 1 minut
        }
        elseif ($ElapsedSeconds -lt 120) {
            $color = "Yellow"  # 1-2 minuter
        }
        else {
            $color = "Red"     # Över 2 minuter
        }

        Write-Host "| Tid: $timeFormatted" -ForegroundColor $color

        # Visar straffsekunder om spelaren fått några
        if ($PenaltySeconds -gt 0) {
            Write-Host "| Straff: +$($PenaltySeconds)s" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "| Tid: [fel vid rendering] $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# STATUSBAR
# Visar tid, straffsekunder och rum-progress
# Anropas av GameEngine för att hålla spelaren uppdaterad
# -----------------------------------------------------------------------------
function Write-StatusBar {
    param(
        [Parameter(Mandatory)][int]$ElapsedSeconds,  # Tid sedan spelet startade
        [int]$PenaltySeconds = 0,                    # Totala straffsekunder
        [int]$CompletedRooms = 0,                    # Antal avklarade rum
        [int]$TotalRooms = 3                         # Totalt antal rum
    )

    try {
        Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkGreen
        Write-Timer -ElapsedSeconds $ElapsedSeconds -PenaltySeconds $PenaltySeconds
        Write-Host "| Rum avklarade: $CompletedRooms av $TotalRooms" -ForegroundColor Green
        Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
        Write-Host ""
    }
    catch {
        Write-Host "  Kunde inte visa statusbar: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# VINST
# Visas när spelaren klarat alla rum
# Visar totaltid inklusive straffsekunder
# -----------------------------------------------------------------------------
function Write-Victory {
    param(
        [Parameter(Mandatory)][int]$ElapsedSeconds,  # Spelarens totala tid
        [int]$PenaltySeconds = 0,                    # Totala straffsekunder
        [int]$KeysFound = 3                          # Antal nyckelbitar hittade
    )

    try {
        # Räknar ut totaltid inklusive straff
        $totalSeconds = $ElapsedSeconds + $PenaltySeconds
        $minutes      = [math]::Floor($totalSeconds / 60)
        $seconds      = $totalSeconds % 60
        "$($minutes.ToString().PadLeft(2,'0')):$($seconds.ToString().PadLeft(2,'0'))"

        $lines = @(
            "  DU KLARADE DET!",
            "  Alla $KeysFound nyckelbitar hittade!",
            "  Speltid: $timeFormatted",
            "  Strafftid: +$($PenaltySeconds)s",
            "  Totaltid: $timeFormatted"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Clear-Host
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  DU KLARADE DET!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  [KORREKT] NYCKELBIT $KeyNumber AV $TotalKeys HITTAD!".PadRight($width) -ForegroundColor Green
        Write-Host ""
        Write-Host "  Speltid:   $timeFormatted".PadRight($width) -ForegroundColor Gray
        Write-Host "  Strafftid: +$($PenaltySeconds)s".PadRight($width) -ForegroundColor Red
        Write-Host "  Totaltid:  $timeFormatted".PadRight($width) -ForegroundColor Cyan
        Write-Host ""
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
# Visas innan spelet börjar så spelaren förstår de nya reglerna
# -----------------------------------------------------------------------------
function Write-Instructions {
    try {
        $lines = @(
            "  SPELINSTRUKTIONER",
            "  Tidräkningen börjar när du går in i första rummet.",
            "  Varje fel svar ger +10 sekunders straff.",
            "  Du får försöka hur många gånger som helst.",
            "  Hitta alla 3 nyckelbitar för att vinna!",
            "  Målet är att klara spelet på kortast möjliga tid."
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  SPELINSTRUKTIONER".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  Tidräkningen börjar när du går in i första rummet.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Varje fel svar ger +10 sekunders straff.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Du får försöka hur många gånger som helst.".PadRight($width) -ForegroundColor Gray
        Write-Host "  Hitta alla 3 nyckelbitar för att vinna!".PadRight($width) -ForegroundColor Gray
        Write-Host "  Målet är att klara spelet på kortast möjliga tid.".PadRight($width) -ForegroundColor Gray
        Write-Host ""
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
        Write-Host "  Kunde inte visa instruktioner: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# RUM-INTRO
# Visas när spelaren går in i ett nytt rum
# Informerar spelaren om vilket rum de är i och vad de letar efter
# -----------------------------------------------------------------------------
function Write-RoomIntro {
    param(
        [Parameter(Mandatory)][string]$RoomName,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][int]$RoomNumber,
        [int]$TotalRooms = 3
    )

    try {
        $lines = @(
            "  [RUM $RoomNumber AV $TotalRooms]",
            "  $RoomName",
            "  $Description",
            "  Hitta nyckelbit $RoomNumber av $TotalRooms!"
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
        Write-Host "  Hitta nyckelbit $RoomNumber av $TotalRooms!".PadRight($width) -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""

        try {
            Read-Host "  Tryck Enter för att börja – tiden startar nu!"
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
# RÄTT SVAR – NYCKELBIT HITTAD
# Visas när spelaren svarar korrekt på en fråga
# Visar vilken nyckelbit spelaren hittade och aktuell tid
# -----------------------------------------------------------------------------
function Write-SuccessMessage {
    param(
        [Parameter(Mandatory)][string]$Message,      # Förklarande text om rätt svar
        [Parameter(Mandatory)][int]$KeyNumber,       # Vilken nyckelbit spelaren hittade
        [int]$TotalKeys = 3,                         # Totalt antal nyckelbitar
        [int]$ElapsedSeconds = 0                     # Aktuell tid när spelaren svarade rätt
    )

    try {
        # Formaterar tiden
        $minutes       = [math]::Floor($ElapsedSeconds / 60)
        $seconds       = $ElapsedSeconds % 60
        "$($minutes.ToString().PadLeft(2,'0')):$($seconds.ToString().PadLeft(2,'0'))"

        $lines = @(
            "  [KORREKT] NYCKELBIT $KeyNumber AV $TotalKeys HITTAD!",
            "  $Message",
            "  Tid: $timeFormatted"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  [KORREKT] NYCKELBIT $KeyNumber AV $TotalKeys HITTAD!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  $Message".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Tid: $timeFormatted".PadRight($width) -ForegroundColor Cyan
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
# FEL SVAR – TIDSSTRAFF
# Visas när spelaren svarar fel
# Spelaren får +10 sekunders straff men kan försöka igen
# -----------------------------------------------------------------------------
function Write-FailureMessage {
    param(
        [Parameter(Mandatory)][string]$Message,  # Förklarande text om fel svar
        [int]$PenaltySeconds = 10                # Strafftid i sekunder (standard 10)
    )

    try {
        $lines = @(
            "  [FEL] ÅTKOMST NEKAD!",
            "  $Message",
            "  +$($PenaltySeconds) sekunders straff!"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Write-Host ""
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  [FEL] ÅTKOMST NEKAD!".PadRight($width) -ForegroundColor Red
        Write-Host $line -ForegroundColor DarkRed
        Write-Host "  $Message".PadRight($width) -ForegroundColor Gray
        Write-Host ""
        Write-Host "  +$($PenaltySeconds) sekunders straff!".PadRight($width) -ForegroundColor Red
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

        # Läser spelarens svar – $input är reserverat i PS, använder $playerAnswer
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
    Write-Timer, Write-StatusBar, Write-Victory, `
    Write-Title, Write-Menu, Write-Instructions, Write-RoomIntro, `
    Write-SuccessMessage, Write-FailureMessage, Write-Question, `
    Wait-Game, Write-Countdown, Write-SaveConfirmation, Write-LoadConfirmation