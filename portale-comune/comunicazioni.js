/* ── Comunicazioni – Operator Page Logic (per-comune) ── */

// ── Per-comune scoped data ──────────────────────────────────

let comunicazioni = [];
let currentPostId = null;
let uploadedFiles = [];
let selectedPriority = 'normale';
let comuneFrazioni = []; // frazioni del comune corrente

async function ensureFirebaseReady() {
  if (typeof window.civicosEnsureFirebaseSession === 'function') {
    await window.civicosEnsureFirebaseSession();
  }
}

// Carica frazioni del comune corrente (da Firestore o da localStorage config)
async function loadFrazioniComune() {
  await ensureFirebaseReady();
  // Prima prova da Firestore
  try {
    const doc = await comuneRef.get();
    if (doc.exists) {
      const data = doc.data();
      if (data.frazioni && data.frazioni.length > 0) {
        comuneFrazioni = data.frazioni;
        renderFrazioniSelector();
        return;
      }
    }
  } catch(e) {}

  // Fallback a localStorage config
  try {
    const auth = JSON.parse(sessionStorage.getItem('civicos_auth') || '{}');
    const comuneNome = auth.comune;
    const config = JSON.parse(localStorage.getItem('civicos_comuni_config') || '{}');
    if (config[comuneNome] && config[comuneNome].frazioni && config[comuneNome].frazioni.length > 0) {
      comuneFrazioni = config[comuneNome].frazioni;
      renderFrazioniSelector();
      return;
    }
  } catch(e) {}

  comuneFrazioni = [];
  renderFrazioniSelector();
}

function renderFrazioniSelector() {
  const wrap = document.getElementById('frazioniSelectorWrap');
  const empty = document.getElementById('frazioniSelectorEmpty');
  const container = document.getElementById('frazioniCheckboxes');
  if (!wrap || !empty || !container) return;

  if (comuneFrazioni.length === 0) {
    wrap.style.display = 'none';
    empty.style.display = 'block';
    return;
  }
  wrap.style.display = 'block';
  empty.style.display = 'none';
  container.innerHTML = comuneFrazioni.map((f, i) => `
    <label style="display:flex;align-items:center;gap:5px;background:#e3f2fd;border-radius:16px;padding:4px 12px;cursor:pointer;font-size:13px;font-weight:500;color:#1E4E8C;user-select:none;">
      <input type="checkbox" class="frazione-chk" value="${esc(f)}" style="accent-color:#1E4E8C;"> ${esc(f)}
    </label>`).join('');
}

function toggleTutteLeFrazioni() {
  const boxes = document.querySelectorAll('.frazione-chk');
  const anyUnchecked = Array.from(boxes).some(b => !b.checked);
  boxes.forEach(b => { b.checked = anyUnchecked; });
}

function getSelectedFrazioni() {
  const boxes = document.querySelectorAll('.frazione-chk:checked');
  return Array.from(boxes).map(b => b.value);
}

function setSelectedFrazioni(frazioni) {
  document.querySelectorAll('.frazione-chk').forEach(b => {
    b.checked = frazioni.includes(b.value);
  });
}

// Carica comunicazioni da Firestore
async function loadComunicazioni() {
  await ensureFirebaseReady();
  comunicazioni = [];
  let snapshot;
  try {
    snapshot = await comuneRef.collection('comunicazioni').orderBy('dataTs', 'desc').get();
  } catch (e) {
    snapshot = await comuneRef.collection('comunicazioni').orderBy('data', 'desc').get();
  }

  const migrations = [];
  snapshot.forEach(doc => {
    const data = doc.data();
    data.id = doc.id;
    if (!data.allegati) data.allegati = [];
    if (!data.frazioni) data.frazioni = [];
    if (!data.data) data.data = todayISO();
    if (!data.dataTs && data.timestamp) {
      data.dataTs = data.timestamp;
      migrations.push(doc.ref.set({ dataTs: data.timestamp }, { merge: true }));
    }
    comunicazioni.push(data);
  });

  if (migrations.length > 0) {
    Promise.allSettled(migrations).catch(() => {});
  }

  render();
}

