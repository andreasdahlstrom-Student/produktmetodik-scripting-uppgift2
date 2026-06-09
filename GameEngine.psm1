# Den här modulen innehåller spelets säkerhetsutmaningar.

# Skapar ett standardiserat resultatobjekt för alla utmaningar oavsett vilken utmaning som kördes.
function New-ChallengeResult {
    param(
        # Anger om spelaren klarade utmaningen eller inte.
        [Parameter(Mandatory)]
        [bool]$Success,

        # Antal poäng spelaren får för sitt val.
        [Parameter(Mandatory)]
        [int]$Points,

        # Text som förklarar varför svaret var rätt eller fel.
        [Parameter(Mandatory)]
        [string]$Feedback
    )

    # Returnerar ett eget objekt med resultatet från utmaningen.
    # Detta gör det lättare för spelmotorn att läsa av resultatet senare.
    return [PSCustomObject]@{
        Success  = $Success
        Points   = $Points
        Feedback = $Feedback
    }
}

# Läser in spelarens val från terminalen.
# Funktionen används av alla utmaningar för att slippa upprepa samma kod.
function Read-ChallengeChoice {
    param(
        # Texten som visas när spelaren ska skriva sitt val.
        [Parameter(Mandatory)]
        [string]$Prompt
    )

    try {
        # Read-Host väntar på att spelaren skriver något i terminalen.
        $choice = Read-Host $Prompt

        # Kontrollerar att spelaren bara har valt ett av de tillåtna alternativen.
        # Om spelaren skriver något annat än 1, 2 eller 3 returneras $null.
        if ($choice -notin @("1", "2", "3")) {
            Write-Host "Terminalen blinkar rött: välj 1, 2 eller 3." -ForegroundColor Yellow
            return $null
        }

        # Om valet är giltigt omvandlas texten till ett heltal.
        # Det gör det enklare att jämföra valet senare i koden.
        return [int]$choice
    }
    catch {
        # Om något oväntat går fel när input läses in hamnar vi här.
        # Spelet kraschar inte, utan spelaren får ett felmeddelande.
        Write-Host "Terminalen kunde inte läsa ditt svar. Försök igen." -ForegroundColor Red
        return $null
    }
}

