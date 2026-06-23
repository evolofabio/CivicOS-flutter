/**
 * Abilita un utente Firebase Auth al portale-admin.
 *
 * Uso:
 *   cd functions && node ../scripts/seed_platform_admin.js <firebase-auth-uid>
 */
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const uid = process.argv[2];
if (!uid) {
  console.error('Usage: node seed_platform_admin.js <uid>');
  process.exit(1);
}

admin.firestore().collection('platform_admins').doc(uid).set({
  uid,
  abilitato: true,
  creato: new Date().toISOString()
}).then(function() {
  console.log('Platform admin abilitato:', uid);
  process.exit(0);
}).catch(function(err) {
  console.error(err);
  process.exit(1);
});
