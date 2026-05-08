const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions, logger } = require('firebase-functions/v2');
const admin = require('firebase-admin');

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