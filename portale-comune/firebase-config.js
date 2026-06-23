// Configurazione Firebase per portale-comune
const firebaseConfig = {
  apiKey: "AIzaSyB8f8WT5uaEB3J6BLOXeF9o27tBpsE9Dis",
  authDomain: "civicos-bb9f7.firebaseapp.com",
  databaseURL: "https://civicos-bb9f7-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "civicos-bb9f7",
  storageBucket: "civicos-bb9f7.firebasestorage.app",
  messagingSenderId: "41965079417",
  appId: "1:41965079417:web:88dc757cb4033e59d33da8"
};

if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}
const firestore = firebase.firestore();
const civicosAuth = typeof firebase.auth === 'function' ? firebase.auth() : null;

let _firebaseSessionReady = null;

function civicosEnsureFirebaseSession() {
  if (_firebaseSessionReady) return _firebaseSessionReady;
  _firebaseSessionReady = (async function() {
    if (!civicosAuth) return true;
    return new Promise(function(resolve) {
      var unsub = civicosAuth.onAuthStateChanged(function(user) {
        unsub();
        resolve(!!user);
      });
    });
  })();
  return _firebaseSessionReady;
}

// Ricava comuneId dalla sessione (es. "Vibo Valentia" → "vibo-valentia")
function _normalizeComuneId(value) {
  if (typeof window.civicosNormalizeComuneId === 'function') {
    return window.civicosNormalizeComuneId(value) || null;
  }
  if (!value || typeof value !== 'string') return null;
  return value.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/['\s]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function _getComuneId() {
  try {
    const raw = sessionStorage.getItem('civicos_auth');
    if (raw) {
      const a = JSON.parse(raw);
      if (a.comune) {
        const fromAuth = _normalizeComuneId(a.comune);
        if (fromAuth) return fromAuth;
      }
    }

    // Fallback al comune selezionato in fase login, se disponibile.
    const selected = sessionStorage.getItem('civicos_comune_sel');
    const fromSelection = _normalizeComuneId(selected);
    if (fromSelection) return fromSelection;
  } catch(e) {}
  return 'default';
}

function civicosGetComuneId() {
  return _getComuneId();
}

function civicosGetComuneRef() {
  return firestore.collection('comuni').doc(civicosGetComuneId());
}

const comuneId = civicosGetComuneId();

// Espone un riferimento dinamico: i file del portale possono continuare a usare
// "comuneRef" senza rischiare di puntare al tenant sbagliato.
Object.defineProperty(window, 'comuneRef', {
  configurable: true,
  enumerable: true,
  get: function() {
    return civicosGetComuneRef();
  }
});

window.civicosEnsureFirebaseSession = civicosEnsureFirebaseSession;
