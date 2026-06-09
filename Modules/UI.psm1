# UI.psm1
# Denna modul hanterar all visuell output i spelet.
# Den importeras av andra scripts via Import-Module.

# ─────────────────────────────────────────
# HP-BAR
# Visar spelarens hälsa som en visuell bar
# ─────────────────────────────────────────
function Show-HPBar {
    param(
        [Parameter(Mandatory)]
        [int]$CurrentHP,  # Spelarens nuvarande HP
        [int]$MaxHP = 100 # Max HP, standard är 100
    )

    # Räknar ut hur många block som ska fyllas i baren
    $barLength = 20
    $filled = [math]::Round(($CurrentHP / $MaxHP) * $barLength)
    $empty = $barLength - $filled

    # Bygger själva baren med Unicode-tecken
    $bar = ("█" * $filled) + ("░" * $empty)

    # Väljer färg beroende på hur mycket HP som återstår
    if ($CurrentHP -gt 60) {
        $color = "Green"   # Bra HP
    } elseif ($CurrentHP -gt 30) {
        $color = "Yellow"  # Varning
    } else {
        $color = "Red"     # Kritiskt låg HP
    }

    Write-Host "| HP: [$bar] $CurrentHP/$MaxHP" -ForegroundColor $color
}

# ─────────────────────────────────────────
# STATUSBAR
# Visar HP, poäng och rum-progress samlat
# ─────────────────────────────────────────
function Show-StatusBar {
    param(
        [Parameter(Mandatory)][int]$CurrentHP,
        [int]$MaxHP = 100,
        [Parameter(Mandatory)][int]$Score,
        [int]$CompletedRooms = 0, # Antal avklarade rum
        [int]$TotalRooms = 3      # Totalt antal rum i spelet
    )

    Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkGreen
    # Anropar Show-HPBar för att rita ut HP-baren
    Show-HPBar -CurrentHP $CurrentHP -MaxHP $MaxHP
    Write-Host "| Poang: $Score" -ForegroundColor Green
    Write-Host "| Rum avklarade: $CompletedRooms av $TotalRooms" -ForegroundColor Green
    Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host ""
}

# ─────────────────────────────────────────
# GAME OVER
# Visas när spelaren förlorat all HP
# ─────────────────────────────────────────
function Show-GameOver {
    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "                  GAME OVER                      " -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "  Du tog for mycket skada och systemet stangde." -ForegroundColor Gray
    Write-Host "  Starta om och forsok igen..." -ForegroundColor Gray
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host ""
}

# ─────────────────────────────────────────
# VINST
# Visas när spelaren klarat alla rum
# ─────────────────────────────────────────
function Show-Victory {
    param(
        [Parameter(Mandatory)][int]$FinalScore # Spelarens slutpoäng
    )
    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "              DU KLARADE DET!                    " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "  Alla sakerhetsrum ar uppllasta." -ForegroundColor Gray
    Write-Host "  Slutpoang: $FinalScore" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
}

# ─────────────────────────────────────────
# TITELSKÄRM
# Första skärmen spelaren ser när spelet startar
# ─────────────────────────────────────────
function Show-Title {
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
    Write-Host "     Samla nycklarna. Las upp rummen. Fly.       " -ForegroundColor DarkGreen
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
}

# ─────────────────────────────────────────
# HUVUDMENY
# Tar emot en lista med menyalternativ och skriver ut dem numrerade
# ─────────────────────────────────────────
function Show-Menu {
    param(
        [Parameter(Mandatory)]
        [string[]]$Options # En array med menyalternativ
    )

    Write-Host "+---------------- HUVUDMENY ----------------+" -ForegroundColor DarkGreen

    # Loopar igenom varje alternativ och skriver ut med nummer
    for ($i = 0; $i -lt $Options.Length; $i++) {
        # Sparar numret i $num för att undvika syntaxproblem i strängen
        $num = $i + 1
        Write-Host "|  [$num] $($Options[$i])" -ForegroundColor Green
    }

    Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host ""
}

# ─────────────────────────────────────────
# RUM-INTRO
# Visas när spelaren går in i ett nytt rum
# ─────────────────────────────────────────
function Show-RoomIntro {
    param(
        [Parameter(Mandatory)][string]$RoomName,    # Rummets namn
        [Parameter(Mandatory)][string]$Description, # Beskrivning av rummet
        [Parameter(Mandatory)][int]$RoomNumber,     # Vilket rum spelaren är i
        [int]$TotalRooms = 3,                       # Totalt antal rum
        [int]$Points = 100                          # Poäng att vinna i rummet
    )

    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "  [RUM $RoomNumber AV $TotalRooms]" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "  $RoomName" -ForegroundColor Green
    Write-Host ""
    Write-Host "  $Description" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Sakerhetsnycklar att vinna: $Points p" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
    # Pausar spelet tills spelaren trycker Enter
    Read-Host "  Tryck Enter for att borja"
}

# ─────────────────────────────────────────
# RÄTT SVAR
# Visas när spelaren svarar rätt på en fråga
# ─────────────────────────────────────────
function Show-SuccessMessage {
    param(
        [Parameter(Mandatory)][string]$Message, # Meddelande att visa spelaren
        [int]$PointsEarned = 100               # Poäng spelaren fick
    )

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "  [KORREKT] SAKERHETSNYCKEL UPPLAST!             " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "  $Message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  + $PointsEarned poang tillagda!               " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
    # Pausar spelet tills spelaren trycker Enter
    Read-Host "  Tryck Enter for att fortsatta"
}

# ─────────────────────────────────────────
# FEL SVAR
# Visas när spelaren svarar fel på en fråga
# ─────────────────────────────────────────
function Show-FailureMessage {
    param(
        [Parameter(Mandatory)][string]$Message, # Meddelande att visa spelaren
        [int]$HPLost = 25                       # HP spelaren förlorar
    )

    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "  [FEL] ATKOMST NEKAD!                          " -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "  $Message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  - $HPLost HP forlorat!                        " -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host ""
    # Pausar spelet tills spelaren trycker Enter
    Read-Host "  Tryck Enter for att forsoka igen"
}


# ─────────────────────────────────────────
# EXPORTERAR ALLA FUNKTIONER
# Gör funktionerna tillgängliga när modulen importeras
# ─────────────────────────────────────────
Export-ModuleMember -Function Show-HPBar, Show-StatusBar, `
    Show-GameOver, Show-Victory, Show-Title, Show-Menu, `
    Show-RoomIntro, Show-SuccessMessage, Show-FailureMessage