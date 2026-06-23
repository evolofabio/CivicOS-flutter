/**
 * Seed config/servizi per comuni pilota.
 * Uso: cd functions && node ../scripts/seed_comune_config.js [comuneId...]
 */
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const DEFAULTS = {
  categorieSegnalazione: [
    'Rifiuti abbandonati', 'Discariche abusive', 'Cestini pieni', 'Degrado urbano',
    'Illuminazione', 'Strade', 'Verde pubblico', 'Igiene pubblica',
  ],
  tipiIngombranti: ['Mobili', 'Elettrodomestici', 'Materassi', 'Elettronica', 'Altro'],
  tipiRifiuto: ['Umido', 'Secco', 'Plastica', 'Carta'],
  motivazioniCisterna: [
    'Assenza totale di acqua', 'Pressione insufficiente', 'Cisterna vuota (periodo estivo)',
    'Guasto alla rete idrica', 'Lavori programmati sulla rete', 'Altro',
  ],
  partnerSanitario: {
    nome: 'VisitaMedical',
    telefono: '0963230208',
    whatsapp: '393930156978',
    sito: 'https://www.visitamedical.it',
  },
};

const PILOT = process.argv.slice(2).length
  ? process.argv.slice(2)
  : ['vibo-valentia', 'mileto', 'nicotera', 'tropea', 'serra-san-bruno'];

async function seed(comuneId) {
  await db.collection('comuni').doc(comuneId).collection('config').doc('servizi').set(
    { ...DEFAULTS, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  console.log('Seeded config/servizi →', comuneId);
}

(async () => {
  for (const id of PILOT) await seed(id);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
