/* ── Comunicazioni – Social Post System ── */

// ── State ──────────────────────────────────────────────────
let comunicazioni = [];
let currentCanaleView = 'all';
let comuneFrazioni = [];

// Composer state
let compPriority = 'normale';
let compMediaFile = null;    // File selezionato
let compMediaDataUrl = null; // dataUrl dopo resize
let compMediaType = null;    // 'image' | 'video'
let compMediaName = null;
let compAllegati = [];       // [{nome, tipo, dimensione, dataUrl?}]
let editingPostId = null;    // null = nuovo, stringa = modifica

// ── Firebase utils ──────────────────────────────────────────
async function ensureFirebaseReady() {
  if (typeof window.civicosEnsureFirebaseSession === 'function') {
    await window.civicosEnsureFirebaseSession();
  }
}

// ── Frazioni ────────────────────────────────────────────────
async function loadFrazioniComune() {
  await ensureFirebaseReady();
  try {
    const doc = await comuneRef.get();
    if (doc.exists && doc.data().frazioni && doc.data().frazioni.length > 0) {
      comuneFrazioni = doc.data().frazioni;
      renderCompFrazioni();
      return;
    }
  } catch(e) {}
  try {
    const auth = JSON.parse(sessionStorage.getItem('civicos_auth') || '{}');
    const config = JSON.parse(localStorage.getItem('civicos_comuni_config') || '{}');
    const f = config[auth.comune] && config[auth.comune].frazioni;
    if (f && f.length) { comuneFrazioni = f; renderCompFrazioni(); return; }
  } catch(e) {}
  comuneFrazioni = [];
  renderCompFrazioni();
}

function renderCompFrazioni() {
  const wrap = document.getElementById('compFrazioniWrap');
  const empty = document.getElementById('compFrazioniEmpty');
  const box = document.getElementById('compFrazioniCheckboxes');
  if (!wrap || !empty || !box) return;
  if (!comuneFrazioni.length) { wrap.style.display = 'none'; empty.style.display = 'block'; return; }
  wrap.style.display = 'block';
  empty.style.display = 'none';
  box.innerHTML = comuneFrazioni.map(f => `
    <label class="fraz-chip">
      <input type="checkbox" class="comp-fraz-chk" value="${esc(f)}"> ${esc(f)}
    </label>`).join('');
}

function toggleCompFrazioni() {
  const boxes = document.querySelectorAll('.comp-fraz-chk');
  const anyUnchecked = Array.from(boxes).some(b => !b.checked);
  boxes.forEach(b => { b.checked = anyUnchecked; });
}

function getCompFrazioni() {
  return Array.from(document.querySelectorAll('.comp-fraz-chk:checked')).map(b => b.value);
}

function setCompFrazioni(list) {
  document.querySelectorAll('.comp-fraz-chk').forEach(b => { b.checked = list.includes(b.value); });
}

// ── Load / Save / Delete ────────────────────────────────────
async function loadComunicazioni() {
  await ensureFirebaseReady();
  comunicazioni = [];
  let snapshot;
  try { snapshot = await comuneRef.collection('comunicazioni').orderBy('dataTs', 'desc').get(); }
  catch(e) {
    try { snapshot = await comuneRef.collection('comunicazioni').orderBy('data', 'desc').get(); }
    catch(e2) { snapshot = await comuneRef.collection('comunicazioni').get(); }
  }
  const migrations = [];
  snapshot.forEach(doc => {
    const d = doc.data(); d.id = doc.id;
    if (!d.allegati) d.allegati = [];
    if (!d.frazioni) d.frazioni = [];
    if (!d.data) d.data = todayISO();
    if (!d.dataTs && d.timestamp) { d.dataTs = d.timestamp; migrations.push(doc.ref.set({dataTs: d.timestamp},{merge:true})); }
    comunicazioni.push(d);
  });
  if (migrations.length) Promise.allSettled(migrations).catch(()=>{});
  render();
}