// Salva o aggiorna comunicazione su Firestore
async function saveComunicazione(data, isDraft = false) {
  await ensureFirebaseReady();
  const payload = {
    ...data,
    data: data.data || todayISO(),
    dataTs: data.dataTs || firebase.firestore.FieldValue.serverTimestamp(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };

  if (payload.stato === 'attivo' && !payload.publishedAt) {
    payload.publishedAt = firebase.firestore.FieldValue.serverTimestamp();
  }

  if (!data.id) {
    // Nuova comunicazione
    const ref = await comuneRef.collection('comunicazioni').add(payload);
    data.id = ref.id;
  } else {
    // Aggiorna esistente
    await comuneRef.collection('comunicazioni').doc(data.id).set(payload, { merge: true });
  }

  // Se è attiva, aggiorna il documento _notifiche per trigger real-time sull'app
  if (data.stato === 'attivo') {
    await comuneRef.set({
      _lastNotifica: {
        titolo: data.titolo,
        contenuto: data.contenuto || '',
        tipo: data.tipo,
        frazioni: data.frazioni || [],
        timestamp: firebase.firestore.FieldValue.serverTimestamp(),
        docId: data.id
      }
    }, { merge: true });
  }

  await loadComunicazioni();
}

// Cancella comunicazione da Firestore
async function deleteComunicazione(id) {
  await ensureFirebaseReady();
  await comuneRef.collection('comunicazioni').doc(id.toString()).delete();
  await loadComunicazioni();
}

// ── Tipo labels & badges ───────────────────────────────────
const tipoLabel = { servizio: 'Servizio', allerta: 'Allerta', evento: 'Evento', istituzionale: 'Istituzionale' };

function tipoBadge(tipo) {
  return `<span class="post-type-badge badge-${tipo}">${tipoLabel[tipo] || tipo}</span>`;
}

function statoTag(stato) {
  const map = { attivo: '#2E7D32', bozza: '#F57C00', archiviato: '#999' };
  return `<span class="status-tag" style="background:${map[stato]||'#aaa'};color:#fff;padding:3px 8px;border-radius:10px;font-size:11px">${stato}</span>`;
}

// ── Render ──────────────────────────────────────────────────
function render() {
  const list = document.getElementById('postsList');
  const filterTipo = document.getElementById('filterTipo').value;
  const filterStato = document.getElementById('filterStato').value;
  const search = document.getElementById('filterSearch').value.toLowerCase();


  let filtered = comunicazioni.filter(c => {
    if (filterTipo && c.tipo !== filterTipo) return false;
    if (filterStato && c.stato !== filterStato) return false;
    if (search && !c.titolo.toLowerCase().includes(search) && !c.contenuto.toLowerCase().includes(search)) return false;
    return true;
  });

  if (!filtered.length) {
    list.innerHTML = '<div style="text-align:center;padding:40px;color:#999">Nessuna comunicazione trovata</div>';
  } else {
    list.innerHTML = filtered.map(c => {
      const attachCount = c.allegati.length;
      const bodyPreview = c.contenuto.length > 140 ? c.contenuto.substring(0, 140) + '…' : c.contenuto;
      return `
        <div class="post-card tipo-${c.tipo}" onclick="viewPost('${escAttr(c.id)}')">
          <div class="post-header">
            ${tipoBadge(c.tipo)}
            <div class="post-title">${esc(c.titolo)}</div>
            <div class="post-date">${formatDate(c.data)}</div>
          </div>
          <div class="post-body">${esc(bodyPreview)}</div>
          <div class="post-zona" style="color:#1976d2;font-size:13px;margin:4px 0 0 0;">${
            c.frazioni && c.frazioni.length > 0
              ? 'Frazioni: ' + c.frazioni.map(f => `<span style="background:#e3f2fd;border-radius:10px;padding:1px 8px;margin-right:4px;">${esc(f)}</span>`).join('')
              : c.zona ? 'Zona: ' + esc(c.zona) : '<span style="color:#aaa">Tutti i cittadini</span>'
          }</div>
          <div class="post-footer">
            ${attachCount ? `<div class="post-attachments"><span class="attachment-chip">📎 ${attachCount} allegat${attachCount > 1 ? 'i' : 'o'}</span></div>` : ''}
            <span class="post-priority prio-${c.priorita}">${c.priorita.toUpperCase()}</span>
            <div class="post-status">${statoTag(c.stato)}</div>
          </div>
        </div>`;
    }).join('');
  }

  updateStats();
}

// ── Stats ───────────────────────────────────────────────────
function updateStats() {
  document.getElementById('statTotal').textContent = comunicazioni.length;
  document.getElementById('statActive').textContent = comunicazioni.filter(c => c.stato === 'attivo').length;
  document.getElementById('statDraft').textContent = comunicazioni.filter(c => c.stato === 'bozza').length;
  document.getElementById('statArchived').textContent = comunicazioni.filter(c => c.stato === 'archiviato').length;
}

// ── New post ────────────────────────────────────────────────
function openNewPost() {
  currentPostId = null;
  uploadedFiles = [];
  selectedPriority = 'normale';
  document.getElementById('postPanel').classList.add('open');
  document.getElementById('viewPanel').classList.remove('open');
  document.body.classList.add('panel-open');
  document.getElementById('panelTitle').textContent = 'Nuovo avviso';
  document.getElementById('postTitolo').value = '';
  document.getElementById('postTipo').value = 'servizio';
  document.getElementById('postCorpo').value = '';
  document.getElementById('fileList').innerHTML = '';
  document.getElementById('btnDelete').style.display = 'none';
  setPriority('normale');
  document.getElementById('postZona').value = '';
  setSelectedFrazioni([]);
}

// ── Edit existing post ──────────────────────────────────────
function editPost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  currentPostId = id;
  uploadedFiles = [...c.allegati];
  selectedPriority = c.priorita;
  document.getElementById('postPanel').classList.add('open');
  document.getElementById('viewPanel').classList.remove('open');
  document.body.classList.add('panel-open');
  document.getElementById('panelTitle').textContent = 'Modifica avviso';
  document.getElementById('postTitolo').value = c.titolo;
  document.getElementById('postTipo').value = c.tipo;
  document.getElementById('postCorpo').value = c.contenuto;
  document.getElementById('btnDelete').style.display = 'inline-flex';
  setPriority(c.priorita);
  renderFileList();
  document.getElementById('postZona').value = c.zona || '';
  setSelectedFrazioni(c.frazioni || []);
}

