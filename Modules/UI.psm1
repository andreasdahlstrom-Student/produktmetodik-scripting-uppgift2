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
        [Parameter(Mandatory)][int]$ElapsedSeconds,
        [int]$PenaltySeconds = 0,
        [int]$CompletedRooms = 0,
        [int]$TotalRooms = 3
    )

    try {
        Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkGreen
        # Visar tid
        Write-Timer -ElapsedSeconds $ElapsedSeconds -PenaltySeconds $PenaltySeconds
        # Visar lösensumman som ökar med tiden
        Write-RansomCounter -ElapsedSeconds $ElapsedSeconds -PenaltySeconds $PenaltySeconds
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
# -----------------------------------------------------------------------------
# VINST
# Visas när spelaren klarat alla rum
# Visar totaltid, strafftid, antal misstag och pengar spelaren slapp betala
# -----------------------------------------------------------------------------
function Write-Victory {
    param(
        [Parameter(Mandatory)][int]$ElapsedSeconds,
        [int]$PenaltySeconds = 0,
        [int]$KeysFound = 3,
        [int]$Mistakes = 0,          # Antal felaktiga svar under spelet
        [int]$BaseRansom = 10000     # Startbelopp för lösensumman
    )

    try {
        # Räknar speltid utan straff
        $playMinutes       = [math]::Floor($ElapsedSeconds / 60)
        $playSeconds       = $ElapsedSeconds % 60
        $playFormatted     = "$($playMinutes.ToString().PadLeft(2,'0')):$($playSeconds.ToString().PadLeft(2,'0'))"

        # Räknar totaltid inklusive straff
        $totalSeconds      = $ElapsedSeconds + $PenaltySeconds
        $totalMinutes      = [math]::Floor($totalSeconds / 60)
        $totalSecs         = $totalSeconds % 60
        $totalFormatted    = "$($totalMinutes.ToString().PadLeft(2,'0')):$($totalSecs.ToString().PadLeft(2,'0'))"

        # Räknar ut pengar spelaren slapp betala
        $ransom            = $BaseRansom + ($ElapsedSeconds * 100) + ($PenaltySeconds * 500)
        $ransomFormatted   = ("{0:N0}" -f $ransom) -replace ",", " "

        $lines = @(
            "  DU KLARADE DET!",
            "  Alla $KeysFound nyckelbitar hittade!",
            "  Speltid:          $playFormatted",
            "  Strafftid:        +$($PenaltySeconds)s ($Mistakes misstag)",
            "  Totaltid:         $totalFormatted",
            "  Du slapp betala:  $ransomFormatted SEK"
        )

        $width = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
        $line  = "=" * $width

        Clear-Host
        Write-Host ""
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host "  DU KLARADE DET!".PadRight($width) -ForegroundColor Green
        Write-Host $line -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  Alla $KeysFound nyckelbitar hittade!".PadRight($width) -ForegroundColor Green
        Write-Host ""
        Write-Host "  Speltid:          $playFormatted".PadRight($width) -ForegroundColor Gray
        Write-Host "  Strafftid:        +$($PenaltySeconds)s ($Mistakes misstag)".PadRight($width) -ForegroundColor Red
        Write-Host "  Totaltid:         $totalFormatted".PadRight($width) -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Du slapp betala:  $ransomFormatted SEK".PadRight($width) -ForegroundColor Green
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
        $timeFormatted = "$($minutes.ToString().PadLeft(2,'0')):$($seconds.ToString().PadLeft(2,'0'))"

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
# HACKER-MEDDELANDE
# Visar ett meddelande på ryska med svensk översättning under.
# Används i Write-HackerIntro för att bygga ransomware-storyn.
# -----------------------------------------------------------------------------
function Write-HackerMessage {
    param(
        [Parameter(Mandatory)][string]$Russian,   # Rysk text (hacker-röst)
        [Parameter(Mandatory)][string]$Swedish   # Svensk översättning för spelaren
    )

    try {
        Write-Host ""
        Write-Host "  >> $Russian" -ForegroundColor Red
        Write-Host "     ($Swedish)" -ForegroundColor DarkGray
    }
    catch {
        Write-Host "  Kunde inte visa hacker-meddelande: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# HACKER-INTRO
# Spelar upp hela ransomware-storyn när spelaren trycker "Starta nytt spel".
# Meddelanden visas på ryska med svensk översättning och paus emellan.
# Anropas från GameEngine efter menyvalet, innan Write-Instructions.
# -----------------------------------------------------------------------------
function Write-HackerIntro {
    param(
        [int]$PauseMs = 1500   # Paus mellan meddelanden i millisekunder (1500 = 1,5 sek)
    )

    try {
        Clear-Host
        Write-Host ""
        Write-Host "  =========================================" -ForegroundColor DarkRed
        Write-Host "  [!] OBEHÖRIG ÅTKOMST DETEKTERAD" -ForegroundColor Red
        Write-Host "  =========================================" -ForegroundColor DarkRed
        Write-Host ""
        Start-Sleep -Milliseconds 800

        # Varningsmeddelande – filer krypterade
        Write-HackerMessage `
            -Russian "!!! ВСЕ ТВОИ ФАЙЛЫ ЗАШИФРОВАНЫ !!!" `
            -Swedish "!!! ALLA DINA FILER ÄR KRYPTERADE !!!"

        Start-Sleep -Milliseconds $PauseMs

        # Hackaren presenterar sig
        Write-HackerMessage `
            -Russian "Привет. Твой компьютер теперь мой." `
            -Swedish "Hej. Din dator tillhör mig nu."

        Start-Sleep -Milliseconds $PauseMs

        # Villkor för att få tillbaka filerna
        Write-HackerMessage `
            -Russian "Реши мои комнаты, и ты получишь всё назад." `
            -Swedish "Lös mina rum, så får du tillbaka allt."

        Start-Sleep -Milliseconds $PauseMs

        # Tiden är igång
        Write-HackerMessage `
            -Russian "Но слушай внимательно. Часы уже идут." `
            -Swedish "Men lyssna noga. Klockan tickar redan."

        Start-Sleep -Milliseconds $PauseMs

        # Lösensumma ökar med tiden
        Write-HackerMessage `
            -Russian "Чем больше времени уйдёт на мои вопросы, тем выше будет твой выкуп." `
            -Swedish "Ju mer tid du tar på dig att klara mina frågor, desto högre blir din lösensumma."

        Start-Sleep -Milliseconds $PauseMs

        # Avslutande hot
        Write-HackerMessage `
            -Russian "Так что поторопись. Каждая секунда стоит тебе денег." `
            -Swedish "Så skynda dig. Varje sekund kostar dig pengar."

        Write-Host ""
        Write-Host "  =========================================" -ForegroundColor DarkRed
        Write-Host ""

        try {
            Read-Host "  Tryck Enter för att fortsätta"
        }
        catch {
            Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "  Kunde inte spela hacker-intro: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# LÖSENSUMMA
# Beräknar och visar lösenbeloppet baserat på tid och straff
# 100 SEK per sekund + 500 SEK per straffsekund + 10 000 SEK startbelopp
# -----------------------------------------------------------------------------
function Write-RansomCounter {
    param(
        [Parameter(Mandatory)][int]$ElapsedSeconds,
        [int]$PenaltySeconds = 0,
        [int]$BaseRansom = 10000
    )

    try {
        # Räknar ut lösensumman
        $ransom = $BaseRansom + ($ElapsedSeconds * 100) + ($PenaltySeconds * 500)

        # Formaterar beloppet med mellanslag som tusentalsavgränsare
        $ransomFormatted = ("{0:N0}" -f $ransom) -replace ",", " "

        # Färg ändras beroende på belopp
        if ($ransom -lt 20000) {
            $color = "Yellow"
        }
        elseif ($ransom -lt 50000) {
            $color = "DarkYellow"
        }
        else {
            $color = "Red"
        }
        

        Write-Host "| Lösensumma: $ransomFormatted SEK" -ForegroundColor $color
    }
    catch {
        Write-Host "| Lösensumma: [fel vid rendering] $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# ANIMERAD SPLASH SCREEN
# Visar ASCII-logotypen rad för rad med en fallande animation
# Körs en gång när programmet startar, innan huvudmenyn visas
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# ANIMERAD SPLASH SCREEN
# Fas 1: Matrix rain – gröna tecken kaskadar ner som i "The Matrix"
# Fas 2: Dekryptering – ASCII-konsten avslöjas gradvis från glitch-tecken
# Fas 3: Typewriter – titeln skrivs ut tecken för tecken
# Körs en gång när programmet startar, innan huvudmenyn visas
# -----------------------------------------------------------------------------
function Write-SplashScreen {
    param(
        [int]$DelayMs = 100    # Fördröjning mellan dekrypteringsframes (ms)
    )

    try {
        # Dölj markören under animationen för renare utseende
        [Console]::CursorVisible = $false

        # Glitch-tecken som simulerar krypterad data
        $glitchChars = @('█','▓','▒','░','╔','╗','╚','╝','║','═','▄','▀','■','◄','►','●')

        # Den riktiga ASCII-konsten som ska "dekrypteras"
        $asciiLines = @(
            "     ░█████╗░██╗░░░██╗██████╗░███████╗██████╗   ",
            "     ██╔══██╗╚██╗░██╔╝██╔══██╗██╔════╝██╔══██╗  ",
            "     ██║░░╚═╝░╚████╔╝░██████╦╝█████╗░░██████╔╝  ",
            "     ██║░░██╗░░╚██╔╝░░██╔══██╗██╔══╝░░██╔══██╗  ",
            "     ╚█████╔╝░░░██║░░░██████╦╝███████╗██║░░██║  ",
            "     ░╚════╝░░░░╚═╝░░░╚═════╝░╚══════╝╚═╝░░╚═╝  "
        )

        $separator = "=================================================="

        # =============================================================
        # FAS 1: MATRIX RAIN
        # Gröna tecken kaskadar ner som i filmen "The Matrix"
        # =============================================================
        Clear-Host
        $matrixChars = @('0','1','@','#','$','%','&','*','+','=','<','>','/','\','|','-')

        Write-Host ""
        for ($row = 0; $row -lt 18; $row++) {
            $line = ""
            for ($col = 0; $col -lt 50; $col++) {
                $line += $matrixChars[(Get-Random -Maximum $matrixChars.Length)]
            }

            # Variera färg mellan rader för djupeffekt
            if ($row % 3 -eq 0) { $rainColor = "Green" }
            else { $rainColor = "DarkGreen" }

            Write-Host "  $line" -ForegroundColor $rainColor
            Start-Sleep -Milliseconds 35
        }

        Start-Sleep -Milliseconds 500

        # =============================================================
        # FAS 2: DEKRYPTERINGSANIMATION
        # ASCII-konsten börjar som slumpmässiga glitch-tecken och
        # "dekrypteras" gradvis till den riktiga CYBER-logotypen.
        # Använder SetCursorPosition för att skriva över utan flimmer.
        # =============================================================
        Clear-Host

        # Rad 0: tom rad
        Write-Host ""
        # Rad 1: separator
        Write-Host $separator -ForegroundColor DarkGreen
        # Rad 2: progress-text
        Write-Host "  [DEKRYPTERAR...]" -ForegroundColor DarkGreen

        # Rad 3–8: fyll med glitch-tecken initialt
        foreach ($realLine in $asciiLines) {
            $scrambled = ""
            for ($c = 0; $c -lt $realLine.Length; $c++) {
                if ($realLine[$c] -eq ' ') { $scrambled += ' ' }
                else { $scrambled += $glitchChars[(Get-Random -Maximum $glitchChars.Length)] }
            }
            Write-Host $scrambled -ForegroundColor Green
        }

        # Rad 9: tom rad, Rad 10: separator
        Write-Host "                                                  "
        Write-Host $separator -ForegroundColor DarkGreen

        # ASCII-konsten börjar på rad 3 i konsolen
        $asciiStartRow = 3

        # Animera dekryptering – varje frame avslöjar fler riktiga tecken
        $totalFrames = 12
        for ($frame = 1; $frame -le $totalFrames; $frame++) {

            # Uppdatera progress-texten med animerade punkter
            $dots = "." * (($frame % 3) + 1)
            [Console]::SetCursorPosition(0, 2)
            Write-Host "  [DEKRYPTERAR$($dots)]     " -ForegroundColor DarkGreen

            # Skriv om varje ASCII-rad med fler riktiga tecken per frame
            for ($lineIdx = 0; $lineIdx -lt $asciiLines.Length; $lineIdx++) {
                [Console]::SetCursorPosition(0, $asciiStartRow + $lineIdx)

                $realLine = $asciiLines[$lineIdx]
                $output = ""
                for ($c = 0; $c -lt $realLine.Length; $c++) {
                    $char = $realLine[$c]
                    if ($char -eq ' ') {
                        $output += ' '
                    }
                    elseif ((Get-Random -Maximum $totalFrames) -lt $frame) {
                        $output += $char   # Visa riktigt tecken
                    }
                    else {
                        $output += $glitchChars[(Get-Random -Maximum $glitchChars.Length)]
                    }
                }
                Write-Host $output -ForegroundColor Green
            }

            Start-Sleep -Milliseconds $DelayMs
        }

        # Slutgiltig ren visning – 100% dekrypterat
        [Console]::SetCursorPosition(0, 2)
        Write-Host "                                                  "

        for ($lineIdx = 0; $lineIdx -lt $asciiLines.Length; $lineIdx++) {
            [Console]::SetCursorPosition(0, $asciiStartRow + $lineIdx)
            Write-Host $asciiLines[$lineIdx] -ForegroundColor Green
        }

        Start-Sleep -Milliseconds 300

        # =============================================================
        # FAS 3: TITEL OCH TAGLINE MED TYPEWRITER-EFFEKT
        # =============================================================
        [Console]::SetCursorPosition(0, $asciiStartRow + $asciiLines.Length)
        Write-Host "                                                  "

        Start-Sleep -Milliseconds 300
        Write-Host $separator -ForegroundColor DarkGreen

        # Typewriter-effekt: titeln skrivs ut tecken för tecken
        $title = "           CYBER SECURITY ESCAPE ROOM            "
        foreach ($char in $title.ToCharArray()) {
            Write-Host -NoNewline $char -ForegroundColor Green
            if ($char -ne ' ') {
                Start-Sleep -Milliseconds 30
            }
        }
        Write-Host ""

        Start-Sleep -Milliseconds 300
        Write-Host $separator -ForegroundColor DarkGreen

        Start-Sleep -Milliseconds 300
        Write-Host "     Samla nycklarna. Lås upp rummen. Fly.       " -ForegroundColor DarkGreen

        Start-Sleep -Milliseconds 200
        Write-Host $separator -ForegroundColor DarkGreen
        Write-Host ""

        Start-Sleep -Milliseconds 800

        # Visa markören igen
        [Console]::CursorVisible = $true
    }
    catch {
        # Säkerställ att markören alltid visas igen
        [Console]::CursorVisible = $true
        # Fallback till vanliga titelskärmen om animationen misslyckas
        Write-Title
    }
}

# -----------------------------------------------------------------------------
# SCOREBOARD
# Visar topplistan med bästa tider
# Tar emot en array med score-objekt från SaveSystem
# Varje objekt förväntas ha: Name, TotalSeconds, PenaltySeconds, Mistakes, Ransom
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# SCOREBOARD
# Visar topplistan med spelarnas resultat, inklusive räddad lösensumma
# -----------------------------------------------------------------------------
function Write-Scoreboard {
    param(
        [Parameter(Mandatory=$false)]
        [array]$Scores
    )

    Clear-Host
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor DarkGreen
    Write-Host "                           TOPPLISTA - BÄSTA TIDER                              " -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor DarkGreen
    Write-Host ""

    if ($null -eq $Scores -or $Scores.Count -eq 0) {
        Write-Host "  Inga scores sparade än." -ForegroundColor Gray
        Write-Host "  Klara spelet för att komma upp på listan!" -ForegroundColor DarkGreen
    }
    else {
        # Uppdaterade rubriker med den nya kolumnen för "Räddade pengar"
        Write-Host "  #   Namn             Totaltid    Straff     Misstag    Räddade pengar" -ForegroundColor Green
        Write-Host "  ------------------------------------------------------------------------" -ForegroundColor DarkGreen

        $i = 1
        foreach ($score in $Scores) {
            # Visar max topp 10
            if ($i -gt 10) { break }

            # Formaterar kolumnerna så att allt hamnar rakt under varandra
            $rank = $i.ToString().PadRight(4)
            $name = $score.Name.ToString().PadRight(17)
            $time = $score.TotalTime.ToString().PadRight(12)
            $pen  = "+$($score.Penalty)s".PadRight(11)
            $mist = "$($score.Mistakes) fel".PadRight(11)
            
            # --- VIKTIGT ---
            # Här hämtar vi pengarna. Dubbelkolla med gänget som gör GameEngine/SaveSystem 
            # vad just denna variabel heter i deras .json fil. Jag sätter den till "SavedMoney" tills vidare.
            $moneyValue = if ($null -ne $score.SavedMoney) { $score.SavedMoney } else { 0 }
            $money = "$moneyValue SEK"

            # Färglägger topp 3 som Guld, Silver, Brons
            $color = "Gray"
            if ($i -eq 1) { $color = "Yellow" }
            elseif ($i -eq 2) { $color = "White" }
            elseif ($i -eq 3) { $color = "DarkYellow" }

            # Skriver ut raden
            Write-Host "  $rank" -NoNewline -ForegroundColor Green
            Write-Host "$name$time$pen$mist$money" -ForegroundColor $color
            
            $i++
        }
    }

    Write-Host ""
    Write-Host "  ------------------------------------------------------------------------" -ForegroundColor DarkGreen
    Write-Host ""
    try {
        Read-Host "  Tryck Enter för att gå tillbaka"
    }
    catch {
        Write-Host "  Kunde inte läsa input: $_" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# SPARA-PROMPT
# Frågar spelaren om de vill spara sitt spel under spelets gång
# Returnerar $true om spelaren vill spara, $false om inte
# Anropas av GameEngine som sedan skickar till SaveSystem om $true returneras
# -----------------------------------------------------------------------------
function Write-SavePrompt {
    try {
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host "  SPARA SPEL" -ForegroundColor Green
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "  Vill du spara ditt spel och fortsätta senare?" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [1] Ja, spara spelet" -ForegroundColor Green
        Write-Host "  [2] Nej, fortsätt spela" -ForegroundColor Green
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor DarkGreen
        Write-Host ""

        try {
            $playerAnswer = Read-Host "  Ditt val"
            $choice       = [int]$playerAnswer

            if ($choice -eq 1) {
                return $true   # Spelaren vill spara
            }
            else {
                return $false  # Spelaren vill inte spara
            }
        }
        catch {
            # Vid ogiltigt svar fortsätter spelet utan att spara
            return $false
        }
    }
    catch {
        Write-Host "  Kunde inte visa spara-prompt: $_" -ForegroundColor Red
        return $false
    }
}

# -----------------------------------------------------------------------------
# EXPORTERA FUNKTIONER
# Gör alla funktioner tillgängliga när modulen importeras med Import-Module
# -----------------------------------------------------------------------------
Export-ModuleMember -Function `
    Write-Timer, Write-RansomCounter, Write-StatusBar, Write-Victory, `
    Write-SplashScreen, Write-Title, Write-Menu, Write-Instructions, `
    Write-RoomIntro, Write-SuccessMessage, Write-FailureMessage, `
    Write-Question, Wait-Game, Write-Countdown, Write-Scoreboard, `
    Write-SavePrompt, Write-SaveConfirmation, Write-LoadConfirmation, `
    Write-HackerMessage, Write-HackerIntro