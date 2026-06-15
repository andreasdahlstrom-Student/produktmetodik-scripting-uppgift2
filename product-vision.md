# Product Vision

## Projekt: Säkerhetsutbildning via CLI (Alternativ C)

### Vision
Vi bygger ett interaktivt "Escape Room"-spel i terminalen som lär användare om IT-säkerhet. Spelet ska göra säkerhetsutbildning engagerande genom att paketera lärandet som ett spel istället för traditionell, påtvingad utbildning.

### Hur spelet fungerar
- Spelet består av flera rum.
- I varje rum får spelaren en pusselbit som behövs för att öppna dörren och till slut vinna spelet.
- Spelaren har **3 liv** och får ett liv för varje avklarad fråga.
- Ett av rummen innehåller logiken för **"hänga gubbe"**, där spelaren har ett visst antal liv och svarsalternativ kopplat till en **progress bar**. Om progress baren når toppen utan att gubben hängs vinner spelaren.

### Ramar och begränsningar
- **Spår:** Alternativ C – Säkerhetsutbildning via CLI.
- **Teknik:** PowerShell med moduluppbyggnad (PS1-/modulfiler), sparfunktion i JSON, avancerat kontrollflöde. Errorhandling ska hanteras på ett tillfredsställande sätt.
- **Versionshantering:** GitHub med Project Board.
- **Deadline:** Redovisning onsdag 17/6, v. 25.

### Vad lösningen ska klara
- Köras i terminalen som ett interaktivt spel.
- Läsa in frågor från en `questions.json`-fil.
- Hantera liv, svarsalternativ och progress bar.
- Ha en huvudmeny med möjlighet att fortsätta ett pågående spel.
