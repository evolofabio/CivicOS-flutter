// ============================================================
// CivicOS – Mezzi e Dipendenti Comunali (JS) – Firestore
// ============================================================

var mezziCache = [];
var dipComunaliCache = [];
var mezziSectionConfig = { attivo: false };
var _mezziUnsubs = [];

function loadMezzi() { return mezziCache.slice(); }
function loadDipComunali() { return dipComunaliCache.slice(); }
function loadSectionConfig() { return Object.assign({}, mezziSectionConfig); }
function saveSectionConfig(cfg) {
  mezziSectionConfig = Object.assign({}, cfg);
  civicosSaveSectionConfig('mezzi', mezziSectionConfig);
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
    icon.style.color = '#2E7D32'; label.textContent = 'Sezione attiva';
    plabel.textContent = 'Gestione mezzi e dipendenti comunali abilitata';
    content.classList.remove('service-disabled-overlay');
  } else {
    icon.style.color = '#E53935'; label.textContent = 'Sezione disattivata';
    plabel.textContent = 'Attiva questa sezione per gestire mezzi e dipendenti comunali';
    content.classList.add('service-disabled-overlay');
  }
}

// ---------- Tabs ----------
function switchTab(tab) {
  document.getElementById('panelMezzi').style.display = tab === 'mezzi' ? '' : 'none';
  document.getElementById('panelDipendenti').style.display = tab === 'dipendenti' ? '' : 'none';
  document.getElementById('tabMezzi').classList.toggle('active', tab === 'mezzi');
  document.getElementById('tabDipendenti').classList.toggle('active', tab === 'dipendenti');
}

// ---------- Firestore init ----------
async function initMezziPage() {
  mezziSectionConfig = await civicosLoadSectionConfig('mezzi', { attivo: false });
  refreshSectionUI();
  _mezziUnsubs.forEach(function(u) { if (u) u(); });
  _mezziUnsubs = [
    civicosListenCollection('mezzi', function(rows) {
      mezziCache = rows;
      renderMezzi();
    }, 'targa'),
    civicosListenCollection('dipendenti_comunali', function(rows) {
      dipComunaliCache = rows;
      renderDipComunali();
    }, 'nome')
  ];
}

function escH(str) { const d = document.createElement('div'); d.textContent = str; return d.innerHTML; }
function formatDate(d) { if (!d) return '–'; const p = d.split('-'); return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : d; }
function statusClass(s) {
  if (s === 'Operativo') return 'status-operativo';
  if (s === 'In manutenzione') return 'status-manutenzione';
  return 'status-fuori';
}

// ---------- Render Mezzi ----------
function renderMezzi() {
  const mezzi = loadMezzi();
  const fTipo = document.getElementById('filterTipoMezzo').value;
  const fStato = document.getElementById('filterStatoMezzo').value;
  const fSearch = document.getElementById('filterSearchMezzo').value.toLowerCase();
  let filtered = mezzi;
  if (fTipo) filtered = filtered.filter(m => m.tipo === fTipo);
  if (fStato) filtered = filtered.filter(m => m.stato === fStato);
  if (fSearch) filtered = filtered.filter(m => (m.targa+' '+m.marca+' '+m.modello+' '+m.assegnato).toLowerCase().includes(fSearch));

  document.getElementById('statMezzi').textContent = mezzi.length;
  document.getElementById('statOperativi').textContent = mezzi.filter(m => m.stato === 'Operativo').length;
  document.getElementById('statManutenzione').textContent = mezzi.filter(m => m.stato === 'In manutenzione').length;
  document.getElementById('statFuoriServizio').textContent = mezzi.filter(m => m.stato === 'Fuori servizio').length;

  document.getElementById('mezziBody').innerHTML = filtered.map(m => `<tr>
    <td><strong>${escH(m.targa)}</strong></td>
    <td>${escH(m.tipo)}</td>
    <td>${escH(m.marca)} ${escH(m.modello)}</td>
    <td>${escH(m.assegnato || '–')}</td>
    <td><span class="${statusClass(m.stato)}">${escH(m.stato)}</span></td>
    <td>${formatDate(m.revisione)}</td>
    <td>${formatDate(m.assicurazione)}</td>
    <td>
      <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;" onclick="editMezzo('${m.id}')">✏️</button>
      <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;color:#E53935;border-color:#E53935;" onclick="deleteMezzo('${m.id}')">🗑️</button>
    </td>
  </tr>`).join('') || '<tr><td colspan="8" style="color:#888;text-align:center;">Nessun mezzo trovato.</td></tr>';
}

