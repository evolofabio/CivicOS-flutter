// Autenticazione Firebase per operatori comunali.

function civicosNormalizeComuneId(value) {
  if (!value || typeof value !== 'string') return '';
  return value.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/['\s]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function civicosAuthErrorMessage(code) {
  var map = {
    'auth/user-not-found': 'Email o password non corretti',
    'auth/wrong-password': 'Email o password non corretti',
    'auth/invalid-credential': 'Email o password non corretti',
    'auth/invalid-login-credentials': 'Email o password non corretti',
    'auth/email-already-in-use': 'Email già registrata',
    'auth/weak-password': 'Password troppo debole (minimo 6 caratteri)',
    'auth/too-many-requests': 'Troppi tentativi, riprova più tardi',
    'auth/user-disabled': 'Account disabilitato'
  };
  return map[code] || 'Errore di autenticazione';
}

function civicosSaveAuthSession(data) {
  sessionStorage.setItem('civicos_auth', JSON.stringify(data));
  if (data.comune) sessionStorage.setItem('civicos_comune_sel', data.comune);
}

async function civicosSignInOperatore(email, password, comuneName) {
  if (!firebase.auth) throw new Error('Firebase Auth non disponibile');
  var comuneId = civicosNormalizeComuneId(comuneName);
  if (!comuneId) throw new Error('Comune non valido');

  var cred = await firebase.auth().signInWithEmailAndPassword(email.trim(), password);
  var uid = cred.user.uid;
  var db = firebase.firestore();

  var opDoc = await db.collection('comuni').doc(comuneId).collection('operatori').doc(uid).get();
  if (!opDoc.exists || opDoc.data().abilitato !== true) {
    await firebase.auth().signOut();
    throw new Error('Non sei un operatore abilitato per il Comune di ' + comuneName + '.');
  }

  var profile = opDoc.data();
  await db.collection('utenti').doc(uid).set({
    comuneId: comuneId,
    email: email.trim(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  civicosSaveAuthSession({
    uid: uid,
    email: email.trim(),
    nome: profile.nome || '',
    cognome: profile.cognome || '',
    role: profile.ruolo || 'operatore',
    comune: comuneName,
    loggedIn: true,
    ts: Date.now()
  });

  return profile;
}

async function civicosSetupSindaco(params) {
  if (!firebase.auth) throw new Error('Firebase Auth non disponibile');
  var comuneName = params.comuneName;
  var comuneId = civicosNormalizeComuneId(comuneName);
  var email = params.email.trim();
  var password = params.password;

  var cred = await firebase.auth().createUserWithEmailAndPassword(email, password);
  var uid = cred.user.uid;
  var db = firebase.firestore();
  var ts = firebase.firestore.FieldValue.serverTimestamp();
  var today = new Date().toISOString().slice(0, 10);

  await db.collection('utenti').doc(uid).set({
    comuneId: comuneId,
    email: email,
    updatedAt: ts
  }, { merge: true });

  await db.collection('comuni').doc(comuneId).collection('operatori').doc(uid).set({
    uid: uid,
    email: email,
    nome: params.nome,
    cognome: params.cognome,
    telefono: params.telefono || '',
    ruolo: 'sindaco',
    abilitato: true,
    stato: 'attivo',
    creato: today,
    updatedAt: ts
  }, { merge: true });

  await db.collection('comuni').doc(comuneId).set({
    frazioni: params.frazioni || [],
    sindaco: {
      nome: params.nome,
      cognome: params.cognome,
      email: email,
      telefono: params.telefono || '',
      creato: today
    },
    info: params.info || {},
    creato: today,
    updatedAt: ts
  }, { merge: true });

  await db.collection('comuni').doc(comuneId).collection('config').doc('servizi').set({
    categorieSegnalazione: [
      'Rifiuti abbandonati', 'Discariche abusive', 'Cestini pieni', 'Degrado urbano',
      'Illuminazione', 'Strade', 'Verde pubblico', 'Igiene pubblica'
    ],
    tipiIngombranti: ['Mobili', 'Elettrodomestici', 'Materassi', 'Elettronica', 'Altro'],
    motivazioniCisterna: [
      'Assenza totale di acqua', 'Pressione insufficiente', 'Cisterna vuota (periodo estivo)',
      'Guasto alla rete idrica', 'Lavori programmati sulla rete', 'Altro'
    ],
    updatedAt: ts
  }, { merge: true });

  civicosSaveAuthSession({
    uid: uid,
    email: email,
    nome: params.nome,
    cognome: params.cognome,
    role: 'sindaco',
    comune: comuneName,
    loggedIn: true,
    ts: Date.now()
  });

  return uid;
}

async function civicosSignOutOperatore() {
  try {
    if (firebase.auth) await firebase.auth().signOut();
  } catch (e) { /* ignore */ }
  sessionStorage.removeItem('civicos_auth');
}

async function civicosIsComuneConfigured(comuneName) {
  var comuneId = civicosNormalizeComuneId(comuneName);
  if (!comuneId || typeof firebase === 'undefined' || !firebase.firestore) return false;
  try {
    var doc = await firebase.firestore().collection('comuni').doc(comuneId).get();
    if (doc.exists) {
      var d = doc.data();
      if (d.sindaco || (Array.isArray(d.frazioni) && d.frazioni.length > 0)) return true;
    }
    var ops = await firebase.firestore().collection('comuni').doc(comuneId)
      .collection('operatori').where('abilitato', '==', true).limit(1).get();
    if (!ops.empty) return true;
  } catch (e) { /* ignore */ }
  return false;
}

async function civicosCreateOperatoreViaFunction(payload) {
  if (typeof firebase.functions !== 'function') {
    throw new Error('Firebase Functions non disponibile');
  }
  var fn = firebase.app().functions('europe-west1').httpsCallable('createOperatore');
  try {
    var result = await fn(payload);
    return result.data;
  } catch (err) {
    var msg = (err.details && err.details.message) || err.message || 'Errore creazione utente';
    throw new Error(msg);
  }
}

window.civicosNormalizeComuneId = civicosNormalizeComuneId;
window.civicosAuthErrorMessage = civicosAuthErrorMessage;
window.civicosSaveAuthSession = civicosSaveAuthSession;
window.civicosSignInOperatore = civicosSignInOperatore;
window.civicosSetupSindaco = civicosSetupSindaco;
window.civicosSignOutOperatore = civicosSignOutOperatore;
window.civicosIsComuneConfigured = civicosIsComuneConfigured;
window.civicosCreateOperatoreViaFunction = civicosCreateOperatoreViaFunction;
