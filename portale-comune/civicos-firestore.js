// Shared Firestore helpers for portale-comune modules.

async function civicosLoadSectionConfig(section, defaults) {
  var base = defaults || { attivo: false };
  if (typeof comuneRef === 'undefined' || !comuneRef) return base;
  try {
    await civicosEnsureFirebaseSession();
    var doc = await comuneRef.collection('config').doc(section).get();
    if (!doc.exists) return base;
    return Object.assign({}, base, doc.data());
  } catch (e) {
    console.error('[CivicOS] config load', section, e);
    return base;
  }
}

async function civicosSaveSectionConfig(section, cfg) {
  if (typeof comuneRef === 'undefined' || !comuneRef) return;
  try {
    await civicosEnsureFirebaseSession();
    await comuneRef.collection('config').doc(section).set(
      Object.assign({}, cfg, {
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      }),
      { merge: true }
    );
  } catch (e) {
    console.error('[CivicOS] config save', section, e);
  }
}

function civicosListenCollection(colName, onData, orderField, orderDir) {
  if (typeof comuneRef === 'undefined' || !comuneRef) return function() {};
  var q = comuneRef.collection(colName);
  if (orderField) q = q.orderBy(orderField, orderDir || 'asc');
  return q.onSnapshot(function(snap) {
    var rows = [];
    snap.forEach(function(doc) {
      var d = doc.data();
      d.id = doc.id;
      rows.push(d);
    });
    onData(rows);
  }, function(e) {
    console.error('[CivicOS] listener', colName, e);
  });
}

async function civicosSaveDoc(colName, id, data) {
  await civicosEnsureFirebaseSession();
  var payload = Object.assign({}, data);
  delete payload.id;
  if (id) {
    await comuneRef.collection(colName).doc(id).set(payload, { merge: true });
    return id;
  }
  var ref = await comuneRef.collection(colName).add(payload);
  return ref.id;
}

async function civicosDeleteDoc(colName, id) {
  await civicosEnsureFirebaseSession();
  await comuneRef.collection(colName).doc(id).delete();
}

function civicosDefaultFrazioni(comuneName) {
  var map = {
    'Vibo Valentia': ['Bivona','Longobardi','Piscopio','Porto Salvo','San Pietro di Bivona','Triparni','Vena Inferiore','Vena Media','Vena Superiore','Vibo Marina'],
    'Mileto': ['Calabrò','Comparni','Paravati'],
    'Nicotera': ['Badia','Comerconi','Marina di Nicotera','Preitoni','San Nicola','Monte Poro'],
    'Tropea': []
  };
  return map[comuneName] || [];
}

async function civicosInitPage() {
  await civicosRefreshComuneDoc();
}
