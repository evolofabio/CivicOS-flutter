// ============================================================
// CivicOS – Aziende e Società (JS)
// ============================================================

const actionFlags = {};
let lastRenderToken = 0;
let renderDebounceTimer = null;

function showError(message, error) {
  console.error('[Aziende]', message, error);
  alert(message);
}

function setGuardButtonsDisabled(flagName, disabled) {
  const buttons = document.querySelectorAll(`[data-guard="${flagName}"]`);
  buttons.forEach(btn => {
    btn.disabled = disabled;
    btn.setAttribute('aria-disabled', disabled ? 'true' : 'false');
  });
}

async function runGuarded(flagName, action, errorMessage) {
  if (actionFlags[flagName]) return;
  actionFlags[flagName] = true;
  setGuardButtonsDisabled(flagName, true);
  try {
    return await action();
  } catch (error) {
    showError(errorMessage, error);
  } finally {
    actionFlags[flagName] = false;
    setGuardButtonsDisabled(flagName, false);
  }
}

function scheduleRenderAziende(delayMs = 0) {
  if (renderDebounceTimer) clearTimeout(renderDebounceTimer);
  renderDebounceTimer = setTimeout(() => {
    renderAziende();
  }, delayMs);
}

function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function isValidPiva(value) {
  return /^\d{11}$/.test(value);
}

function isValidCf(value) {
  return /^[A-Z0-9]{16}$/i.test(value);
}

// ---------- Storage helpers ----------
// Firestore CRUD
async function loadAziende() {
  const snapshot = await comuneRef.collection('aziende').orderBy('ragioneSociale').get();
  const aziende = await Promise.all(snapshot.docs.map(async doc => {
    const data = doc.data();
    data.id = doc.id;

    const dipendentiSub = await listDipendentiAzienda(doc.id, data.dipendenti);
    if (dipendentiSub.length > 0) {
      data.dipendenti = dipendentiSub;
    } else if (Array.isArray(data.dipendenti)) {
      data.dipendenti = data.dipendenti;
    } else {
      data.dipendenti = [];
    }

    return data;
  }));

  return aziende;
}
async function saveAziendaFirestore(azienda) {
  const payload = { ...azienda };
  delete payload.dipendenti;

  if (!azienda.id) {
    const ref = await comuneRef.collection('aziende').add(payload);
    azienda.id = ref.id;
  } else {
    await comuneRef.collection('aziende').doc(azienda.id).set(payload, { merge: true });
  }
}
async function deleteAziendaFirestore(id) {
  const dipSnapshot = await comuneRef.collection('aziende').doc(id).collection('dipendenti').get();
  await Promise.all(dipSnapshot.docs.map(doc => doc.ref.delete()));
  await comuneRef.collection('aziende').doc(id).delete();
}

