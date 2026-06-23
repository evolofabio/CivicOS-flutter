// ── Prenotazioni data – per-comune scoped ──

var prenotazioni = [];

// Listener real-time Firestore
function initPrenotazioniListener() {
  comuneRef.collection('prenotazioni').orderBy('timestamp', 'desc')
    .onSnapshot(function(snapshot) {
      prenotazioni = [];
      snapshot.forEach(function(doc) {
        var data = doc.data();
        data.id = doc.id;
        prenotazioni.push(data);
      });
      render();
    }, function(e) {
      console.error('[CivicOS] Errore prenotazioni listener:', e);
    });
}

// Carica prenotazioni da Firestore (kept for compat)
async function loadPrenotazioni() {
  initPrenotazioniListener();
}

// Salva o aggiorna prenotazione su Firestore
async function savePrenotazione(data) {
  if (!data.id) {
    // Nuova prenotazione
    const ref = await comuneRef.collection('prenotazioni').add(data);
    data.id = ref.id;
  } else {
    // Aggiorna esistente
    await comuneRef.collection('prenotazioni').doc(data.id).set(data);
  }
  await loadPrenotazioni();
}

// Cancella prenotazione da Firestore
async function deletePrenotazione(id) {
  await comuneRef.collection('prenotazioni').doc(id.toString()).delete();
  await loadPrenotazioni();
}

var tipi = [];

// ── Populate type filter ──
var filterTipo = document.getElementById('filterTipo');
tipi.forEach(function(t) {
  var opt = document.createElement('option');
  opt.value = t; opt.textContent = t;
  filterTipo.appendChild(opt);
});

// ── Status ──
function statusClass(stato) {
  if (stato === 'In attesa') return 'status-open';
  if (stato === 'Confermata') return 'status-confirmed';
  return 'status-done';
}

function tipoIcon(tipo) {
  var icons = { 'Mobili': '🛋️', 'Elettrodomestici': '🔌', 'Materassi': '🛏️', 'Elettronica': '💻', 'Altro': '📦' };
  return icons[tipo] || '📦';
}

// ── Render ──
function render() {
  var stato = document.getElementById('filterStato').value;
  var tipo = document.getElementById('filterTipo').value;
  var search = document.getElementById('filterSearch').value.toLowerCase();

  var filtered = prenotazioni.filter(function(p) {
    if (stato && p.stato !== stato) return false;
    if (tipo && p.tipo !== tipo) return false;
    if (search && p.indirizzo && p.indirizzo.toLowerCase().indexOf(search) === -1 && p.note && p.note.toLowerCase().indexOf(search) === -1) return false;
    return true;
  });

  document.getElementById('totalLabel').textContent = filtered.length + ' di ' + prenotazioni.length + ' prenotazioni';
  document.getElementById('statTotal').textContent = prenotazioni.length;
  document.getElementById('statPending').textContent = prenotazioni.filter(function(p) { return p.stato === 'In attesa'; }).length;
  document.getElementById('statConfirmed').textContent = prenotazioni.filter(function(p) { return p.stato === 'Confermata'; }).length;
  document.getElementById('statDone').textContent = prenotazioni.filter(function(p) { return p.stato === 'Completata'; }).length;

  var tbody = document.getElementById('tableBody');
  tbody.innerHTML = '';

  filtered.forEach(function(p) {
    var tr = document.createElement('tr');
    tr.style.cursor = 'pointer';
    tr.onclick = function() { openDetail(p); };
    tr.innerHTML =
      '<td><strong>' + p.id + '</strong></td>' +
      '<td>' + p.data + '</td>' +
      '<td>' + tipoIcon(p.tipo) + ' ' + p.tipo + '</td>' +
      '<td>' + p.indirizzo + '</td>' +
      '<td>' + (p.note || '–') + '</td>' +
      '<td><span class="status ' + statusClass(p.stato) + '">' + p.stato + '</span></td>' +
      '<td></td>';
    tbody.appendChild(tr);
  });
}

// ── Detail Panel ──
function openDetail(p) {
  var panel = document.getElementById('detailPanel');
  document.getElementById('detailTitle').textContent = p.id + ' – ' + p.tipo;

  document.getElementById('detailContent').innerHTML =
    '<div class="detail-row"><span class="label">Data ritiro</span><span class="value">' + p.data + '</span></div>' +
    '<div class="detail-row"><span class="label">Tipologia</span><span class="value">' + tipoIcon(p.tipo) + ' ' + p.tipo + '</span></div>' +
    '<div class="detail-row"><span class="label">Indirizzo</span><span class="value">' + p.indirizzo + '</span></div>' +
    '<div class="detail-row"><span class="label">Note</span><span class="value">' + (p.note || 'Nessuna nota') + '</span></div>' +
    '<div class="detail-row"><span class="label">Stato attuale</span><span class="value"><span class="status ' + statusClass(p.stato) + '">' + p.stato + '</span></span></div>';

  var actions = document.getElementById('detailActions');
  actions.innerHTML = '';

  if (p.stato === 'In attesa') {
    actions.innerHTML =
      '<button class="btn btn-primary" onclick="cambiStato(\'' + p.id + '\',\'Confermata\')">Conferma</button>' +
      '<button class="btn btn-danger" onclick="cambiStato(\'' + p.id + '\',\'Annullata\')">Rifiuta</button>';
  } else if (p.stato === 'Confermata') {
    actions.innerHTML =
      '<button class="btn btn-success" onclick="cambiStato(\'' + p.id + '\',\'Completata\')">Segna completata</button>' +
      '<button class="btn btn-outline" onclick="cambiStato(\'' + p.id + '\',\'In attesa\')">Rimetti in attesa</button>';
  } else {
    actions.innerHTML =
      '<button class="btn btn-outline" onclick="cambiStato(\'' + p.id + '\',\'In attesa\')">Riapri</button>';
  }

  panel.classList.add('open');
  document.body.classList.add('panel-open');
}

function closeDetail() {
  document.getElementById('detailPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}

function cambiStato(id, nuovoStato) {
  var p = prenotazioni.find(function(x) { return x.id === id; });
  if (p) {
    p.stato = nuovoStato;
    savePrenotazione(p);
  }
  closeDetail();
}

// ── Listeners ──
document.getElementById('filterStato').addEventListener('change', render);
document.getElementById('filterTipo').addEventListener('change', render);
document.getElementById('filterSearch').addEventListener('input', render);

// ── Init ──
loadPrenotazioni();
