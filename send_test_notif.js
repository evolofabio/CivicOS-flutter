const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Checking if this exists later or using default

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'civicos-bb9f7'
  });
}

const db = admin.firestore();

async function send() {
  try {
    const res = await db.collection('comuni/vibo-valentia/comunicazioni').add({
      titolo: 'Test Anti-Duplicazione',
      testo: 'Verifica notifica al reopen',
      stato: 'attivo',
      data: admin.firestore.Timestamp.now()
    });
    console.log('Documento creato con ID: ', res.id);
  } catch (e) {
    console.error('Errore durante la scrittura su Firestore: ', e.message);
  }
}

send();
