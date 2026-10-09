# ♠️ Poker Trainer (PWA)

Un'applicazione Flutter progettata per allenare le decisioni preflop e il calcolo matematico postflop (Equity, Outs e Pot Odds) nel Texas Hold'em. Si basa sui miei range preferiti di gioco e condizioni limite (stile simile al GTO-TAG).

## 🚀 Funzionalità Principali

### 1. Preflop Opening Trainer
* **Mani casuali dinamiche:** Generazione procedurale di combinazioni preflop.
* **Range dinamici per posizione:** Supporto completo da 2 a 10 giocatori con compressione delle posizioni (Early, Middle, Late, Blinds).
* **Filtri di allenamento:** Possibilità di isolare specifici range o posizioni, oppure testare scenari 100% casuali.
* **Didattica avanzata:** Note contestuali sulle coppie basse per il set mining in Middle Position e gestione dello stack effettivo.

### 2. Odds & Equity Trainer
* **Regola del 4 e del 2:** Passaggio rapido tra Flop (2 carte da vedere) e Turn (1 carta da vedere).
* **Simulazione:** Calibrazione del piatto e delle puntate su un bankroll tipico da 2.000$ fiches. Gestione dello stack personale.
* **Calcolo mentale privo di spoiler:** Visualizzazione dei valori numerici grezzi a schermo per allenare la conversione mentale Pot $\to$ Equity richiesta.
* **Riconoscimento Wet/Dry Board:** Distinzione automatica tra mani chiuse dominanti (Made Hand) e progetti puri da inseguire (Draws).
* **Guida rapida integrata:** Tabella puntate/equity, sconto per tavoli multiway, gestione degli out sporchi, gerarchia completa dei punti e gestione degli stack in Big Blind (BB).

---

## 📲 Installazione su Dispositivo (PWA)

L'applicazione è fruibile direttamente da browser senza passare dagli store:

* **Android (Chrome):** Premi i tre puntini in alto a destra $\to$ **"Aggiungi a schermata Home"** o **"Installa app"**.
* **iOS (Safari):** Premi l'icona di condivisione in basso $\to$ **"Aggiungi alla schermata Home"**.
* **PC / Mac (Chrome / Edge):** Clicca sull'icona di installazione nella barra degli indirizzi in alto a destra.