# Utmaning 1: Phishing.
# Spelaren får ett misstänkt mejl och ska välja det säkraste sättet att agera.
function Invoke-PhishingChallenge {
    Write-Host ""
    Write-Host "Terminalutmaning: Inkorgen" -ForegroundColor Cyan
    Write-Host "Ett nytt mejl fyller skärmen: 'DITT KONTO STÄNGS OM 10 MINUTER'."
    Write-Host "Avsändaren liknar skolans adress, men några bokstäver är fel. En stor knapp blinkar."
    Write-Host ""
    Write-Host "1. Klicka på knappen direkt för att rädda kontot."
    Write-Host "2. Kontrollera avsändaren och gå själv till skolans riktiga inloggningssida."
    Write-Host "3. Svara på mejlet med ditt användarnamn och lösenord."

    # Hämtar spelarens val med den gemensamma input-funktionen.
    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"

    # Om spelaren skrev ett ogiltigt svar returneras ett misslyckat resultat.
    if ($null -eq $choice) {
        return New-ChallengeResult -Success $false -Points 0 -Feedback "Terminalen accepterar bara alternativen 1, 2 eller 3."
    }

    # Alternativ 2 är rätt eftersom användaren inte klickar på en misstänkt länk.
    if ($choice -eq 2) {
        $feedback = "Rätt. Du litade inte på länken, utan valde en kontrollerad väg till tjänsten."
        Write-Host $feedback -ForegroundColor Green
        return New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    # Alla andra giltiga val är osäkra och ger därför inga poäng.
    $feedback = "Farligt val. Phishing använder ofta stress och falska länkar för att stjäla inloggningar."
    Write-Host $feedback -ForegroundColor Yellow
    return New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
}

# Utmaning 2: Lösenord.
# Spelaren ska välja det starkaste lösenordet av tre alternativ.
function Invoke-PasswordChallenge {
    Write-Host ""
    Write-Host "Terminalutmaning: Valvlåset" -ForegroundColor Cyan
    Write-Host "Valvet visar tre möjliga lösenord. Ett svagt val startar larmet."
    Write-Host "Du behöver välja det lösenord som bäst står emot gissning och knäckning."
    Write-Host ""
    Write-Host "1. Password123"
    Write-Host "2. sommar2026"
    Write-Host "3. Vinter!Kamera-73-Skog"

    $choice = Read-ChallengeChoice -Prompt "Välj lösenord"

    if ($null -eq $choice) {
        return New-ChallengeResult -Success $false -Points 0 -Feedback "Valvet kräver ett val mellan 1 och 3."
    }

    # Alternativ 3 är bäst eftersom det är längre och mer varierat.
    if ($choice -eq 3) {
        $feedback = "Rätt. Längd, variation och unikhet gör lösenfrasen mycket starkare."
        Write-Host $feedback -ForegroundColor Green
        return New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    # Svaga lösenord är ofta korta, vanliga eller baserade på enkla mönster.
    $feedback = "För svagt. Vanliga ord, namn, årtal och enkla mönster är lätta att gissa."
    Write-Host $feedback -ForegroundColor Yellow
    return New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
}

# Utmaning 3: MFA.
# Spelaren får en oväntad MFA-notis och måste förstå att den inte ska godkännas.
function Invoke-MfaChallenge {
    Write-Host ""
    Write-Host "Terminalutmaning: Andra låset" -ForegroundColor Cyan
    Write-Host "Dörren skickar en MFA-notis. Problemet är att du inte försöker logga in."
    Write-Host "Om du godkänner fel notis kan någon annan komma in."
    Write-Host ""
    Write-Host "1. Godkänn notisen för att bli av med den."
    Write-Host "2. Neka notisen och rapportera eller byt lösenord enligt rutinen."
    Write-Host "3. Stäng av MFA eftersom det stör."

    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"

    if ($null -eq $choice) {
        return New-ChallengeResult -Success $false -Points 0 -Feedback "MFA-låset kräver ett giltigt val."
    }

    # Rätt svar är att neka notisen och agera enligt säkerhetsrutinen.
    if ($choice -eq 2) {
        $feedback = "Rätt. En oväntad MFA-notis kan betyda att någon redan har lösenordet."
        Write-Host $feedback -ForegroundColor Green
        return New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    $feedback = "Fel val. Godkänn aldrig en MFA-notis som du inte själv har startat."
    Write-Host $feedback -ForegroundColor Yellow
    return New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
}

# Utmaning 4: Okänd USB-enhet.
function Invoke-UsbChallenge {
    Write-Host ""
    Write-Host "Terminalutmaning: Okänd enhet" -ForegroundColor Cyan
    Write-Host "USB-minnet ligger precis bredvid labbdatorn. Skärmen visar: 'Anslut enhet för analys'."
    Write-Host "Det kan vara oskyldigt, men det kan också vara en fälla."
    Write-Host ""
    Write-Host "1. Stoppa in det i datorn för att hitta ägaren."
    Write-Host "2. Lämna det till lärare eller IT-ansvarig utan att koppla in det."
    Write-Host "3. Kopiera filerna snabbt och radera sedan USB-minnet."

    $choice = Read-ChallengeChoice -Prompt "Välj säker åtgärd"

    if ($null -eq $choice) {
        return New-ChallengeResult -Success $false -Points 0 -Feedback "USB-labbet accepterar bara val 1, 2 eller 3."
    }

    # Rätt val är att inte ansluta USB-minnet till datorn.
    if ($choice -eq 2) {
        $feedback = "Rätt. Okända USB-enheter ska inte kopplas in i en vanlig dator."
        Write-Host $feedback -ForegroundColor Green
        return New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    $feedback = "Osäkert. En okänd USB-enhet kan köra skadlig kod eller lura användaren."
    Write-Host $feedback -ForegroundColor Yellow
    return New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
}

# Utmaning 5: Incidenthantering.
# Spelaren får ett scenario där ett konto kan vara kapat och ska välja första åtgärd.
function Invoke-IncidentChallenge {
    Write-Host ""
    Write-Host "Terminalutmaning: Larmcentralen" -ForegroundColor Cyan
    Write-Host "Skärmarna visar: 'Möjlig kapning av konto'. Filer saknas och konstiga meddelanden skickas."
    Write-Host "Du behöver välja första åtgärden innan skadan sprider sig."
    Write-Host ""
    Write-Host "1. Rapportera snabbt till lärare eller IT och följ skolans rutin."
    Write-Host "2. Vänta några dagar för att se om problemet försvinner."
    Write-Host "3. Lägg ut användarnamnet och problemet offentligt i en chatt."

    $choice = Read-ChallengeChoice -Prompt "Välj första åtgärd"

    if ($null -eq $choice) {
        return New-ChallengeResult -Success $false -Points 0 -Feedback "Incidentcentralen behöver ett giltigt val."
    }

    # Rätt svar är att rapportera incidenten snabbt till ansvarig person.
    if ($choice -eq 1) {
        $feedback = "Rätt. Snabb rapportering hjälper ansvariga att begränsa skadan och säkra bevis."
        Write-Host $feedback -ForegroundColor Green
        return New-ChallengeResult -Success $true -Points 10 -Feedback $feedback
    }

    $feedback = "Inte bra. Incidenter ska rapporteras snabbt och inte delas offentligt med känslig information."
    Write-Host $feedback -ForegroundColor Yellow
    return New-ChallengeResult -Success $false -Points 0 -Feedback $feedback
}

# Exporterar bara de funktioner som andra filer i projektet behöver kunna anropa.
# Hjälpfunktionerna New-ChallengeResult och Read-ChallengeChoice används internt i modulen
# och behöver därför inte exporteras.
Export-ModuleMember -Function Invoke-PhishingChallenge, Invoke-PasswordChallenge, Invoke-MfaChallenge, Invoke-UsbChallenge, Invoke-IncidentChallenge