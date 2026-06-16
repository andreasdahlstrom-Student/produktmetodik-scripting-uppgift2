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

**Syftet** med projektet är att ersetätta passiv och "tråkig" IT-säkerhetsutbildning med en spännande, verklighetsförankrad utmaning. Genom spelet tränar medarbetarna på riktiga säkerhetsrisker på ett sätt som faktiskt skapar engagemang.

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

Projektet stödjer organisationens ITSM-processer:

* **Service Desk Avlastning:** Ökad förmåga (*Ability*) hos användarna resulterar i färre handhavandefel och klickade phishinglänkar. Detta frigör tid för Service Desk.
* **Continual Improvement:** Insamling av data (via JSON) visar var användare svarar fel eller får mest tidsstraff. Faller många på en specifik fråga vet IT-avdelningen exakt vad nästa utbildningsinsats bör fokusera på.

---

<a id="installation"></a>
## Installation och Spela

Spelet kräver ingen installation utöver att ladda ner filerna. 

### Förutsättningar
* Windows OS
* PowerShell
