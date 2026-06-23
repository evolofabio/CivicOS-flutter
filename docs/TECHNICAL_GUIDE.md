# CivicOS - Technical Guide

Questa guida centralizza setup, architettura, sincronizzazione Firebase, notifiche, sicurezza e checklist operativa.

## 1) Architettura progetto

Il workspace contiene 3 prodotti principali:

- App mobile Flutter cittadini: `lib/`
- Portale Admin web: `portale-admin/`
- Portale Comune web: `portale-comune/`

Backend e infrastruttura:

- Cloud Functions: `functions/index.js`
- Regole Firestore: `firestore.rules`
- Config Firebase Hosting/Functions: `firebase.json`

## 2) Prerequisiti

- Flutter SDK installato e configurato
- Android SDK / ADB (per device fisico)
- Firebase CLI (`firebase --version`)
- Account Firebase con accesso al progetto

## 3) Setup locale

### App Flutter

```bash
flutter pub get
flutter run -d android
```

### Portale Comune

```bash
cd portale-comune
python3 -m http.server 8090
```

URL: `http://localhost:8090/login.html`

### Portale Admin

```bash
cd portale-admin
python3 -m http.server 8091
```

URL: `http://localhost:8091/admin-login.html`

## 4) Calendario raccolta (Firestore)

Documento: `comuni/{comuneId}/calendari/differenziata`

Campi:

- `perFrazione`: mappa `{ frazione: [{ giorno, tipi[], variazione }] }`
- `updatedAt`: timestamp server

File coinvolti:

- App mobile: `lib/core/services/calendario_service.dart`
- Portale comune: `portale-comune/calendario.js` (Firestore `comuni/{id}/calendari/differenziata`)

L'app legge il calendario in tempo reale e usa `MockData` solo come fallback offline.

## 5) Flusso sincronizzazione (mobile)

### Fonte dati profilo

Documento Firestore: `utenti/{uid}`

Campi principali gestiti dall'app mobile:

- anagrafica: `nome`, `cognome`, `dataNascita`, `codiceFiscale`, `telefono`, `email`
- residenza: `residenza.indirizzo`, `residenza.civico`, `residenza.cap`, `residenza.provincia`
- abitazioni: array `abitazioni[]`
- contesto: `comune`, `comuneId`, `frazione`

### Lettura

- All'avvio app e al login viene eseguito il load remoto del profilo (`utenti/{uid}`)
- Il model `CitizenData` viene idratato da Firestore

File coinvolti:

- `lib/app.dart`
- `lib/core/models/citizen_data.dart`

### Scrittura

- Salvataggio profilo (anagrafica, residenza, abitazioni) da sezione Profilo
- Salvataggio comune/frazione quando l'utente li modifica
- Registrazione utente salva il contesto iniziale su `utenti/{uid}`

File coinvolti:

- `lib/features/profile/profile_screen.dart`
- `lib/app.dart`
- `lib/features/auth/registration_screen.dart`

## 5) Notifiche mobile

### Canale di ricezione

- FCM topic per comune: `comune_{comuneId}`
- Token e topic utente persistiti in `utenti/{uid}`

File: `lib/services/firebase_messaging_service.dart`

### Anti-duplicazione

Per evitare notifiche ripetute a ogni apertura:

- bootstrap listener con `lastNotificaSeenAt`
- persistenza per utente in Firestore:
  - `lastNotificaSeenComuneId`
  - `lastNotificaSeenAt`
- dedup in-session per stessa chiave notifica

File: `lib/app.dart`

## 6) Build e reinstall su Android fisico

### Rebuild completa

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

APK output:

`build/app/outputs/flutter-apk/app-debug.apk`

### Install su device

```bash
adb devices
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-debug.apk
```

Se necessario reinstall pulita:

```bash
adb -s <DEVICE_ID> uninstall com.example.civic_os
adb -s <DEVICE_ID> install build/app/outputs/flutter-apk/app-debug.apk
```

## 7) Test checklist raccomandata

### Profilo e sync account

1. Login con account reale
2. Modifica anagrafica + residenza + abitazioni
3. Verifica su Firestore `utenti/{uid}`
4. Chiudi e riapri app
5. Verifica che i dati siano ricaricati

### Notifiche

1. Pubblica nuova comunicazione (`stato: attivo`) nel comune utente
2. Verifica singola notifica ricevuta
3. Chiudi e riapri app senza nuova comunicazione
4. Verifica che non venga ripetuta

## 8) Sicurezza e privacy (stato attuale)

- App mobile: sincronizzazione utente spostata su Firebase (niente storage locale per profilo/comune/frazione)
- Portali web: presenti aree con storage browser (vedi README specifici)

Raccomandazioni:

- rafforzare `firestore.rules` in produzione
- evitare write pubbliche
- applicare hardening headers su hosting
- introdurre audit log e monitoraggio errori runtime

## 9) Deploy

Script disponibili in root:

- `deploy_flutter.sh`
- `deploy_portale_admin.sh`
- `deploy_portale_comune.sh`
- `deploy_landing.sh`

Prima del deploy, verificare sempre:

1. build locale OK
2. smoke test login + sync
3. test notifiche singole (no duplicati)
4. validazione regole Firestore
