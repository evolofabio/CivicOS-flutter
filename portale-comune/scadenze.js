// ============================================================
// CivicOS – Scadenze Comunali (JS) – Firestore
// ============================================================

var scadenzeCache = [];
var scadenzeSectionConfig = { attivo: false };
var _scadenzeUnsub = null;

function loadScadenze() { return scadenzeCache.slice(); }
function loadSectionConfig() { return Object.assign({}, scadenzeSectionConfig); }
function saveSectionConfig(cfg) {
  scadenzeSectionConfig = Object.assign({}, cfg);
  civicosSaveSectionConfig('scadenze', scadenzeSectionConfig);
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
  document.getElementById('serviceToggle').checked = cfg.attivo;
  const content = document.getElementById('sectionContent');
  if (cfg.attivo) {
    document.getElementById('serviceIcon').style.color = '#2E7D32';
    document.getElementById('serviceStatusLabel').textContent = 'Sezione attiva';
    document.getElementById('servicePeriodLabel').textContent = 'Gestione scadenze comunali abilitata';
    content.classList.remove('service-disabled-overlay');
  } else {
    document.getElementById('serviceIcon').style.color = '#E53935';
    document.getElementById('serviceStatusLabel').textContent = 'Sezione disattivata';
    document.getElementById('servicePeriodLabel').textContent = 'Attiva per gestire scadenze, bandi e utenze comunali';
    content.classList.add('service-disabled-overlay');
  }
}

// ---------- Helpers ----------
function escH(str) { const d = document.createElement('div'); d.textContent = str; return d.innerHTML; }
function formatDate(d) { if (!d) return '–'; const p = d.split('-'); return p.length === 3 ? `${p[2]}/${p[1]}/${p[0]}` : d; }

function getStato(dataStr) {
  if (!dataStr) return 'attiva';
  const now = new Date();
  const scad = new Date(dataStr);
  const diff = (scad - now) / (1000 * 60 * 60 * 24);
  if (diff < 0) return 'scaduta';
  if (diff <= 30) return 'prossima';
  return 'attiva';
}
function statoBadge(stato) {
  if (stato === 'scaduta') return '<span class="badge-scaduta">Scaduta</span>';
  if (stato === 'prossima') return '<span class="badge-prossima">In scadenza</span>';
  return '<span class="badge-attiva">Attiva</span>';
}

async function initScadenzePage() {
  scadenzeSectionConfig = await civicosLoadSectionConfig('scadenze', { attivo: false });
  refreshSectionUI();
  if (_scadenzeUnsub) _scadenzeUnsub();
  _scadenzeUnsub = civicosListenCollection('scadenze', function(rows) {
    scadenzeCache = rows;
    renderScadenze();
  }, 'data');
}

// ---------- Render ----------
function renderScadenze() {
  const scadenze = loadScadenze();
  const fCat = document.getElementById('filterCategoria').value;
  const fStato = document.getElementById('filterStato').value;
  const fSearch = document.getElementById('filterSearch').value.toLowerCase();

  let filtered = scadenze;
  if (fCat) filtered = filtered.filter(s => s.categoria === fCat);
  if (fStato) filtered = filtered.filter(s => getStato(s.data) === fStato);
  if (fSearch) filtered = filtered.filter(s =>
    (s.descrizione + ' ' + s.fornitore + ' ' + s.protocollo).toLowerCase().includes(fSearch)
  );

  // Stats
  const prossime = scadenze.filter(s => getStato(s.data) === 'prossima').length;
  const scadute = scadenze.filter(s => getStato(s.data) === 'scaduta').length;
  const costoTot = scadenze.reduce((s, x) => s + (x.costoAnnuo || 0), 0);
  document.getElementById('statTotale').textContent = scadenze.length;
  document.getElementById('statProssime').textContent = prossime;
  document.getElementById('statScadute').textContent = scadute;
  document.getElementById('statCostoTotale').textContent = '€ ' + costoTot.toLocaleString('it-IT');

  // Sort by date (nearest first)
  filtered.sort((a, b) => {
    if (!a.data) return 1;
    if (!b.data) return -1;
    return new Date(a.data) - new Date(b.data);
  });

  document.getElementById('scadenzeBody').innerHTML = filtered.map(s => {
    const stato = getStato(s.data);
    return `<tr>
      <td><strong>${escH(s.descrizione)}</strong>${s.protocollo ? `<br><span style="font-size:11px;color:#888;">${escH(s.protocollo)}</span>` : ''}</td>
      <td>${escH(s.categoria)}</td>
      <td>${escH(s.fornitore || '–')}</td>
      <td>${formatDate(s.data)}</td>
      <td>${statoBadge(stato)}</td>
      <td style="text-align:right;">€ ${(s.costoAnnuo||0).toLocaleString('it-IT')}${s.costoMensile ? `<br><span style="font-size:11px;color:#888;">€ ${s.costoMensile.toLocaleString('it-IT')}/mese</span>` : ''}</td>
      <td style="max-width:160px;font-size:12px;color:#666;">${escH(s.note || '–')}</td>
      <td>
        <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;" onclick="editScadenza('${s.id}')">✏️</button>
        <button class="btn btn-outline" style="font-size:11px;padding:3px 8px;color:#E53935;border-color:#E53935;" onclick="deleteScadenza('${s.id}')">🗑️</button>
      </td>
    </tr>`;
  }).join('') || '<tr><td colspan="8" style="color:#888;text-align:center;">Nessuna scadenza trovata.</td></tr>';
}