// ---------- Render Dipendenti Comunali ----------
function renderDipComunali() {
  const dips = loadDipComunali();
  const fCat = document.getElementById('filterCategoria').value;
  const fSearch = document.getElementById('filterSearchDip').value.toLowerCase();
  let filtered = dips;
  if (fCat) filtered = filtered.filter(d => d.categoria === fCat);
  if (fSearch) filtered = filtered.filter(d => (d.nome+' '+d.cf+' '+d.ufficio).toLowerCase().includes(fSearch));

  document.getElementById('statDipCom').textContent = dips.length;
  document.getElementById('statInServizio').textContent = dips.length;
  const cats = new Set(dips.map(d => d.categoria));
  document.getElementById('statCategorie').textContent = cats.size;

  document.getElementById('dipComunaliBody').innerHTML = filtered.map(d => `<tr>
    <td><strong>${escH(d.nome)}</strong></td>
    <td>${escH(d.cf || '–')}</td>
    <td>${escH(d.categoria)}</td>
    <td>${escH(d.ufficio || '–')}</td>
    <td>${escH(d.telefono || '–')}</td>
    <td>${escH(d.email || '–')}</td>
    <td>${formatDate(d.assunzione)}</td>
    <td>
      <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;" onclick="editDipComunale('${d.id}')">✏️</button>
      <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;color:#E53935;border-color:#E53935;" onclick="deleteDipComunale('${d.id}')">🗑️</button>
    </td>
  </tr>`).join('') || '<tr><td colspan="8" style="color:#888;text-align:center;">Nessun dipendente trovato.</td></tr>';
}

