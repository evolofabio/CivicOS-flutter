# Allineamento dati CivicOS

## Stato sync Firestore

| Modulo | App | Portale | Storage |
|--------|-----|---------|---------|
| Profilo utente | ✅ | ✅ | Firestore |
| Segnalazioni | ✅ | ✅ | Firestore |
| Prenotazioni | ✅ | ✅ | Firestore |
| Comunicazioni | ✅ | ✅ | Firestore |
| Cisterne | ✅ | ✅ | Firestore |
| Calendario raccolta | ✅ | ✅ | Firestore |
| Aziende / convenzionati | ✅ | ✅ | Firestore |
| Mezzi / Dipendenti | — | ✅ | Firestore |
| Scadenze | — | ✅ | Firestore |
| Dashboard | — | ✅ | Firestore |
| Config servizi | ✅ | ✅ | `config/servizi` |
| Frazioni comune | ✅ | ✅ | `comuni/{id}.frazioni` |
| Auth operatori portale | — | ✅ | Firebase Auth + `operatori/{uid}` |

## Seed config pilota

```bash
cd functions && node ../scripts/seed_comune_config.js vibo-valentia mileto
```

## Test Firestore rules

```bash
firebase emulators:exec --only firestore "cd test/firestore_rules && npm install && npm test"
```

## TODO residui

- [x] portale-comune: nessun localStorage applicativo (solo Firestore)
- [x] portale-admin: config, servizi, audit, snapshot su Firestore
- [ ] Abilitare admin: `node scripts/seed_platform_admin.js <uid>`