// ── View post ───────────────────────────────────────────────
function viewPost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  document.getElementById('viewPanel').classList.add('open');
  document.getElementById('postPanel').classList.remove('open');
  document.body.classList.add('panel-open');

  let html = `
    <div class="view-title">${esc(c.titolo)}</div>
    <div class="view-meta">
      ${tipoBadge(c.tipo)}
      ${statoTag(c.stato)}
      <span style="color:#999;font-size:12px">${formatDate(c.data)}</span>
      <span class="post-priority prio-${c.priorita}">${c.priorita.toUpperCase()}</span>
    </div>
    <div class="view-body">${esc(c.contenuto)}</div>
    ${c.zona ? `<div class=\"view-zona\" style=\"margin:10px 0 0 0;color:#1976d2;font-size:15px;\"><strong>Zona interessata:</strong> ${esc(c.zona)}</div>` : ''}`;

  if (c.allegati.length) {
    html += `<div class="view-attachments"><h4>Allegati</h4>`;
    c.allegati.forEach(a => {
      const icon = a.tipo === 'pdf' ? '📄' : '🖼️';
      html += `<div class="view-file"><span class="file-icon">${icon}</span><span class="file-name">${esc(a.nome)}</span><span class="file-size">${a.dimensione}</span></div>`;
    });
    html += `</div>`;
  }

  document.getElementById('viewContent').innerHTML = html;

  // View actions
  const actions = document.getElementById('viewActions');
  let btns = `<button class="btn btn-primary" onclick="editPost('${escAttr(id)}')">✏️ Modifica</button>`;
  if (c.stato === 'attivo') {
    btns += ` <button class="btn btn-outlined" onclick="archivePost('${escAttr(id)}')">📦 Archivia</button>`;
  } else if (c.stato === 'bozza') {
    btns += ` <button class="btn btn-primary" onclick="quickPublish('${escAttr(id)}')">🚀 Pubblica</button>`;
  } else if (c.stato === 'archiviato') {
    btns += ` <button class="btn btn-outlined" onclick="reactivatePost('${escAttr(id)}')">♻️ Riattiva</button>`;
  }
  actions.innerHTML = btns;
}