// ---------- Mezzo CRUD ----------
function openMezzoModal() {
  document.getElementById('mezzoModalTitle').textContent = 'Nuovo Mezzo';
  document.getElementById('editMezzoId').value = '';
  ['mzTarga','mzMarca','mzModello','mzAssegnato','mzRevisione','mzAssicurazione','mzNote'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  document.getElementById('mzTipo').value = 'Autocarro';
  document.getElementById('mzStato').value = 'Operativo';
  document.getElementById('mezzoModal').classList.add('open');
}
function closeMezzoModal() { document.getElementById('mezzoModal').classList.remove('open'); }

function editMezzo(id) {
  const m = loadMezzi().find(x => x.id === id);
  if (!m) return;
  document.getElementById('mezzoModalTitle').textContent = 'Modifica Mezzo';
  document.getElementById('editMezzoId').value = id;
  document.getElementById('mzTarga').value = m.targa || '';
  document.getElementById('mzTipo').value = m.tipo || 'Autocarro';
  document.getElementById('mzMarca').value = m.marca || '';
  document.getElementById('mzModello').value = m.modello || '';
  document.getElementById('mzAssegnato').value = m.assegnato || '';
  document.getElementById('mzStato').value = m.stato || 'Operativo';
  document.getElementById('mzRevisione').value = m.revisione || '';
  document.getElementById('mzAssicurazione').value = m.assicurazione || '';
  document.getElementById('mzNote').value = m.note || '';
  document.getElementById('mezzoModal').classList.add('open');
}

async function saveMezzo() {
  const targa = document.getElementById('mzTarga').value.trim();
  if (!targa) { alert('Inserire la targa'); return; }
  const editId = document.getElementById('editMezzoId').value;
  const data = {
    targa, tipo: document.getElementById('mzTipo').value,
    marca: document.getElementById('mzMarca').value.trim(),
    modello: document.getElementById('mzModello').value.trim(),
    assegnato: document.getElementById('mzAssegnato').value.trim(),
    stato: document.getElementById('mzStato').value,
    revisione: document.getElementById('mzRevisione').value,
    assicurazione: document.getElementById('mzAssicurazione').value,
    note: document.getElementById('mzNote').value.trim()
  };
  try {
    await civicosSaveDoc('mezzi', editId || null, data);
    closeMezzoModal();
  } catch (e) {
    alert('Errore salvataggio mezzo');
    console.error(e);
  }
}

async function deleteMezzo(id) {
  if (!confirm('Eliminare questo mezzo?')) return;
  try {
    await civicosDeleteDoc('mezzi', id);
    renderMezzi();
  } catch (e) {
    alert('Errore eliminazione mezzo');
    console.error(e);
  }
}

// ---------- Dipendente Comunale CRUD ----------
function openDipComunaleModal() {
  document.getElementById('dipComModalTitle').textContent = 'Nuovo Dipendente';
  document.getElementById('editDipComId').value = '';
  ['dcNome','dcCF','dcUfficio','dcTelefono','dcEmail','dcAssunzione','dcNote'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  document.getElementById('dcCategoria').value = 'Amministrativo';
  document.getElementById('dipComunaleModal').classList.add('open');
}
function closeDipComunaleModal() { document.getElementById('dipComunaleModal').classList.remove('open'); }

function editDipComunale(id) {
  const d = loadDipComunali().find(x => x.id === id);
  if (!d) return;
  document.getElementById('dipComModalTitle').textContent = 'Modifica Dipendente';
  document.getElementById('editDipComId').value = id;
  document.getElementById('dcNome').value = d.nome || '';
  document.getElementById('dcCF').value = d.cf || '';
  document.getElementById('dcCategoria').value = d.categoria || 'Amministrativo';
  document.getElementById('dcUfficio').value = d.ufficio || '';
  document.getElementById('dcTelefono').value = d.telefono || '';
  document.getElementById('dcEmail').value = d.email || '';
  document.getElementById('dcAssunzione').value = d.assunzione || '';
  document.getElementById('dcNote').value = d.note || '';
  document.getElementById('dipComunaleModal').classList.add('open');
}

async function saveDipComunale() {
  const nome = document.getElementById('dcNome').value.trim();
  if (!nome) { alert('Inserire nome e cognome'); return; }
  const editId = document.getElementById('editDipComId').value;
  const data = {
    nome, cf: document.getElementById('dcCF').value.trim(),
    categoria: document.getElementById('dcCategoria').value,
    ufficio: document.getElementById('dcUfficio').value.trim(),
    telefono: document.getElementById('dcTelefono').value.trim(),
    email: document.getElementById('dcEmail').value.trim(),
    assunzione: document.getElementById('dcAssunzione').value,
    note: document.getElementById('dcNote').value.trim()
  };
  try {
    await civicosSaveDoc('dipendenti_comunali', editId || null, data);
    closeDipComunaleModal();
  } catch (e) {
    alert('Errore salvataggio dipendente');
    console.error(e);
  }
}

async function deleteDipComunale(id) {
  if (!confirm('Eliminare questo dipendente?')) return;
  try {
    await civicosDeleteDoc('dipendenti_comunali', id);
    renderDipComunali();
  } catch (e) {
    alert('Errore eliminazione dipendente');
    console.error(e);
  }
}

// ---------- Export ----------
function exportMezziExcel() {
  const mezzi = loadMezzi();
  if (!mezzi.length) { alert('Nessun mezzo'); return; }
  let csv = 'Targa;Tipo;Marca;Modello;Assegnato;Stato;Revisione;Assicurazione;Note\n';
  mezzi.forEach(m => {
    csv += `"${m.targa}";"${m.tipo}";"${m.marca}";"${m.modello}";"${m.assegnato||''}";"${m.stato}";"${m.revisione||''}";"${m.assicurazione||''}";"${m.note||''}"\n`;
  });
  downloadCSV(csv, 'mezzi_comunali.csv');
}
function exportMezziPDF() {
  const mezzi = loadMezzi();
  if (!mezzi.length) { alert('Nessun mezzo'); return; }
  let txt = 'MEZZI COMUNALI\n\n';
  mezzi.forEach(m => { txt += `${m.targa} | ${m.tipo} | ${m.marca} ${m.modello} | ${m.stato} | Assegnato: ${m.assegnato||'–'}\n`; });
  downloadTextFile(txt, 'mezzi_comunali.txt');
}
function exportDipComunaliExcel() {
  const dips = loadDipComunali();
  if (!dips.length) { alert('Nessun dipendente'); return; }
  let csv = 'Nome;Codice Fiscale;Categoria;Ufficio;Telefono;Email;Data Assunzione;Note\n';
  dips.forEach(d => {
    csv += `"${d.nome}";"${d.cf||''}";"${d.categoria}";"${d.ufficio||''}";"${d.telefono||''}";"${d.email||''}";"${d.assunzione||''}";"${d.note||''}"\n`;
  });
  downloadCSV(csv, 'dipendenti_comunali.csv');
}
function exportDipComunaliPDF() {
  const dips = loadDipComunali();
  if (!dips.length) { alert('Nessun dipendente'); return; }
  let txt = 'DIPENDENTI COMUNALI\n\n';
  dips.forEach(d => { txt += `${d.nome} | CF: ${d.cf||'–'} | ${d.categoria} | ${d.ufficio||'–'} | Tel: ${d.telefono||'–'}\n`; });
  downloadTextFile(txt, 'dipendenti_comunali.txt');
}

function downloadCSV(content, filename) {
  const BOM = '\uFEFF';
  const blob = new Blob([BOM + content], { type: 'text/csv;charset=utf-8;' });
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = filename; a.click(); URL.revokeObjectURL(a.href);
}
function downloadTextFile(content, filename) {
  const blob = new Blob([content], { type: 'text/plain;charset=utf-8;' });
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = filename; a.click(); URL.revokeObjectURL(a.href);
}

// ---------- Filter listeners ----------
document.getElementById('filterTipoMezzo').addEventListener('change', renderMezzi);
document.getElementById('filterStatoMezzo').addEventListener('change', renderMezzi);
document.getElementById('filterSearchMezzo').addEventListener('input', renderMezzi);
document.getElementById('filterCategoria').addEventListener('change', renderDipComunali);
document.getElementById('filterSearchDip').addEventListener('input', renderDipComunali);

// ---------- Init ----------
initMezziPage();
