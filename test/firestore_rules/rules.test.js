const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { readFileSync } = require('fs');

const rules = readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8');

describe('CivicOS Firestore rules', function () {
  /** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
  let testEnv;

  before(async function () {
    testEnv = await initializeTestEnvironment({
      projectId: 'civicos-rules-test',
      firestore: { rules, host: '127.0.0.1', port: 8080 },
    });
  });

  after(async function () {
    await testEnv.cleanup();
  });

  beforeEach(async function () {
    await testEnv.clearFirestore();
  });

  it('nega lettura segnalazioni ad anonimo', async function () {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection('comuni').doc('vibo-valentia').collection('segnalazioni').get(),
    );
  });

  it('consente bootstrap utente al proprietario', async function () {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('utenti').doc('user1').set({
        comuneId: 'vibo-valentia',
        email: 'a@test.it',
      });
    });

    const db = testEnv.authenticatedContext('user1').firestore();
    await assertSucceeds(db.collection('utenti').doc('user1').get());
  });

  it('consente create contatti landing senza auth', async function () {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(
      db.collection('contatti').add({
        nome: 'Mario Rossi',
        email: 'mario@test.it',
        messaggio: 'Info su CivicOS',
      }),
    );
  });

  it('nega lettura contatti', async function () {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('contatti').doc('c1').set({
        nome: 'X',
        email: 'x@test.it',
        messaggio: 'Hi',
      });
    });
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection('contatti').doc('c1').get());
  });

  it('cittadino legge config servizi del proprio comune', async function () {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const admin = ctx.firestore();
      await admin.collection('utenti').doc('cit1').set({
        comuneId: 'vibo-valentia',
        email: 'c@test.it',
      });
      await admin.collection('comuni').doc('vibo-valentia').collection('config').doc('servizi').set({
        categorieSegnalazione: ['Rifiuti'],
      });
    });

    const db = testEnv.authenticatedContext('cit1').firestore();
    await assertSucceeds(
      db.collection('comuni').doc('vibo-valentia').collection('config').doc('servizi').get(),
    );
  });
});
