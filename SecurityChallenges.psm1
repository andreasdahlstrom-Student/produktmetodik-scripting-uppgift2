# SecurityChallenges.psm1
# Här finns spelets säkerhetsutmaningar.
# Varje funktion returnerar ett objekt med Success, Points och Feedback.

# ==========================================
# Hjälpfunktioner
# ==========================================

# Skapar ett standardiserat resultatobjekt
function New-ChallengeResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [int]$Points,

        [Parameter(Mandatory)]
        [string]$Feedback
    )

    return [PSCustomObject]@{
        Success  = $Success
        Points   = $Points
        Feedback = $Feedback
    }
}

# Läser in ett giltigt val från användaren
function Read-ChallengeChoice {
    param([string]$Prompt)

    while ($true) {
        $choice = Read-Host $Prompt

        if ($choice -match '^[1-3]$') {
            return [int]$choice
        }

        Write-Host "Ogiltigt val. Välj 1, 2 eller 3." -ForegroundColor DarkYellow
    }
}

# Skriver ut en visuell avdelare i terminalen
function Write-Separator {
    Write-Host ""
    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}
function Invoke-PhishingChallenge {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host "  TERMINALUTMANING: INKORGEN   " -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host ""
# Visa scenario för användaren
    Write-Host "SCENARIO:" -ForegroundColor Yellow
    Write-Separator

    Write-Host "Du får ett mejl som säger: 'Ditt konto kommer att stängas inom 10 minuter!'" -ForegroundColor Gray
    Write-Host "Avsändaren liknar skolans adress, men några bokstäver är fel. En stor knapp blinkar" -ForegroundColor Gray
    Write-Host ""

    Write-Separator

    Write-Host "ALTERNATIV:" -ForegroundColor Yellow
    Write-Host "1. Klicka på knappen direkt för att rädda kontot."
    Write-Host "2. Kontrollera avsändaren och gå själv till skolans riktiga inloggningssida"
    Write-Host "3. Svara på mejlet med ditt användarnamn och lösenord."
    Write-Host ""
# Läs in användarens val
    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"
# Utvärdera svaret
$result = switch ($choice) {

        1 {
            $feedback = "FEL: Klicka aldrig på misstänkta länkar."
            Write-Host $feedback -ForegroundColor Red
            New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
        }

        2 {
            $feedback = "RÄTT: Du verifierade avsändaren först."
            Write-Host $feedback -ForegroundColor Green
            New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
        }

        3 {
            $feedback = "FEL: Att dela lösenord är alltid osäkert."
            Write-Host $feedback -ForegroundColor Red
            New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
        }
    }

    Write-Host ""
    Read-Host "Tryck Enter för att fortsätta"

return $result
}
function Invoke-PasswordChallenge {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host "  TERMINALUTMANING: VALVLÅSET  " -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "SCENARIO:" -ForegroundColor Yellow
    Write-Separator
   
    Write-Host "Valvet visar tre möjliga lösenord. Ett svagt val startar larmet." -ForegroundColor Gray
    Write-Host "Du behöver välja det lösenord som bäst står emot gissning och knäckning." -ForegroundColor Gray
    Write-Host ""

    Write-Separator
    
    Write-Host "ALTERNATIV:" -ForegroundColor Yellow
    Write-Host "1. password123"
    Write-Host "2. sommar2026"
    Write-Host "3. Vinter!Kamera-73-Skog"
    Write-Host ""

    $choice = Read-ChallengeChoice -Prompt "Välj lösenord"

$result = switch ($choice) {

    1 {
        $feedback = "FEL: Detta lösenord är för svagt och lätt att gissa."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }

    2 {
        $feedback = "FEL: Även om det ser bättre ut är det fortfarande förutsägbart."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }

    3 {
        $feedback = "RÄTT: Lång, unik och blandad - mycket starkare lösenord."
        Write-Host $feedback -ForegroundColor Green
        New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }
}

Write-Host ""
Read-Host "Tryck Enter för att fortsätta"

return $result
}
function Invoke-MFAChallenge {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host " TERMINALUTMANING: ANDRA LÅSET " -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "SCENARIO:" -ForegroundColor Yellow
    Write-Separator

    Write-Host "Dörren skickar en MFA-notis. Problemet är att du inte försöker logga in." -ForegroundColor Gray
    Write-Host "Om du godkänner fel notis kan någon annan komma in." -ForegroundColor Gray
    Write-Host ""

    Write-Separator

    Write-Host "ALTERNATIV:" -ForegroundColor Yellow
    Write-Host "1. Godkänn notisen för att bli av med den."
    Write-Host "2. Neka notisen och rapportera eller byt lösenord enligt rutinen."
    Write-Host "3. Stäng av MFA eftersom det stör."
    Write-Host ""

    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"

$result = switch ($choice) {

    1 {
        $feedback = "FEL: Du godkände en inloggning du inte startade själv."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }

    2 {
        $feedback = "RÄTT: Du blockerar och hanterar misstänkt inloggning korrekt."
        Write-Host $feedback -ForegroundColor Green
        New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    3 {
        $feedback = "FEL: Att stänga av MFA gör kontot osäkert."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }
}

Write-Host ""
Read-Host "Tryck Enter för att fortsätta"

return $result
}

function Invoke-USBChallenge {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host " TERMINALUTMANING: OKÄND ENHET " -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "SCENARIO:" -ForegroundColor Yellow
    Write-Separator
    
    Write-Host "USB-minnet ligger precis bredvid labbdatorn. Skärmen visar: 'Anslut enhet för analys'." -ForegroundColor Gray
    Write-Host "Det kan vara oskyldigt, men det kan också vara en fälla." -ForegroundColor Gray
    Write-Host ""

    Write-Separator

    Write-Host "ALTERNATIV:" -ForegroundColor Yellow
    Write-Host "1. Koppla in USB och öppna filerna"
    Write-Host "2. Lämna det till lärare eller IT-ansvarig utan att koppla in det."
    Write-Host "3. Kopiera filerna snabbt och radera sedan USB-minnet."
    Write-Host ""

    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"

$result = switch ($choice) {
    1 {
        $feedback = "FEL: Okända USB-enheter kan innehålla skadlig kod."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }

    2 {
        $feedback = "RÄTT: Du lämnar enheten till ansvarig istället för att riskera datorn."
        Write-Host $feedback -ForegroundColor Green
        New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    3 {
        $feedback = "FEL: Att öppna okända filer kan vara farligt."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }
}

Write-Host ""
Read-Host "Tryck Enter för att fortsätta"

return $result
}

function Invoke-IncidentChallenge {

    Write-Host ""
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host "TERMINALUTMANING: LARMCENTRALEN" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "SCENARIO:" -ForegroundColor Yellow
    Write-Separator
    
    Write-Host "Skärmarna visar: 'Möjlig kapning av konto'. Filer saknas och konstiga meddelanden skickas." -ForegroundColor Gray
    Write-Host "Du behöver välja första åtgärden innan skadan sprider sig." -ForegroundColor Gray
    Write-Host ""

    Write-Separator
    
    Write-Host "ALTERNATIV:" -ForegroundColor Yellow
    Write-Host "1. Rapportera snabbt till lärare eller IT och följ skolans rutin."
    Write-Host "2. Vänta några dagar för att se om problemet försvinner."
    Write-Host "3. Lägg ut användarnamnet och problemet offentligt i en chatt."
    Write-Host ""

    $choice = Read-ChallengeChoice -Prompt "Välj första åtgärd"

$result = switch ($choice) {

    1 {
        $feedback = "RÄTT: Snabb rapportering minskar skadan och hjälper IT att agera."
        Write-Host $feedback -ForegroundColor Green
        New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    2 {
        $feedback = "FEL: Att vänta kan göra att problemet blir värre."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }

    3 {
        $feedback = "FEL: Att sprida information kan skapa säkerhetsrisker."
        Write-Host $feedback -ForegroundColor Red
        New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
    }
}

Write-Host ""
Read-Host "Tryck Enter för att fortsätta"

return $result
}

Export-ModuleMember -Function Invoke-PhishingChallenge, Invoke-PasswordChallenge, Invoke-MFAChallenge, Invoke-USBChallenge, Invoke-IncidentChallenge, Write-Separator