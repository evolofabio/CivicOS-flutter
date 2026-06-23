# CivicOS – Portale Admin

Dashboard di amministrazione aziendale CivicOS per la gestione dei comuni, servizi e configurazioni.

## Funzionalità

- Login admin con credenziali dedicate
- Panoramica statistiche (comuni attivi, servizi, utenti registrati)
- Griglia comuni con toggle servizi (48 comuni della Provincia di Vibo Valentia)
- Gestione anagrafica comuni (abitanti, CAP, codice catastale, ecc.)
- **Configura Comune** con 7 tab:
  - Sindaco, Sede, Frazioni, Servizi, Personalizzazione, Orari, Link/Contatti

## Avvio

```bash
cd portale-admin
python3 -m http.server 8091
```

Apri nel browser: [http://localhost:8091/admin-login.html](http://localhost:8091/admin-login.html)

## Credenziali di default

- **Email:** admin@civicos.it
- **Password:** admin2026

## File

| File | Descrizione |
|------|-------------|
| `admin.html` | Dashboard principale admin |
| `admin-login.html` | Pagina di login |
| `auth.css` | Stile condiviso per pagine di autenticazione |
| `logo.png` | Logo CivicOS |
| `CivicOS-Remove.png` | Logo trasparente |

## Storage

Tutti i dati applicativi sono su **Firestore**:
- `comuni/{comuneId}` – configurazione comune e toggle servizi
- `comuni/{comuneId}/operatori` – utenti portale
- `comuni/{comuneId}/configHistory` – storico configurazioni
- `platform/audit/entries` – log audit admin
- `platform_admins/{uid}` – accesso portale-admin

Abilitare un admin dopo il primo login Firebase Auth:
```bash
cd functions && node ../scripts/seed_platform_admin.js <uid>
```

La sessione admin usa Firebase Auth; il ruolo UI (super-admin, solo-lettura) è in `sessionStorage`.