async function saveComunicazione(data) {
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
    const ref = await comuneRef.collection('comunicazioni').add(payload);
    data.id = ref.id;
  } else {
    await comuneRef.collection('comunicazioni').doc(data.id).set(payload, {merge: true});
  }
  if (data.stato === 'attivo') {
    await comuneRef.set({
      _lastNotifica: {
        titolo: data.titolo, contenuto: data.contenuto || '',
        tipo: data.tipo, frazioni: data.frazioni || [],
        timestamp: firebase.firestore.FieldValue.serverTimestamp(), docId: data.id
      }
    }, {merge: true});
  }
  await loadComunicazioni();
}

async function deleteComunicazione(id) {
  await ensureFirebaseReady();
  await comuneRef.collection('comunicazioni').doc(id).delete();
  await loadComunicazioni();
}

// ── Badges / helpers ─────────────────────────────────────────
const tipoLabel = { servizio:'Servizio', allerta:'Allerta', evento:'Evento', istituzionale:'Istituzionale' };
function tipoBadge(tipo) {
  return `<span class="post-type-badge badge-${tipo}">${tipoLabel[tipo]||tipo}</span>`;
}
function statoTag(stato) {
  const map = {attivo:'#2E7D32', bozza:'#F57C00', archiviato:'#999'};
  return `<span class="status-tag" style="background:${map[stato]||'#aaa'};color:#fff;padding:3px 8px;border-radius:10px;font-size:11px">${stato}</span>`;
}
function canaleOf(c) {
  if (c.canale) return String(c.canale).toLowerCase();
  return c.mediaUrl ? 'news' : 'comunicazione';
}
function esc(str) { const d=document.createElement('div'); d.textContent=str; return d.innerHTML; }
function escAttr(s) { return String(s).replace(/&/g,'&amp;').replace(/'/g,'&#39;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function formatDate(iso) {
  if (!iso||typeof iso!=='string'||!iso.includes('-')) return String(iso||'');
  const [y,m,d]=iso.split('-'); return `${d}/${m}/${y}`;
}
function todayISO() { return new Date().toISOString().split('T')[0]; }
function formatSize(b) { if(b<1024) return b+' B'; if(b<1048576) return (b/1024).toFixed(0)+' KB'; return (b/1048576).toFixed(1)+' MB'; }

// ── Tabs & Filters ───────────────────────────────────────────
function setCanaleView(v) {
  currentCanaleView = v || 'all';
  document.getElementById('tabAll').classList.toggle('active', currentCanaleView==='all');
  document.getElementById('tabComunicazioni').classList.toggle('active', currentCanaleView==='comunicazione');
  document.getElementById('tabNews').classList.toggle('active', currentCanaleView==='news');
  render();
}

// ── Render feed ──────────────────────────────────────────────
function render() {
  const feed = document.getElementById('postsFeed');
  const filterTipo = document.getElementById('filterTipo').value;
  const filterStato = document.getElementById('filterStato').value;
  const search = document.getElementById('filterSearch').value.toLowerCase();

  const filtered = comunicazioni.filter(c => {
    if (currentCanaleView !== 'all' && canaleOf(c) !== currentCanaleView) return false;
    if (filterTipo && c.tipo !== filterTipo) return false;
    if (filterStato && c.stato !== filterStato) return false;
    if (search && !c.titolo.toLowerCase().includes(search) && !c.contenuto.toLowerCase().includes(search)) return false;
    return true;
  });

  if (!filtered.length) {
    feed.innerHTML = `<div class="feed-empty">${currentCanaleView==='news'?'Nessuna news trovata':'Nessuna comunicazione trovata'}</div>`;
    updateStats(); return;
  }

  feed.innerHTML = filtered.map(c => {
    const canale = canaleOf(c);
    const hasMedia = c.mediaUrl && c.mediaUrl.length > 10;
    const isVideo = c.mediaType === 'video';
    const hasDest = c.frazioni && c.frazioni.length > 0;
    const destHtml = hasDest
      ? c.frazioni.map(f => `<span class="dest-chip">${esc(f)}</span>`).join('')
      : c.zona ? `<span class="dest-chip zona">${esc(c.zona)}</span>` : `<span class="dest-chip all">Tutti i cittadini</span>`;

    return `<article class="social-card tipo-${c.tipo}" onclick="viewPost('${escAttr(c.id)}')">
      ${hasMedia ? `<div class="social-card-media">${
        isVideo
          ? `<video src="${escAttr(c.mediaUrl)}" class="social-media-el" preload="metadata"></video>`
          : `<img src="${escAttr(c.mediaUrl)}" class="social-media-el" alt="${esc(c.titolo)}" loading="lazy">`
      }</div>` : ''}
      <div class="social-card-body">
        <div class="social-card-meta">
          ${tipoBadge(c.tipo)}
          ${canale==='news' ? '<span class="post-type-badge badge-news">News</span>' : ''}
          ${statoTag(c.stato)}
          <span class="prio-dot prio-${c.priorita}" title="${c.priorita}">${c.priorita==='urgente'?'🔴':c.priorita==='importante'?'🟡':'🟢'}</span>
          <span class="social-date">${formatDate(c.data)}</span>
        </div>
        <div class="social-card-title">${esc(c.titolo)}</div>
        <div class="social-card-text">${esc(c.contenuto.length > 180 ? c.contenuto.substring(0,180)+'…' : c.contenuto)}</div>
        <div class="social-card-dest">${destHtml}</div>
        ${c.allegati.length ? `<div class="social-card-attach">📎 ${c.allegati.length} allegat${c.allegati.length>1?'i':'o'}</div>` : ''}
      </div>
      <div class="social-card-actions" onclick="event.stopPropagation()">
        <button class="card-action-btn" onclick="editPost('${escAttr(c.id)}')">✏️ Modifica</button>
        ${c.stato==='attivo' ? `<button class="card-action-btn" onclick="archivePost('${escAttr(c.id)}')">📦 Archivia</button>` : ''}
        ${c.stato==='bozza' ? `<button class="card-action-btn primary" onclick="quickPublish('${escAttr(c.id)}')">🚀 Pubblica</button>` : ''}
        ${c.stato==='archiviato' ? `<button class="card-action-btn" onclick="reactivatePost('${escAttr(c.id)}')">♻️ Riattiva</button>` : ''}
        <button class="card-action-btn danger" onclick="if(confirm('Eliminare?')) deletePost('${escAttr(c.id)}')">🗑️</button>
      </div>
    </article>`;
  }).join('');

  updateStats();
}

function updateStats() {
  document.getElementById('statTotal').textContent = comunicazioni.length;
  document.getElementById('statActive').textContent = comunicazioni.filter(c=>c.stato==='attivo').length;
  document.getElementById('statDraft').textContent = comunicazioni.filter(c=>c.stato==='bozza').length;
  document.getElementById('statArchived').textContent = comunicazioni.filter(c=>c.stato==='archiviato').length;
}

// ── View post overlay ─────────────────────────────────────────
function viewPost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  const hasMedia = c.mediaUrl && c.mediaUrl.length > 10;
  const isVideo = c.mediaType === 'video';
  const hasDest = c.frazioni && c.frazioni.length > 0;
  const destHtml = hasDest
    ? c.frazioni.map(f=>`<span class="dest-chip">${esc(f)}</span>`).join('')
    : c.zona ? `<span class="dest-chip zona">${esc(c.zona)}</span>` : `<span class="dest-chip all">Tutti i cittadini</span>`;

  let html = '';
  if (hasMedia) {
    html += `<div class="view-media">${isVideo
      ? `<video src="${escAttr(c.mediaUrl)}" controls style="width:100%;border-radius:12px;max-height:480px;background:#000"></video>`
      : `<img src="${escAttr(c.mediaUrl)}" style="width:100%;border-radius:12px;object-fit:cover;max-height:480px" alt="${esc(c.titolo)}">`
    }</div>`;
  }
  html += `
    <div class="view-meta" style="margin-top:${hasMedia?'16px':'0'}">
      ${tipoBadge(c.tipo)}
      ${canaleOf(c)==='news'?'<span class="post-type-badge badge-news">News</span>':''}
      ${statoTag(c.stato)}
      <span class="prio-dot prio-${c.priorita}">${c.priorita==='urgente'?'🔴':c.priorita==='importante'?'🟡':'🟢'} ${c.priorita}</span>
      <span style="color:#999;font-size:12px">${formatDate(c.data)}</span>
    </div>
    <div class="view-title">${esc(c.titolo)}</div>
    <div class="view-body">${esc(c.contenuto)}</div>
    <div class="social-card-dest" style="margin-top:10px">${destHtml}</div>`;

  if (c.allegati && c.allegati.length) {
    html += `<div class="view-attachments"><h4>Allegati</h4>`;
    c.allegati.forEach(a => {
      if (a.dataUrl && a.tipo === 'image') {
        html += `<div class="view-attach-item"><img src="${escAttr(a.dataUrl)}" style="max-width:100%;border-radius:8px;margin-top:8px" alt="${esc(a.nome)}"><div class="file-name">${esc(a.nome)}</div></div>`;
      } else {
        const icon = a.tipo==='pdf'?'📄':'🖼️';
        html += `<div class="view-file"><span class="file-icon">${icon}</span><span class="file-name">${esc(a.nome)}</span><span class="file-size">${a.dimensione||''}</span></div>`;
      }
    });
    html += '</div>';
  }

  document.getElementById('viewContent').innerHTML = html;
  let btns = `<button class="btn btn-primary" onclick="editPost('${escAttr(id)}')">✏️ Modifica</button>`;
  if (c.stato==='attivo') btns += ` <button class="btn btn-outline" onclick="archivePost('${escAttr(id)}');closeViewPanel()">📦 Archivia</button>`;
  if (c.stato==='bozza') btns += ` <button class="btn btn-primary" onclick="quickPublish('${escAttr(id)}');closeViewPanel()">🚀 Pubblica</button>`;
  if (c.stato==='archiviato') btns += ` <button class="btn btn-outline" onclick="reactivatePost('${escAttr(id)}');closeViewPanel()">♻️ Riattiva</button>`;
  btns += ` <button class="btn btn-danger" onclick="if(confirm('Eliminare?')){deletePost('${escAttr(id)}');closeViewPanel()}">🗑️ Elimina</button>`;
  document.getElementById('viewActions').innerHTML = btns;
  document.getElementById('viewPanel').classList.add('open');
  document.body.classList.add('panel-open');
}