// ---------- CRUD ----------
function openScadenzaModal() {
  document.getElementById('scadenzaModalTitle').textContent = 'Nuova Scadenza';
  document.getElementById('editScadenzaId').value = '';
  ['scDescrizione','scFornitore','scData','scCostoMensile','scCostoAnnuo','scProtocollo','scNote'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
  document.getElementById('scCategoria').value = 'Bando';
  document.getElementById('scadenzaModal').classList.add('open');
}
function closeScadenzaModal() { document.getElementById('scadenzaModal').classList.remove('open'); }

function editScadenza(id) {
  const s = loadScadenze().find(x => x.id === id);
  if (!s) return;
  document.getElementById('scadenzaModalTitle').textContent = 'Modifica Scadenza';
  document.getElementById('editScadenzaId').value = id;
  document.getElementById('scDescrizione').value = s.descrizione || '';
  document.getElementById('scCategoria').value = s.categoria || 'Bando';
  document.getElementById('scFornitore').value = s.fornitore || '';
  document.getElementById('scData').value = s.data || '';
  document.getElementById('scCostoMensile').value = s.costoMensile || '';
  document.getElementById('scCostoAnnuo').value = s.costoAnnuo || '';
  document.getElementById('scProtocollo').value = s.protocollo || '';
  document.getElementById('scNote').value = s.note || '';
  document.getElementById('scadenzaModal').classList.add('open');
}

async function saveScadenza() {
  const desc = document.getElementById('scDescrizione').value.trim();
  if (!desc) { alert('Inserire la descrizione'); return; }
  const editId = document.getElementById('editScadenzaId').value;
  const data = {
    descrizione: desc,
    categoria: document.getElementById('scCategoria').value,
    fornitore: document.getElementById('scFornitore').value.trim(),
    data: document.getElementById('scData').value,
    costoMensile: parseFloat(document.getElementById('scCostoMensile').value) || 0,
    costoAnnuo: parseFloat(document.getElementById('scCostoAnnuo').value) || 0,
    protocollo: document.getElementById('scProtocollo').value.trim(),
    note: document.getElementById('scNote').value.trim()
  };
  try {
    await civicosSaveDoc('scadenze', editId || null, data);
    closeScadenzaModal();
  } catch (e) {
    alert('Errore salvataggio scadenza');
    console.error(e);
  }
}

async function deleteScadenza(id) {
  if (!confirm('Eliminare questa scadenza?')) return;
  try {
    await civicosDeleteDoc('scadenze', id);
    renderScadenze();
  } catch (e) {
    alert('Errore eliminazione scadenza');
    console.error(e);
  }
}

// ---------- Export ----------
function exportExcel() {
  const scadenze = loadScadenze();
  if (!scadenze.length) { alert('Nessuna scadenza'); return; }
  let csv = 'Descrizione;Categoria;Fornitore;Scadenza;Stato;Costo Mensile;Costo Annuo;Protocollo;Note\n';
  scadenze.forEach(s => {
    csv += `"${s.descrizione}";"${s.categoria}";"${s.fornitore||''}";"${s.data||''}";"${getStato(s.data)}";"${s.costoMensile||0}";"${s.costoAnnuo||0}";"${s.protocollo||''}";"${s.note||''}"\n`;
  });
  downloadCSV(csv, 'scadenze_comunali.csv');
}
function exportPDF() {
  const scadenze = loadScadenze();
  if (!scadenze.length) { alert('Nessuna scadenza'); return; }
  let txt = 'SCADENZE COMUNALI\n\n';
  scadenze.forEach(s => {
    txt += `${s.descrizione} | ${s.categoria} | Fornitore: ${s.fornitore||'–'} | Scadenza: ${formatDate(s.data)} | Costo annuo: € ${(s.costoAnnuo||0).toLocaleString('it-IT')}\n`;
  });
  downloadTextFile(txt, 'scadenze_comunali.txt');
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

// ---------- Filters ----------
document.getElementById('filterCategoria').addEventListener('change', renderScadenze);
document.getElementById('filterStato').addEventListener('change', renderScadenze);
document.getElementById('filterSearch').addEventListener('input', renderScadenze);

// ---------- Init ----------
initScadenzePage();