// ── Close panels ────────────────────────────────────────────
function closePanel() {
  document.getElementById('postPanel').classList.remove('open');
  document.getElementById('viewPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}
function closeViewPanel() {
  document.getElementById('viewPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}

// ── Priority toggle ─────────────────────────────────────────
function setPriority(p) {
  selectedPriority = p;
  document.querySelectorAll('.prio-btn').forEach(b => {
    b.classList.toggle('active', b.dataset.prio === p);
  });
}

// ── File handling ───────────────────────────────────────────
function handleFiles(files) {
  Array.from(files).forEach(f => {
    const isImage = f.type.startsWith('image/');
    const isPdf = f.type === 'application/pdf';
    if (!isImage && !isPdf) return;
    uploadedFiles.push({
      nome: f.name,
      tipo: isImage ? 'image' : 'pdf',
      dimensione: formatSize(f.size),
      _file: f
    });
  });
  renderFileList();
}

function renderFileList() {
  const container = document.getElementById('fileList');
  if (!uploadedFiles.length) {
    container.innerHTML = '';
    return;
  }
  container.innerHTML = uploadedFiles.map((f, i) => {
    const icon = f.tipo === 'pdf' ? '📄' : '🖼️';
    return `<div class="file-item">
      <span class="file-icon">${icon}</span>
      <span class="file-name">${esc(f.nome)}</span>
      <span class="file-size">${f.dimensione}</span>
      <button class="file-remove" onclick="removeFile(${i})">✕</button>
    </div>`;
  }).join('');
}

function removeFile(index) {
  uploadedFiles.splice(index, 1);
  renderFileList();
}

function formatSize(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(0) + ' KB';
  return (bytes / 1048576).toFixed(1) + ' MB';
}

// ── Publish / Save / Delete ─────────────────────────────────
async function publishPost() {
  const titolo = document.getElementById('postTitolo').value.trim();
  const contenuto = document.getElementById('postCorpo').value.trim();
  const zona = document.getElementById('postZona').value.trim();
  if (!titolo) { alert('Inserisci un titolo'); return; }
  if (!contenuto) { alert('Inserisci il contenuto'); return; }

  const data = {
    titolo,
    tipo: document.getElementById('postTipo').value,
    contenuto,
    zona,
    frazioni: getSelectedFrazioni(),
    priorita: selectedPriority,
    stato: 'attivo',
    data: todayISO(),
    timestamp: firebase.firestore.FieldValue.serverTimestamp(),
    allegati: uploadedFiles.map(f => ({ nome: f.nome, tipo: f.tipo, dimensione: f.dimensione }))
  };
  if (currentPostId) {
    data.id = currentPostId;
  }
  try {
    await saveComunicazione(data);
    closePanel();
  } catch (e) {
    console.error('Publish comunicazione failed:', e);
    alert('Impossibile pubblicare la comunicazione. Verifica connessione e autenticazione.');
  }
}

async function saveDraft() {
  const titolo = document.getElementById('postTitolo').value.trim();
  if (!titolo) { alert('Inserisci almeno un titolo'); return; }

  const data = {
    titolo,
    tipo: document.getElementById('postTipo').value,
    contenuto: document.getElementById('postCorpo').value.trim(),
    zona: document.getElementById('postZona').value.trim(),
    frazioni: getSelectedFrazioni(),
    priorita: selectedPriority,
    stato: 'bozza',
    data: todayISO(),
    allegati: uploadedFiles.map(f => ({ nome: f.nome, tipo: f.tipo, dimensione: f.dimensione }))
  };
  if (currentPostId) {
    data.id = currentPostId;
  }
  try {
    await saveComunicazione(data, true);
    closePanel();
  } catch (e) {
    console.error('Save draft comunicazione failed:', e);
    alert('Impossibile salvare la bozza. Verifica connessione e autenticazione.');
  }
}

async function deletePost() {
  if (!currentPostId) return;
  if (!confirm('Eliminare questa comunicazione?')) return;
  try {
    await deleteComunicazione(currentPostId);
    closePanel();
  } catch (e) {
    console.error('Delete comunicazione failed:', e);
    alert('Impossibile eliminare la comunicazione.');
  }
}

async function archivePost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (c) {
    c.stato = 'archiviato';
    try {
      await saveComunicazione(c);
      closePanel();
    } catch (e) {
      console.error('Archive comunicazione failed:', e);
      alert('Impossibile archiviare la comunicazione.');
    }
  }
}

async function quickPublish(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (c) {
    c.stato = 'attivo'; c.data = todayISO();
    try {
      await saveComunicazione(c);
      closePanel();
    } catch (e) {
      console.error('Quick publish comunicazione failed:', e);
      alert('Impossibile pubblicare la comunicazione.');
    }
  }
}

async function reactivatePost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (c) {
    c.stato = 'attivo';
    try {
      await saveComunicazione(c);
      closePanel();
    } catch (e) {
      console.error('Reactivate comunicazione failed:', e);
      alert('Impossibile riattivare la comunicazione.');
    }
  }
}

// ── Helpers ─────────────────────────────────────────────────
function esc(str) {
  const d = document.createElement('div');
  d.textContent = str;
  return d.innerHTML;
}

function escAttr(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/'/g, '&#39;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function formatDate(iso) {
  if (!iso || typeof iso !== 'string' || !iso.includes('-')) return String(iso || '');
  const [y, m, d] = iso.split('-');
  return `${d}/${m}/${y}`;
}

function todayISO() {
  const d = new Date();
  return d.toISOString().split('T')[0];
}

// ── Init & event listeners ──────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  Promise.all([loadComunicazioni(), loadFrazioniComune()]).catch((e) => {
    console.error('Init comunicazioni failed:', e);
    alert('Errore inizializzazione comunicazioni. Ricarica la pagina.');
  });

  // Filters
  document.getElementById('filterTipo').addEventListener('change', render);
  document.getElementById('filterStato').addEventListener('change', render);
  document.getElementById('filterSearch').addEventListener('input', render);

  // File input
  const fileInput = document.getElementById('fileInput');
  fileInput.addEventListener('change', () => { handleFiles(fileInput.files); fileInput.value = ''; });

  // Drag & drop
  const uploadArea = document.getElementById('uploadArea');
  uploadArea.addEventListener('click', () => fileInput.click());
  uploadArea.addEventListener('dragover', e => { e.preventDefault(); uploadArea.classList.add('dragover'); });
  uploadArea.addEventListener('dragleave', () => uploadArea.classList.remove('dragover'));
  uploadArea.addEventListener('drop', e => {
    e.preventDefault();
    uploadArea.classList.remove('dragover');
    handleFiles(e.dataTransfer.files);
  });

  // Priority buttons
  document.querySelectorAll('.prio-btn').forEach(btn => {
    btn.addEventListener('click', () => setPriority(btn.dataset.prio));
  });
});
