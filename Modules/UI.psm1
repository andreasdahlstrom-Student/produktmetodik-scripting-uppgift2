function Show-HPBar {
    param(
        [Parameter(Mandatory)]
        [int]$CurrentHP,
        [int]$MaxHP = 100
    )

    $barLength = 20
    $filled = [math]::Round(($CurrentHP / $MaxHP) * $barLength)
    $empty = $barLength - $filled

    $bar = ("█" * $filled) + ("░" * $empty)

    # Färgen ändras beroende på hur mycket HP som återstår
    if ($CurrentHP -gt 60) {
        $color = "Green"
    } elseif ($CurrentHP -gt 30) {
        $color = "Yellow"
    } else {
        $color = "Red"
    }

    Write-Host "| HP: [$bar] $CurrentHP/$MaxHP" -ForegroundColor $color
}

function Show-StatusBar {
    param(
        [Parameter(Mandatory)]
        [int]$CurrentHP,
        [int]$MaxHP = 100,
        [Parameter(Mandatory)]
        [int]$Score,
        [int]$CompletedRooms = 0,
        [int]$TotalRooms = 3
    )

    Write-Host "+---------------- STATUS -------------------+" -ForegroundColor DarkCyan
    Show-HPBar -CurrentHP $CurrentHP -MaxHP $MaxHP
    Write-Host "| Poäng: $Score" -ForegroundColor Magenta
    Write-Host "| Rum avklarade: $CompletedRooms av $TotalRooms" -ForegroundColor Magenta
    Write-Host "+-------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-GameOver {
    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "                  GAME OVER                      " -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host "  Du tog för mycket skada och systemet stängde." -ForegroundColor Gray
    Write-Host "  Starta om och försök igen..." -ForegroundColor Gray
    Write-Host "==================================================" -ForegroundColor DarkRed
    Write-Host ""
}

function Show-Victory {
    param(
        [Parameter(Mandatory)]
        [int]$FinalScore
    )
    Clear-Host
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "              DU KLARADE DET!                    " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host "  Alla säkerhetsrum är upplåsta." -ForegroundColor Gray
    Write-Host "  Slutpoäng: $FinalScore" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
}

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
    Write-Host "     Samla nycklarna. Lås upp rummen. Fly.       " -ForegroundColor DarkGreen
    Write-Host "==================================================" -ForegroundColor DarkGreen
    Write-Host ""
}

function Show-Menu {
    param(
        [Parameter(Mandatory)]
        [string[]]$Options
    )
    Write-Host "+---------------- HUVUDMENY ----------------+" -ForegroundColor DarkGreen
    for ($i = 0; $i -lt $Options.Length; $i++) {
        $num = $i + 1
        Write-Host "|  [$num] $($Options[$i])" -ForegroundColor Green
    }
    Write-Host "+-------------------------------------------+" -ForegroundColor DarkGreen
    Write-Host ""
}

function Show-RoomIntro {
    param(
        [Parameter(Mandatory)][string]$RoomName,
        [Parameter(Mandatory)][string]$Description,
        [Parameter(Mandatory)][int]$RoomNumber,
        [int]$TotalRooms = 3,
        [int]$Points = 100
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
    Read-Host "  Tryck Enter for att borja"
}

Export-ModuleMember -Function Show-HPBar, Show-StatusBar, `
    Show-GameOver, Show-Victory, Show-Title, Show-Menu, Show-RoomIntro