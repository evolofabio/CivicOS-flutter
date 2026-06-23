# CivicOS – Portale Comune (Operatori)

Portale web per gli operatori comunali. Consente la gestione di segnalazioni, prenotazioni, comunicazioni, cisterne, calendario, aziende, mezzi, scadenze e utenti.

## Funzionalità

- Login e registrazione operatori per comune
- Setup iniziale del comune (selezione stemma, configurazione)
- Dashboard con navigazione a tutti i servizi attivi
- Servizi: Segnalazioni, Prenotazioni, Cisterne, Calendario, Comunicazioni, Aziende, Mezzi, Scadenze, Utenti

## Avvio

```bash
cd portale-comune
python3 -m http.server 8090
```

Apri nel browser: [http://localhost:8090/login.html](http://localhost:8090/login.html)

## File principali

| File | Descrizione |
|------|-------------|
| `login.html` | Login operatori |
| `registrazione.html` | Registrazione nuovo operatore |
| `setup.html` | Setup iniziale comune |
| `portale.html` | Dashboard principale operatore |
| `index.html` | Hub navigazione servizi |
| `style.css` | Stile globale portale |
| `auth.css` | Stile pagine di autenticazione |
| `portale-auth.js` | Gestione autenticazione |
| `app.js` | Logica applicativa comune |

## Servizi (pagine + script)

| Servizio | HTML | JS |
|----------|------|----|
| Segnalazioni | `segnalazioni.html` | `segnalazioni.js` |
| Prenotazioni | `prenotazioni.html` | `prenotazioni.js` |
| Cisterne | `cisterne.html` | `cisterne.js` |
| Calendario | `calendario.html` | `calendario.js` |
| Comunicazioni | `comunicazioni.html` | `comunicazioni.js` |
| Aziende | `aziende.html` | `aziende.js` |
| Mezzi | `mezzi.html` | `mezzi.js` |
| Scadenze | `scadenze.html` | `scadenze.js` |
| Utenti | `utenti.html` | — |

## Stemmi

Cartella `stemmi/` contiene i loghi dei comuni:
mileto.png, nicotera.png, serra-san-bruno.png, tropea.png, vibo-valentia.png

## Storage

I dati operativi sono su **Firestore** (`comuni/{comuneId}/...`).  
Config sezioni in `comuni/{comuneId}/config/{sezione}`.  
Il catalogo comuni/frazioni resta in `mock_data.dart` (app mobile).
