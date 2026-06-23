const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions, logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

function normalizeText(value, fallback = '') {
  return typeof value === 'string' && value.trim() ? value.trim() : fallback;
}

exports.notifyComuneCommunication = onDocumentWritten(
  'comuni/{comuneId}/comunicazioni/{communicationId}',
  async (event) => {
    const after = event.data.after;
    if (!after) {
      return;
    }

    const beforeData = event.data.before ? event.data.before.data() : null;
    const afterData = after.data();
    const comuneId = event.params.comuneId;
    const stato = normalizeText(afterData.stato, 'attivo').toLowerCase();
    const wasActive = normalizeText(beforeData?.stato, '').toLowerCase() === 'attivo';

    // Notifica solo quando viene pubblicato o riattivato.
    if (stato !== 'attivo' || wasActive) {
      return;
    }

    const title = normalizeText(afterData.titolo, 'Nuovo avviso dal comune');
    const bodySource = normalizeText(afterData.contenuto || afterData.corpo, 'Apri CivicOS per leggere la comunicazione.');
    const body = bodySource.length > 140 ? `${bodySource.slice(0, 137)}...` : bodySource;
    const topic = `comune_${comuneId}`;

    const message = {
      topic,
      notification: {
        title,
        body,
      },
      data: {
        screen: 'comunicazioni',
        comuneId,
        communicationId: event.params.communicationId,
        tipo: normalizeText(afterData.tipo, 'servizio'),
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'civicos_avvisi',
          priority: 'high',
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      logger.info('Push inviata', { topic, response, title });
    } catch (error) {
      logger.error('Errore invio push', { topic, error });
    }
  },
);

// ── Notifica email su nuovo contatto dalla landing page ──────────────────────
// Setup richiesto (una-tantum):
//   firebase functions:secrets:set GMAIL_USER   → es. info@civicos.it
//   firebase functions:secrets:set GMAIL_PASS   → App Password Google Workspace
exports.notifyNewContact = onDocumentCreated(
  {
    document: 'contatti/{contactId}',
    region: 'europe-west1',
    secrets: ['GMAIL_USER', 'GMAIL_PASS'],
  },
  async (event) => {
    const data = event.data.data();
    if (!data) return;

    const gmailUser = process.env.GMAIL_USER;
    const gmailPass = process.env.GMAIL_PASS;

    if (!gmailUser || !gmailPass) {
      logger.warn('notifyNewContact: GMAIL_USER o GMAIL_PASS non configurati — skip email');
      return;
    }

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: gmailUser, pass: gmailPass },
    });

    const comuneLine = data.comune ? `\nComune/Org: ${data.comune}` : '';
    const timestamp  = data.timestamp
      ? new Date(data.timestamp.toDate()).toLocaleString('it-IT', { timeZone: 'Europe/Rome' })
      : 'N/D';

    const mailOptions = {
      from:    `CivicOS Landing <${gmailUser}>`,
      to:      'info@civicos.it',
      subject: `[CivicOS] Nuova richiesta demo — ${data.nome}`,
      text: [
        '📩 Nuova richiesta demo dalla landing page',
        '─────────────────────────────────────',
        `Nome:  ${data.nome}`,
        `Email: ${data.email}`,
        comuneLine,
        `Data:  ${timestamp}`,
        '',
        'Messaggio:',
        data.messaggio,
        '─────────────────────────────────────',
        'Vai su Firestore:',
        'https://console.firebase.google.com/project/civicos-bb9f7/firestore/data/~2Fcontatti',
      ].filter(l => l !== undefined).join('\n'),
      replyTo: data.email,
    };

    try {
      await transporter.sendMail(mailOptions);
      logger.info('Email notifica contatto inviata', { to: 'info@civicos.it', from: data.email });
    } catch (err) {
      logger.error('Errore invio email notifica contatto', { err });
    }
  },
);

function normalizeComuneId(value) {
  if (!value || typeof value !== 'string') return '';
  return value.toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/['\s]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

exports.createOperatore = onCall({ region: 'europe-west1' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Accesso richiesto');
  }

  const data = request.data || {};
  const comuneId = normalizeComuneId(data.comuneId);
  const email = normalizeText(data.email).toLowerCase();
  const password = normalizeText(data.password);
  const nome = normalizeText(data.nome);
  const cognome = normalizeText(data.cognome);
  const ruolo = normalizeText(data.ruolo, 'operatore');
  const telefono = normalizeText(data.telefono);

  if (!comuneId || !email || !password || !nome || !cognome) {
    throw new HttpsError('invalid-argument', 'Dati incompleti');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password troppo corta');
  }

  const db = admin.firestore();
  const callerRef = db.collection('comuni').doc(comuneId).collection('operatori').doc(request.auth.uid);
  const callerSnap = await callerRef.get();
  if (!callerSnap.exists || callerSnap.data().abilitato !== true) {
    throw new HttpsError('permission-denied', 'Non autorizzato');
  }

  const today = new Date().toISOString().slice(0, 10);
  let userRecord;
  try {
    userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${nome} ${cognome}`.trim(),
    });
  } catch (err) {
    if (err.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'Email già registrata');
    }
    throw new HttpsError('internal', err.message || 'Errore creazione utente');
  }

  const ts = admin.firestore.FieldValue.serverTimestamp();
  await db.collection('utenti').doc(userRecord.uid).set({
    comuneId,
    email,
    updatedAt: ts,
  }, { merge: true });

  await db.collection('comuni').doc(comuneId).collection('operatori').doc(userRecord.uid).set({
    uid: userRecord.uid,
    email,
    nome,
    cognome,
    ruolo,
    telefono,
    abilitato: true,
    stato: 'attivo',
    creato: today,
    updatedAt: ts,
  }, { merge: true });

  return { uid: userRecord.uid };
});