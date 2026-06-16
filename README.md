<div align="center">

# CLI Security Escape Room: Ransomware Edition
*Ett interaktivt "Escape Room"-spel direkt i terminalen för att utbilda medarbetare inom IT-säkerhet.*

</div>

---

## Innehållsförteckning
1. [Story och Syfte](#story)
2. [Spelmekanik och Funktioner](#mekanik)
3. [Scrum-teamet](#team)
4. [Teknisk Arkitektur](#arkitektur)
5. [Förändringsledning ADKAR](#adkar)
6. [ITIL Continual Improvement](#itil)
7. [Installation och Spela](#installation)

---

<a id="story"></a>
## Story och Syfte

> **VARNING: Företaget har blivit hackat!** 
> *En ransomware-attack har krypterat vår mest känsliga data. För att låsa upp filerna och undvika att betala en enorm lösensumma måste du överlista hackaren. Genom att lösa 5 säkerhetsrelaterade utmaningar direkt i hackarens terminal kan vi återta kontrollen.*

**Syftet** med projektet är att ersätta passiv och "tråkig" IT-säkerhetsutbildning med en spännande, verklighetsförankrad utmaning. Genom spelet tränar medarbetarna på riktiga säkerhetsrisker på ett sätt som faktiskt skapar engagemang.

---

<a id="mekanik"></a>
## Spelmekanik och Funktioner

Spelet är designat för att simulera stressen vid ett riktigt säkerhetshot:
* **5 Säkerhetsutmaningar:** Interaktiva frågor som testar användarens faktiska kunskap och förmåga.
* **Tidtagning:** Hela spelet går på tid. Klockan tickar från det att du startar!
* **Tidsstraff:** Varje felaktigt svar straffas omedelbart med **+10 sekunder** tillägg på din totala tid.
* **Scoreboard:** En topplista i slutet av spelet visar de bästa tiderna, vilket bygger tävlingsanda mellan avdelningarna.

---

<a id="team"></a>
## Scrum-teamet

Vi arbetar agilt enligt Scrum-ramverket med korta sprintar, och hanterar vårt arbete i GitHub Projects (To Do ➔ In Progress ➔ Done).

| Roll | Namn |
| :--- | :--- |
| **Product Owner** | `Andreas Dahlström` |
| **Scrum Master** | `Victor Khatibi` |
| **Utvecklare** | `Flamur Mehmeti`, `Richard Edward Alexander Hope`, `Lucas Wenehult` |

---

<a id="arkitektur"></a>
## Teknisk Arkitektur

Spelet är utvecklat för Windows-miljöer och använder inga tunga tredjepartsprogram.

* **PowerShell & VS Code:** Kärnan är skriven i PowerShell via Visual Studio Code, vilket gör det enkelt att distribuera på företagets datorer.
* **Avancerat Kontrollflöde:** Spelets logik anpassar sig i realtid efter inmatningar, räknar ut tidsstraff och hanterar poäng.
* **JSON State Management:** Framsteg, tider och scoreboard sparas i en `.json`-fil.
* **Modulär kod:** Enkelt att byta ut eller lägga till nya frågor i framtida versioner.

---

<a id="adkar"></a>
## Förändringsledning ADKAR

För att säkerställa att medarbetarna tar till sig utbildningen använder vi ADKAR-modellen:

- 🟢 **Awareness:** Vi lanserar spelet via ett fejkat "hackar-meddelande" på intranätet/Slack.
- 🟡 **Desire:** Storyn om ransomware skapar spänning. Scoreboarden driver motivation och viljan att vara snabbast.
- 🟠 **Knowledge:** Spelets 5 utmaningar fungerar som pedagogiska moment med inbyggda ledtrådar.
- 🔴 **Ability:** Genom att skriva kommandon och lösa problem under tidspress bevisar medarbetarna sin förmåga.
- 🟣 **Reinforcement:** Spelet kan expanderas med nya frågor varje år för att hålla kunskapen färsk.

### Hantering av motstånd
För anställda som tvekar (ofta p.g.a. rädsla för terminalmiljön) erbjuder vi *Pair-playing* med en kollega. Skulle någon vägra helt, erbjuds traditionell skriftlig compliance-utbildning.

---

<a id="itil"></a>
## ITIL Continual Improvement

Projektet stödjer organisationens ITSM-processer genom att koppla samman praktisk utbildning med proaktiv supportverksamhet:

* **Service Desk Avlastning:** Genom att höja användarnas praktiska förmåga (*Ability*) att identifiera cyberhot, minskar vi antalet incidenter orsakade av den mänskliga faktorn. När medarbetare själva kan identifiera och undvika phishinglänkar, skadliga bilagor och social engineering-försök, minskar trycket på First-Line Support avsevärt. Detta leder till:
    * **Färre akuta säkerhetsincidenter:** Färre infekterade datorer innebär mindre tidskrävande skadebegränsning och ominspektioner av klienter.
    * **Kortare svarstider:** När inflödet av enkla, användarrelaterade fel minskar, kortas köerna till Service Desk för andra kritiska ärenden.
    * **Strategiskt resursskapande:** Supporttekniker avlastas från reaktiva "brandkårsutryckningar" och kan istället lägga tid på proaktivt arbete, kunskapsartiklar och Problem Management.

* **Continual Improvement (CSI):** Spelets inbyggda datainsamling (via JSON) skapar en direkt feedback-loop till IT-avdelningen och Service Desk. Genom att analysera anonymiserad statistik över *var* användarna svarar fel eller drabbas av mest tidsstraff, kan organisationen bedriva ett helt datadrivet förbättringsarbete. Detta samverkar med Service Desk på följande sätt:
    * **Identifiering av dolda kunskapsluckor:** Om datan visar att en stor majoritet av spelarna får tidsstraff på exempelvis utmaningen om lösenordssäkerhet, vet IT-avdelningen exakt vad nästa riktade utbildningsinsats eller informationskampanj måste fokusera på.
    * **Proaktiv Knowledge Management:** Istället för att Service Desk ska vänta på att felaktiga beteenden leder till riktiga incidenter, kan de använda spelets data för att proaktivt uppdatera sina självbetjäningsportaler och skapa relevanta guider innan problemen uppstår.
    * **Mätbar beteendeförändring:** Genom att köra spelet i omgångar kan vi jämföra JSON-datan över tid. Om tidsstraffen minskar och slutresultaten förbättras har vi ett mätbart, konkret kvitto på att säkerhetsmedvetenheten ökar, vilket i sin tur bekräftar den långsiktiga avlastningen för Service Desk.

---

<a id="installation"></a>
## Installation och Spela

Spelet är helt portabelt och kräver ingen traditionell installation. Allt som behövs är att ladda ner projektfilerna och starta spelet direkt från din terminal.

### Förutsättningar
* **Operativsystem:** Windows 10 eller Windows 11.
* **Miljö:** PowerShell 5.1 eller senare (inbyggt i Windows standardmiljö).

### Kom igång på 3 enkla steg

**Steg 1: Ladda ner filerna**
Klicka på den gröna knappen **Code** högst upp på denna GitHub-sida och välj **Download ZIP** (och packa upp filen), alternativt klona projektet direkt via Git:

Powershell:

git clone andreasdahlstrom-Student/produktmetodik-scripting-uppgift2


**Steg 2: Öppna PowerShell och navigera till mappen**
Starta PowerShell och använd kommandot cd för att ställa dig i den mapp där du sparade spelets filer:

Powershell:

cd "C:\Sökväg\Till\Mappen\CLI-Security-Escape-Room"


**Steg 3: Starta spelet**
Kör spelets huvudskript för att kicka igång ransomware-simuleringen:

Powershell:

.\Start-Game.ps1

⚠️ **Felsökning:** Om skriptet blockeras av Windows
Eftersom Windows har inbyggda säkerhetsspärrar mot att köra externa skript som laddats ner från internet, kan du mötas av ett rött felmeddelande när du försöker starta.

För att lösa detta och tillåta att spelet körs i just det fönstret, klistra in följande kommando i PowerShell och tryck på Enter:

Powershell: 

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Detta kommando ändrar endast säkerhetspolicyn tillfälligt för ditt öppna terminalfönster. Så fort du stänger fönstret återställs datorns permanenta systemsäkerhet till det normala.