function closeViewPanel() {
  document.getElementById('viewPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}

// ── Composer ─────────────────────────────────────────────────
function openComposer(postData) {
  editingPostId = postData ? postData.id : null;
  compPriority = postData ? postData.priorita : 'normale';
  compMediaFile = null;
  compMediaDataUrl = postData && postData.mediaUrl ? postData.mediaUrl : null;
  compMediaType = postData && postData.mediaType ? postData.mediaType : null;
  compMediaName = postData && postData.mediaName ? postData.mediaName : null;
  compAllegati = postData && postData.allegati ? [...postData.allegati] : [];

  document.getElementById('compTesto').value = postData ? postData.titolo + (postData.contenuto ? '\n' + postData.contenuto : '') : '';
  document.getElementById('compTipo').value = postData ? (postData.tipo || 'servizio') : 'servizio';
  document.getElementById('compCanale').value = postData ? (postData.canale || 'comunicazione') : 'comunicazione';
  document.getElementById('compZona').value = postData ? (postData.zona || '') : '';

  updatePrioChips();
  renderCompAllegatiList();
  renderCompMediaPreview();

  if (postData && postData.frazioni) setCompFrazioni(postData.frazioni);
  else setCompFrazioni([]);

  document.getElementById('composerWrap').style.display = 'block';
  document.getElementById('btnNuovoPost').style.display = 'none';
  document.getElementById('compTesto').focus();
}

function closeComposer() {
  document.getElementById('composerWrap').style.display = 'none';
  document.getElementById('btnNuovoPost').style.display = '';
  editingPostId = null; compMediaFile = null; compMediaDataUrl = null; compAllegati = [];
}

function autoGrowComposer(el) {
  el.style.height = 'auto';
  el.style.height = el.scrollHeight + 'px';
}

function setComposerPriority(p) {
  compPriority = p;
  updatePrioChips();
}

function updatePrioChips() {
  document.querySelectorAll('#compPrioChips .prio-chip').forEach(b => {
    b.classList.toggle('active', b.dataset.prio === compPriority);
  });
}

// ── Media handling ────────────────────────────────────────────
function triggerMediaPick() {
  document.getElementById('compMediaInput').click();
}

function handleComposerMedia(files) {
  const file = files && files[0];
  if (!file) return;
  const isImage = file.type.startsWith('image/');
  const isVideo = file.type.startsWith('video/');
  if (!isImage && !isVideo) { alert('Formato non supportato. Usa immagine o video.'); return; }

  compMediaFile = file;
  compMediaType = isVideo ? 'video' : 'image';
  compMediaName = file.name;

  if (isImage) {
    resizeImageToDataUrl(file, 1200, 0.85).then(dataUrl => {
      compMediaDataUrl = dataUrl;
      renderCompMediaPreview();
    });
  } else {
    // Video: preview via blob URL
    compMediaDataUrl = URL.createObjectURL(file);
    renderCompMediaPreview();
  }
}

function resizeImageToDataUrl(file, maxPx, quality) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = e => {
      const img = new Image();
      img.onload = () => {
        const ratio = Math.min(maxPx / img.width, maxPx / img.height, 1);
        const w = Math.round(img.width * ratio);
        const h = Math.round(img.height * ratio);
        const canvas = document.createElement('canvas');
        canvas.width = w; canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        resolve(canvas.toDataURL('image/jpeg', quality));
      };
      img.onerror = reject;
      img.src = e.target.result;
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}

function renderCompMediaPreview() {
  const wrap = document.getElementById('compMediaPreview');
  const img = document.getElementById('compMediaImg');
  const vid = document.getElementById('compMediaVid');
  if (!compMediaDataUrl) {
    wrap.style.display = 'none'; img.style.display = 'none'; vid.style.display = 'none';
    img.src = ''; vid.src = '';
    return;
  }
  wrap.style.display = 'block';
  if (compMediaType === 'video') {
    img.style.display = 'none'; vid.style.display = 'block'; vid.src = compMediaDataUrl;
  } else {
    vid.style.display = 'none'; img.style.display = 'block'; img.src = compMediaDataUrl;
  }
}

function clearComposerMedia() {
  compMediaFile = null; compMediaDataUrl = null; compMediaType = null; compMediaName = null;
  document.getElementById('compMediaInput').value = '';
  renderCompMediaPreview();
}

// ── Allegati ──────────────────────────────────────────────────
function handleCompAllegati(files) {
  Array.from(files).forEach(f => {
    const isImage = f.type.startsWith('image/');
    const isPdf = f.type === 'application/pdf';
    if (!isImage && !isPdf) return;
    const item = { nome: f.name, tipo: isImage?'image':'pdf', dimensione: formatSize(f.size), _file: f };
    compAllegati.push(item);
  });
  renderCompAllegatiList();
}

function renderCompAllegatiList() {
  const c = document.getElementById('compAllegatiList');
  if (!c) return;
  if (!compAllegati.length) { c.innerHTML = ''; return; }
  c.innerHTML = compAllegati.map((f,i) => `<div class="file-item">
    <span class="file-icon">${f.tipo==='pdf'?'📄':'🖼️'}</span>
    <span class="file-name">${esc(f.nome)}</span>
    <span class="file-size">${f.dimensione}</span>
    <button class="file-remove" onclick="removeCompAllegato(${i})">✕</button>
  </div>`).join('');
}

function removeCompAllegato(i) { compAllegati.splice(i,1); renderCompAllegatiList(); }

async function buildCompAllegatiPayload() {
  const MAX = 420000;
  return Promise.all(compAllegati.map(async f => {
    const item = { nome: f.nome, tipo: f.tipo, dimensione: f.dimensione };
    if (f._file && f.tipo==='image' && f._file.size <= MAX) {
      try { item.dataUrl = await resizeImageToDataUrl(f._file, 800, 0.8); } catch(_){}
    } else if (!f._file && f.dataUrl) {
      item.dataUrl = f.dataUrl;
    }
    return item;
  }));
}

// ── Parse titolo / contenuto dal textarea ─────────────────────
function parseComposerText() {
  const raw = document.getElementById('compTesto').value.trim();
  const lines = raw.split('\n');
  const titolo = lines[0].trim();
  const contenuto = lines.slice(1).join('\n').trim();
  return { titolo, contenuto };
}

// ── Publish ───────────────────────────────────────────────────
async function publishComp() {
  const { titolo, contenuto } = parseComposerText();
  if (!titolo) { alert('Scrivi almeno un titolo.'); return; }

  const btn = document.getElementById('btnPublishComp');
  btn.disabled = true; btn.textContent = 'Pubblicazione…';

  try {
    const allegati = await buildCompAllegatiPayload();
    // Per i video usa l'URL blob (solo sessione corrente) o la dataUrl se piccolo
    let mediaUrl = compMediaDataUrl || '';
    // Se è un video file, proviamo a fare dataUrl (per video piccoli < 20MB) – altrimenti stringa vuota
    if (compMediaFile && compMediaType === 'video' && compMediaFile.size < 20 * 1024 * 1024) {
      try {
        mediaUrl = await new Promise((res, rej) => {
          const reader = new FileReader();
          reader.onload = e => res(e.target.result);
          reader.onerror = rej;
          reader.readAsDataURL(compMediaFile);
        });
      } catch(_) { mediaUrl = ''; }
    } else if (compMediaFile && compMediaType === 'image') {
      // già in compMediaDataUrl (resize)
    }

    const data = {
      titolo,
      contenuto: contenuto || titolo,
      tipo: document.getElementById('compTipo').value,
      canale: document.getElementById('compCanale').value,
      mediaUrl,
      mediaType: compMediaType || '',
      mediaName: compMediaName || '',
      zona: document.getElementById('compZona').value.trim(),
      frazioni: getCompFrazioni(),
      priorita: compPriority,
      stato: 'attivo',
      data: todayISO(),
      timestamp: firebase.firestore.FieldValue.serverTimestamp(),
      allegati
    };
    if (editingPostId) data.id = editingPostId;
    await saveComunicazione(data);
    closeComposer();
  } catch(e) {
    console.error('Publish failed:', e);
    alert('Errore durante la pubblicazione: ' + e.message);
  } finally {
    btn.disabled = false; btn.textContent = 'Pubblica';
  }
}

async function saveCompDraft() {
  const { titolo, contenuto } = parseComposerText();
  if (!titolo) { alert('Scrivi almeno un titolo.'); return; }
  try {
    const allegati = await buildCompAllegatiPayload();
    const data = {
      titolo, contenuto: contenuto || titolo,
      tipo: document.getElementById('compTipo').value,
      canale: document.getElementById('compCanale').value,
      mediaUrl: compMediaDataUrl || '',
      mediaType: compMediaType || '',
      mediaName: compMediaName || '',
      zona: document.getElementById('compZona').value.trim(),
      frazioni: getCompFrazioni(),
      priorita: compPriority,
      stato: 'bozza',
      data: todayISO(),
      allegati
    };
    if (editingPostId) data.id = editingPostId;
    await saveComunicazione(data);
    closeComposer();
  } catch(e) {
    console.error('Draft failed:', e);
    alert('Errore durante il salvataggio: ' + e.message);
  }
}

// ── Edit / Delete / Archive / Publish rapido ─────────────────
function editPost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  closeViewPanel();
  openComposer(c);
}

async function deletePost(id) {
  try { await deleteComunicazione(id); } catch(e) { alert('Errore eliminazione: ' + e.message); }
}

async function archivePost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  try { await saveComunicazione({...c, stato:'archiviato'}); } catch(e) { alert('Errore: ' + e.message); }
}

async function quickPublish(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  try { await saveComunicazione({...c, stato:'attivo', data: todayISO()}); } catch(e) { alert('Errore: ' + e.message); }
}

async function reactivatePost(id) {
  const c = comunicazioni.find(x => x.id === id);
  if (!c) return;
  try { await saveComunicazione({...c, stato:'attivo'}); } catch(e) { alert('Errore: ' + e.message); }
}

// ── Init ──────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  Promise.all([loadComunicazioni(), loadFrazioniComune()]).catch(e => {
    console.error('Init failed:', e);
    alert('Errore inizializzazione. Ricarica la pagina.');
  });
  document.getElementById('filterTipo').addEventListener('change', render);
  document.getElementById('filterStato').addEventListener('change', render);
  document.getElementById('filterSearch').addEventListener('input', render);
});
