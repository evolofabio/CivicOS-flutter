# CivicOS

Piattaforma GovTech per comuni italiani, composta da app mobile Flutter e portali web amministrativi.

## Prodotti

- App Flutter cittadini (`lib/`)
- Portale Admin (`portale-admin/`)
- Portale Comune operatori (`portale-comune/`)

## Avvio rapido

### App Flutter

```bash
flutter pub get
flutter run -d android
```

### Portale Admin

```bash
cd portale-admin
python3 -m http.server 8091
```

Apri: http://localhost:8091/admin-login.html

### Portale Comune

```bash
cd portale-comune
python3 -m http.server 8090
```

Apri: http://localhost:8090/login.html

## Documentazione

- Guida tecnica completa: `docs/TECHNICAL_GUIDE.md`
- Stato allineamento dati: `docs/ALIGNMENT.md`
- Portale Admin: `portale-admin/README.md`
- Portale Comune: `portale-comune/README.md`

## Deploy scripts disponibili

- `deploy_flutter.sh`
- `deploy_portale_admin.sh`
- `deploy_portale_comune.sh`
- `deploy_landing.sh`

## Nota

Lo stato corrente dell'app mobile usa sincronizzazione profilo e contesto utente basata su Firebase/Firestore.