async function listDipendentiAzienda(aziendaId, legacyDipendenti = null) {
  const dipRef = comuneRef.collection('aziende').doc(aziendaId).collection('dipendenti');
  let snapshot = await dipRef.orderBy('nome').get();

  if (snapshot.empty && Array.isArray(legacyDipendenti) && legacyDipendenti.length > 0) {
    await Promise.all(legacyDipendenti.map(raw => {
      const data = raw && typeof raw === 'object' ? { ...raw } : {};
      const legacyId = data.id ? String(data.id) : null;
      delete data.id;

      const targetRef = legacyId ? dipRef.doc(legacyId) : dipRef.doc();
      return targetRef.set(data, { merge: true });
    }));

    snapshot = await dipRef.orderBy('nome').get();
  }

  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

async function saveDipendenteFirestore(aziendaId, dipendente) {
  const payload = { ...dipendente };
  delete payload.id;

  if (!dipendente.id) {
    const ref = await comuneRef
      .collection('aziende')
      .doc(aziendaId)
      .collection('dipendenti')
      .add(payload);
    return ref.id;
  }

  await comuneRef
    .collection('aziende')
    .doc(aziendaId)
    .collection('dipendenti')
    .doc(dipendente.id)
    .set(payload, { merge: true });

  return dipendente.id;
}

async function deleteDipendenteFirestore(aziendaId, dipId) {
  await comuneRef
    .collection('aziende')
    .doc(aziendaId)
    .collection('dipendenti')
    .doc(dipId)
    .delete();
}
var aziendeSectionConfig = { attivo: false };
function loadSectionConfig() { return Object.assign({}, aziendeSectionConfig); }
function saveSectionConfig(cfg) {
  aziendeSectionConfig = Object.assign({}, cfg);
  civicosSaveSectionConfig('aziende', aziendeSectionConfig);
}
async function initAziendeSectionConfig() {
  aziendeSectionConfig = await civicosLoadSectionConfig('aziende', { attivo: false });
  refreshSectionUI();
}

// ---------- Section toggle ----------
function toggleSection() {
  const cfg = loadSectionConfig();
  cfg.attivo = document.getElementById('serviceToggle').checked;
  saveSectionConfig(cfg);
  refreshSectionUI();
}
function refreshSectionUI() {
  const cfg = loadSectionConfig();
  const toggle = document.getElementById('serviceToggle');
  const icon = document.getElementById('serviceIcon');
  const label = document.getElementById('serviceStatusLabel');
  const plabel = document.getElementById('servicePeriodLabel');
  const content = document.getElementById('sectionContent');
  toggle.checked = cfg.attivo;
  if (cfg.attivo) {
    icon.textContent = '●';
    icon.style.color = '#2E7D32';
    label.textContent = 'Sezione attiva';
    plabel.textContent = 'Gestione aziende e società abilitata';
    content.classList.remove('service-disabled-overlay');
  } else {
    icon.textContent = '●';
    icon.style.color = '#E53935';
    label.textContent = 'Sezione disattivata';
    plabel.textContent = 'Attiva questa sezione per gestire aziende e società';
    content.classList.add('service-disabled-overlay');
  }
}

// ---------- Mock data ----------
// Mock non più necessario: ora i dati sono su Firestore
// ---------- Render ----------
async function renderAziende() {
  const renderToken = ++lastRenderToken;
  try {
    const aziende = await loadAziende();
    if (renderToken !== lastRenderToken) return;

    const filterSettore = document.getElementById('filterSettore').value;
    const filterSearch = document.getElementById('filterSearch').value.toLowerCase();
    let filtered = aziende;
    if (filterSettore) filtered = filtered.filter(a => a.settore === filterSettore);
    if (filterSearch) filtered = filtered.filter(a =>
      a.ragioneSociale.toLowerCase().includes(filterSearch) ||
      a.settore.toLowerCase().includes(filterSearch) ||
      (a.piva || '').includes(filterSearch)
    );

    // Stats
    const totalDip = aziende.reduce((s, a) => s + (a.dipendenti ? a.dipendenti.length : 0), 0);
    const totalMens = aziende.reduce((s, a) => s + (a.costoMensile || 0), 0);
    const totalAnno = aziende.reduce((s, a) => s + (a.costoAnnuo || 0), 0);
    document.getElementById('statAziende').textContent = aziende.length;
    document.getElementById('statDipendenti').textContent = totalDip;
    document.getElementById('statCostoMensile').textContent = '€ ' + totalMens.toLocaleString('it-IT');
    document.getElementById('statCostoAnnuo').textContent = '€ ' + totalAnno.toLocaleString('it-IT');

    const container = document.getElementById('aziendeList');
    if (filtered.length === 0) {
      container.innerHTML = '<p style="color:#888;grid-column:1/-1;">Nessuna azienda trovata.</p>';
      return;
    }
    container.innerHTML = filtered.map(a => {
      const numDip = a.dipendenti ? a.dipendenti.length : 0;
      const idAttr = escAttr(a.id);
      return `
      <div class="azienda-card">
        <h3>${escH(a.ragioneSociale)}</h3>
        <span class="settore-badge">${escH(a.settore)}</span>
        <div class="info-row">📋 P.IVA: ${escH(a.piva || '–')}</div>
        <div class="info-row">📍 ${escH(a.indirizzo || '–')}</div>
        <div class="info-row">📞 ${escH(a.telefono || '–')} · ✉️ ${escH(a.email || '–')}</div>
        ${a.bando ? `<div class="info-row">📄 ${escH(a.bando)}</div>` : ''}
        ${a.scadenza ? `<div class="info-row">📅 Scadenza: ${formatDate(a.scadenza)}</div>` : ''}
        <div class="costi-row">
          <div class="costo"><span>Mensile</span><strong>€ ${(a.costoMensile || 0).toLocaleString('it-IT')}</strong></div>
          <div class="costo"><span>Annuo</span><strong>€ ${(a.costoAnnuo || 0).toLocaleString('it-IT')}</strong></div>
          <div class="costo"><span>Dipendenti</span><strong>${numDip}</strong></div>
        </div>
        <div class="card-actions">
          <button class="btn btn-primary" type="button" data-action="open-detail" data-id="${idAttr}">Dettagli</button>
          <button class="btn btn-outline" type="button" data-action="edit-azienda" data-id="${idAttr}" aria-label="Modifica azienda ${escH(a.ragioneSociale)}">✏️</button>
          <button class="btn btn-outline" type="button" data-action="delete-azienda" data-id="${idAttr}" style="color:#E53935;border-color:#E53935;" aria-label="Elimina azienda ${escH(a.ragioneSociale)}">🗑️</button>
        </div>
      </div>`;
    }).join('');
  } catch (error) {
    const container = document.getElementById('aziendeList');
    if (container) {
      container.innerHTML = '<p style="color:#E53935;grid-column:1/-1;">Errore nel caricamento aziende.</p>';
    }
    showError('Impossibile caricare le aziende. Riprova.', error);
  }
}

function escH(str) {
  const d = document.createElement('div');
  d.textContent = str;
  return d.innerHTML;
}
function escAttr(str) {
  return String(str ?? '')
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
function formatDate(d) {
  if (!d) return '–';
  const parts = d.split('-');
  return parts.length === 3 ? `${parts[2]}/${parts[1]}/${parts[0]}` : d;
}

// ---------- Azienda CRUD ----------
function openAziendaModal() {
  document.getElementById('modalTitle').textContent = 'Nuova Azienda';
  document.getElementById('editAziendaId').value = '';
  ['azRagioneSociale','azPiva','azIndirizzo','azTelefono','azEmail','azBando','azScadenza'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('azCostoMensile').value = '';
  document.getElementById('azCostoAnnuo').value = '';
  document.getElementById('azSettore').value = 'Nettezza urbana';
  document.getElementById('aziendaModal').classList.add('open');
}
function closeAziendaModal() { document.getElementById('aziendaModal').classList.remove('open'); }

async function saveAzienda() {
  return runGuarded('saveAzienda', async () => {
    const rs = document.getElementById('azRagioneSociale').value.trim();
    if (!rs) { alert('Inserire la ragione sociale'); return; }

    const piva = document.getElementById('azPiva').value.trim();
    if (piva && !isValidPiva(piva)) {
      alert('La P.IVA deve contenere 11 cifre numeriche.');
      return;
    }

    const email = document.getElementById('azEmail').value.trim();
    if (email && !isValidEmail(email)) {
      alert('Inserire un indirizzo email valido.');
      return;
    }

    const costoMensile = parseFloat(document.getElementById('azCostoMensile').value) || 0;
    const costoAnnuo = parseFloat(document.getElementById('azCostoAnnuo').value) || 0;
    if (costoMensile < 0 || costoAnnuo < 0) {
      alert('I costi non possono essere negativi.');
      return;
    }

    const editId = document.getElementById('editAziendaId').value;
    const data = {
      ragioneSociale: rs,
      settore: document.getElementById('azSettore').value,
      piva,
      indirizzo: document.getElementById('azIndirizzo').value.trim(),
      telefono: document.getElementById('azTelefono').value.trim(),
      email,
      costoMensile,
      costoAnnuo,
      bando: document.getElementById('azBando').value.trim(),
      scadenza: document.getElementById('azScadenza').value
    };
    if (editId) {
      data.id = editId;
      await saveAziendaFirestore(data);
    } else {
      await saveAziendaFirestore(data);
    }
    closeAziendaModal();
    await renderAziende();
  }, 'Impossibile salvare l\'azienda. Riprova.');
}

async function editAzienda(id) {
  try {
    const aziende = await loadAziende();
    const az = aziende.find(a => a.id === id);
    if (!az) return;
    document.getElementById('modalTitle').textContent = 'Modifica Azienda';
    document.getElementById('editAziendaId').value = id;
    document.getElementById('azRagioneSociale').value = az.ragioneSociale || '';
    document.getElementById('azSettore').value = az.settore || 'Nettezza urbana';
    document.getElementById('azPiva').value = az.piva || '';
    document.getElementById('azIndirizzo').value = az.indirizzo || '';
    document.getElementById('azTelefono').value = az.telefono || '';
    document.getElementById('azEmail').value = az.email || '';
    document.getElementById('azCostoMensile').value = az.costoMensile || '';
    document.getElementById('azCostoAnnuo').value = az.costoAnnuo || '';
    document.getElementById('azBando').value = az.bando || '';
    document.getElementById('azScadenza').value = az.scadenza || '';
    document.getElementById('aziendaModal').classList.add('open');
  } catch (error) {
    showError('Impossibile caricare i dati dell\'azienda.', error);
  }
}

async function deleteAzienda(id) {
  if (!confirm('Eliminare questa azienda e tutti i suoi dipendenti?')) return;
  return runGuarded('deleteAzienda', async () => {
    await deleteAziendaFirestore(id);
    await renderAziende();
    closeDetail();
  }, 'Impossibile eliminare l\'azienda. Riprova.');
}

// ---------- Azienda Detail ----------
async function openAziendaDetail(id) {
  try {
    const aziende = await loadAziende();
    const az = aziende.find(a => a.id === id);
    if (!az) return;
    document.getElementById('detailTitle').textContent = az.ragioneSociale;

  let dipHtml = '';
  if (az.dipendenti && az.dipendenti.length > 0) {
    dipHtml = `<table class="dip-table"><thead><tr><th>Nome</th><th>CF</th><th>Ruolo</th><th>Telefono</th><th>Email</th><th>Dal</th><th></th></tr></thead><tbody>` +
      az.dipendenti.map(d => `<tr>
        <td>${escH(d.nome)}</td><td>${escH(d.cf || '–')}</td><td>${escH(d.ruolo || '–')}</td>
        <td>${escH(d.telefono || '–')}</td><td>${escH(d.email || '–')}</td><td>${formatDate(d.assunzione)}</td>
        <td>
          <button class="btn btn-outline" type="button" style="font-size:11px;padding:2px 6px;" data-action="edit-dipendente" data-parent-id="${escAttr(az.id)}" data-id="${escAttr(d.id)}" aria-label="Modifica dipendente ${escH(d.nome)}">✏️</button>
          <button class="btn btn-outline" type="button" style="font-size:11px;padding:2px 6px;color:#E53935;border-color:#E53935;" data-action="delete-dipendente" data-parent-id="${escAttr(az.id)}" data-id="${escAttr(d.id)}" aria-label="Elimina dipendente ${escH(d.nome)}">🗑️</button>
        </td></tr>`).join('') + '</tbody></table>';
  } else {
    dipHtml = '<p style="color:#aaa;font-size:13px;">Nessun dipendente registrato.</p>';
  }

  document.getElementById('detailContent').innerHTML = `
    <div style="margin-bottom:14px;">
      <span class="settore-badge" style="display:inline-block;padding:3px 12px;border-radius:10px;font-size:12px;background:#e3f2fd;color:#1565C0;font-weight:600;">${escH(az.settore)}</span>
    </div>
    <div style="font-size:13px;color:#555;line-height:1.8;">
      📋 <strong>P.IVA:</strong> ${escH(az.piva || '–')}<br>
      📍 <strong>Sede:</strong> ${escH(az.indirizzo || '–')}<br>
      📞 <strong>Tel:</strong> ${escH(az.telefono || '–')}<br>
      ✉️ <strong>Email:</strong> ${escH(az.email || '–')}<br>
      ${az.bando ? `📄 <strong>Bando:</strong> ${escH(az.bando)}<br>` : ''}
      ${az.scadenza ? `📅 <strong>Scadenza contratto:</strong> ${formatDate(az.scadenza)}<br>` : ''}
    </div>
    <div style="display:flex;gap:20px;margin:16px 0;padding:14px;background:#f4f7fb;border-radius:10px;">
      <div style="flex:1;text-align:center;"><span style="font-size:12px;color:#888;">Costo Mensile</span><br><strong style="font-size:20px;color:#1E4E8C;">€ ${(az.costoMensile||0).toLocaleString('it-IT')}</strong></div>
      <div style="flex:1;text-align:center;"><span style="font-size:12px;color:#888;">Costo Annuo</span><br><strong style="font-size:20px;color:#1E4E8C;">€ ${(az.costoAnnuo||0).toLocaleString('it-IT')}</strong></div>
    </div>
    <div style="display:flex;align-items:center;justify-content:space-between;margin-top:18px;">
      <h3 style="font-size:16px;color:#1E4E8C;">👥 Dipendenti (${az.dipendenti ? az.dipendenti.length : 0})</h3>
      <button class="btn btn-primary" type="button" style="font-size:12px;" data-action="add-dipendente" data-id="${escAttr(az.id)}">+ Aggiungi</button>
    </div>
    ${dipHtml}
    <div style="margin-top:16px;display:flex;gap:8px;">
      <button class="btn btn-outline" type="button" data-action="export-dip-xls" data-id="${escAttr(az.id)}">📥 Esporta dipendenti Excel</button>
      <button class="btn btn-outline" type="button" data-action="export-dip-pdf" data-id="${escAttr(az.id)}">📄 Esporta dipendenti PDF</button>
    </div>
  `;
  document.getElementById('detailActions').innerHTML = `
    <button class="btn btn-outline" type="button" data-action="edit-azienda-close" data-id="${escAttr(az.id)}">✏️ Modifica azienda</button>
    <button class="btn btn-outline" type="button" style="color:#E53935;border-color:#E53935;" data-action="delete-azienda" data-id="${escAttr(az.id)}">🗑️ Elimina</button>
  `;
    document.getElementById('detailPanel').classList.add('open');
  } catch (error) {
    showError('Impossibile aprire il dettaglio azienda.', error);
  }
}
function closeDetail() { document.getElementById('detailPanel').classList.remove('open'); }

// ---------- Dipendente CRUD ----------
function openDipendenteModal(azId) {
  document.getElementById('dipModalTitle').textContent = 'Nuovo Dipendente';
  document.getElementById('dipAziendaId').value = azId;
  document.getElementById('editDipId').value = '';
  ['dipNome','dipCF','dipRuolo','dipTelefono','dipEmail','dipAssunzione'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('dipendenteModal').classList.add('open');
}
function closeDipendenteModal() { document.getElementById('dipendenteModal').classList.remove('open'); }

async function editDipendente(azId, dipId) {
  try {
    const dipendenti = await listDipendentiAzienda(azId);
    const dip = dipendenti.find(d => d.id === dipId);
    if (!dip) return;
    document.getElementById('dipModalTitle').textContent = 'Modifica Dipendente';
    document.getElementById('dipAziendaId').value = azId;
    document.getElementById('editDipId').value = dipId;
    document.getElementById('dipNome').value = dip.nome || '';
    document.getElementById('dipCF').value = dip.cf || '';
    document.getElementById('dipRuolo').value = dip.ruolo || '';
    document.getElementById('dipTelefono').value = dip.telefono || '';
    document.getElementById('dipEmail').value = dip.email || '';
    document.getElementById('dipAssunzione').value = dip.assunzione || '';
    document.getElementById('dipendenteModal').classList.add('open');
  } catch (error) {
    showError('Impossibile caricare i dati del dipendente.', error);
  }
}

async function saveDipendente() {
  return runGuarded('saveDipendente', async () => {
    const azId = document.getElementById('dipAziendaId').value;
    const nome = document.getElementById('dipNome').value.trim();
    if (!nome) { alert('Inserire nome e cognome'); return; }

    const cf = document.getElementById('dipCF').value.trim().toUpperCase();
    if (cf && !isValidCf(cf)) {
      alert('Il codice fiscale deve avere 16 caratteri alfanumerici.');
      return;
    }

    const email = document.getElementById('dipEmail').value.trim();
    if (email && !isValidEmail(email)) {
      alert('Inserire una email valida per il dipendente.');
      return;
    }

    const editId = document.getElementById('editDipId').value;
    const data = {
      nome,
      cf,
      ruolo: document.getElementById('dipRuolo').value.trim(),
      telefono: document.getElementById('dipTelefono').value.trim(),
      email,
      assunzione: document.getElementById('dipAssunzione').value
    };
    if (editId) data.id = editId;
    await saveDipendenteFirestore(azId, data);
    closeDipendenteModal();
    await renderAziende();
    await openAziendaDetail(azId);
  }, 'Impossibile salvare il dipendente. Riprova.');
}

async function deleteDipendente(azId, dipId) {
  if (!confirm('Eliminare questo dipendente?')) return;
  return runGuarded('deleteDipendente', async () => {
    await deleteDipendenteFirestore(azId, dipId);
    await renderAziende();
    await openAziendaDetail(azId);
  }, 'Impossibile eliminare il dipendente. Riprova.');
}

// ---------- Export PDF ----------
async function exportAziendePDF() {
  return runGuarded('exportAziendePDF', async () => {
    const aziende = await loadAziende();
    if (aziende.length === 0) { alert('Nessuna azienda da esportare'); return; }
    let content = 'ELENCO AZIENDE E SOCIETÀ\\n\\n';
    aziende.forEach(a => {
      content += `${a.ragioneSociale} (${a.settore})\\n`;
      content += `P.IVA: ${a.piva || '–'} | Tel: ${a.telefono || '–'}\\n`;
      content += `Costo mensile: € ${(a.costoMensile||0).toLocaleString('it-IT')} | Annuo: € ${(a.costoAnnuo||0).toLocaleString('it-IT')}\\n`;
      content += `Dipendenti: ${(a.dipendenti||[]).length}\\n\\n`;
    });
    downloadTextFile(content, 'aziende_export.txt');
  }, 'Impossibile esportare le aziende.');
}

async function exportDipendentiPDF(azId) {
  return runGuarded('exportDipendentiPDF', async () => {
    const aziende = await loadAziende();
    const az = aziende.find(a => a.id === azId);
    if (!az || !az.dipendenti || az.dipendenti.length === 0) { alert('Nessun dipendente'); return; }
    let content = `DIPENDENTI – ${az.ragioneSociale}\\n\\n`;
    az.dipendenti.forEach(d => {
      content += `${d.nome} | CF: ${d.cf || '–'} | Ruolo: ${d.ruolo || '–'} | Tel: ${d.telefono || '–'} | Dal: ${formatDate(d.assunzione)}\\n`;
    });
    downloadTextFile(content, `dipendenti_${az.ragioneSociale.replace(/\s+/g,'_')}.txt`);
  }, 'Impossibile esportare i dipendenti.');
}

// ---------- Export Excel (CSV) ----------
async function exportAziendeExcel() {
  return runGuarded('exportAziendeExcel', async () => {
    const aziende = await loadAziende();
    if (aziende.length === 0) { alert('Nessuna azienda da esportare'); return; }
    let csv = 'Ragione Sociale;Settore;P.IVA;Indirizzo;Telefono;Email;Costo Mensile;Costo Annuo;Bando;Scadenza;N.Dipendenti\\n';
    aziende.forEach(a => {
      csv += `"${a.ragioneSociale}";"${a.settore}";"${a.piva||''}";"${a.indirizzo||''}";"${a.telefono||''}";"${a.email||''}";"${a.costoMensile||0}";"${a.costoAnnuo||0}";"${a.bando||''}";"${a.scadenza||''}";"${(a.dipendenti||[]).length}"\\n`;
    });
    downloadCSV(csv, 'aziende_export.csv');
  }, 'Impossibile esportare le aziende in Excel.');
}

async function exportDipendentiExcel(azId) {
  return runGuarded('exportDipendentiExcel', async () => {
    const aziende = await loadAziende();
    const az = aziende.find(a => a.id === azId);
    if (!az || !az.dipendenti || az.dipendenti.length === 0) { alert('Nessun dipendente'); return; }
    let csv = 'Nome;Codice Fiscale;Ruolo;Telefono;Email;Data Assunzione\\n';
    az.dipendenti.forEach(d => {
      csv += `"${d.nome}";"${d.cf||''}";"${d.ruolo||''}";"${d.telefono||''}";"${d.email||''}";"${d.assunzione||''}"\\n`;
    });
    downloadCSV(csv, `dipendenti_${az.ragioneSociale.replace(/\s+/g,'_')}.csv`);
  }, 'Impossibile esportare i dipendenti in Excel.');
}

function downloadCSV(content, filename) {
  const BOM = '\\uFEFF';
  const blob = new Blob([BOM + content], { type: 'text/csv;charset=utf-8;' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function downloadTextFile(content, filename) {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8;' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.click();
  URL.revokeObjectURL(a.href);
}

function bindIfPresent(elementId, eventName, handler) {
  const el = document.getElementById(elementId);
  if (el) el.addEventListener(eventName, handler);
}

function handleDelegatedAction(event) {
  const actionEl = event.target.closest('[data-action]');
  if (!actionEl) return;

  const action = actionEl.getAttribute('data-action');
  const id = actionEl.getAttribute('data-id');
  const parentId = actionEl.getAttribute('data-parent-id');

  switch (action) {
    case 'open-detail':
      openAziendaDetail(id);
      break;
    case 'edit-azienda':
      editAzienda(id);
      break;
    case 'edit-azienda-close':
      editAzienda(id);
      closeDetail();
      break;
    case 'delete-azienda':
      deleteAzienda(id);
      break;
    case 'add-dipendente':
      openDipendenteModal(id);
      break;
    case 'edit-dipendente':
      editDipendente(parentId, id);
      break;
    case 'delete-dipendente':
      deleteDipendente(parentId, id);
      break;
    case 'export-dip-xls':
      exportDipendentiExcel(id);
      break;
    case 'export-dip-pdf':
      exportDipendentiPDF(id);
      break;
    default:
      break;
  }
}

function initUIBindings() {
  bindIfPresent('logoutLink', 'click', event => {
    event.preventDefault();
    if (typeof civicosLogout === 'function') civicosLogout();
  });

  bindIfPresent('serviceToggle', 'change', toggleSection);
  bindIfPresent('newAziendaBtn', 'click', openAziendaModal);
  bindIfPresent('exportAziendeExcelBtn', 'click', exportAziendeExcel);
  bindIfPresent('exportAziendePDFBtn', 'click', exportAziendePDF);

  bindIfPresent('closeAziendaModalBtn', 'click', closeAziendaModal);
  bindIfPresent('cancelAziendaBtn', 'click', closeAziendaModal);
  bindIfPresent('saveAziendaBtn', 'click', saveAzienda);

  bindIfPresent('closeDipendenteModalBtn', 'click', closeDipendenteModal);
  bindIfPresent('cancelDipendenteBtn', 'click', closeDipendenteModal);
  bindIfPresent('saveDipendenteBtn', 'click', saveDipendente);

  bindIfPresent('closeDetailBtn', 'click', closeDetail);

  bindIfPresent('filterSettore', 'change', () => scheduleRenderAziende(0));
  bindIfPresent('filterSearch', 'input', () => scheduleRenderAziende(250));

  document.addEventListener('click', handleDelegatedAction);
}

// ---------- Init ----------
initUIBindings();
initAziendeSectionConfig();
renderAziende();
