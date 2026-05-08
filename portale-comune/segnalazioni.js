// ── Segnalazioni data – per-comune scoped ──

var segnalazioni = [];

// Listener real-time Firestore
function initSegnalazioniListener() {
  comuneRef.collection('segnalazioni').orderBy('timestamp', 'desc')
    .onSnapshot(function(snapshot) {
      segnalazioni = [];
      snapshot.forEach(function(doc) {
        var data = doc.data();
        data.id = doc.id;
        if (!data.segnalazioneId) data.segnalazioneId = doc.id;
        data.utenteDisplay = data.utenteDisplay || data.utenteEmail || data.email || data.uid || 'Anonimo';
        segnalazioni.push(data);
      });
      render();
    }, function(e) {
      console.error('[CivicOS] Errore segnalazioni listener:', e);
    });
}

// Carica segnalazioni da Firestore (kept for compat)
async function loadSegnalazioni() {
  initSegnalazioniListener();
}

// Salva o aggiorna segnalazione su Firestore
async function saveSegnalazione(data) {
  if (!data.id) {
    // Nuova segnalazione
    const ref = await comuneRef.collection('segnalazioni').add(data);
    data.id = ref.id;
  } else {
    // Aggiorna esistente
    await comuneRef.collection('segnalazioni').doc(data.id).set(data);
  }
  await loadSegnalazioni();
}

// Cancella segnalazione da Firestore
async function deleteSegnalazione(id) {
  await comuneRef.collection('segnalazioni').doc(id.toString()).delete();
  await loadSegnalazioni();
}

var categorie = [...new Set(segnalazioni.map(s => s.categoria))].sort();

// ── Populate category filter ──
var filterCat = document.getElementById('filterCategoria');
categorie.forEach(function(c) {
  var opt = document.createElement('option');
  opt.value = c; opt.textContent = c;
  filterCat.appendChild(opt);
});

// ── Render ──
function statusClass(stato) {
  if (stato === 'Aperta') return 'status-open';
  if (stato === 'In lavorazione') return 'status-progress';
  return 'status-done';
}

function render() {
  var stato = document.getElementById('filterStato').value;
  var cat = document.getElementById('filterCategoria').value;
  var search = document.getElementById('filterSearch').value.toLowerCase();

  var filtered = segnalazioni.filter(function(s) {
    var descr = (s.descrizione || '').toString().toLowerCase();
    var pos = (s.posizione || '').toString().toLowerCase();
    if (stato && s.stato !== stato) return false;
    if (cat && s.categoria !== cat) return false;
    if (search && descr.indexOf(search) === -1 && pos.indexOf(search) === -1) return false;
    return true;
  });

  var aperte = segnalazioni.filter(function(s) { return s.stato === 'Aperta'; }).length;
  document.getElementById('countBadge').textContent = aperte;
  document.getElementById('totalLabel').textContent = filtered.length + ' di ' + segnalazioni.length + ' segnalazioni';

  var tbody = document.getElementById('tableBody');
  tbody.innerHTML = '';

  filtered.forEach(function(s) {
    var tr = document.createElement('tr');
    tr.style.cursor = 'pointer';
    tr.onclick = function() { openDetail(s); };
    tr.innerHTML =
      '<td><strong>' + (s.segnalazioneId || s.id) + '</strong></td>' +
      '<td>' + s.data + '</td>' +
      '<td>' + s.categoria + '</td>' +
      '<td>' + truncate(s.descrizione || '', 45) + '</td>' +
      '<td>' + (s.utenteDisplay || '-') + '</td>' +
      '<td>' + (s.posizione || '-') + '</td>' +
      '<td><span class="status ' + statusClass(s.stato) + '">' + s.stato + '</span></td>' +
      '<td>' + (s.foto ? '📷' : '') + '</td>';
    tbody.appendChild(tr);
  });

  renderMap(filtered);
}

function truncate(str, n) {
  return str.length > n ? str.substring(0, n) + '…' : str;
}

function getSegnalazioneCoords(s) {
  var lat = Number(s.lat);
  var lng = Number(s.lng);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
    var pos = (s.posizione || '').toString();
    var parts = pos.split(',');
    if (parts.length >= 2) {
      lat = Number(parts[0].trim());
      lng = Number(parts[1].trim());
    }
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return [lat, lng];
}

// ── Map ──
var mapCoords = civicosGetComuneCoords();
var map = L.map('map').setView(mapCoords, 14);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
  attribution: '&copy; OpenStreetMap'
}).addTo(map);

var markers = [];
function renderMap(items) {
  markers.forEach(function(m) { map.removeLayer(m); });
  markers = [];
  items.forEach(function(s) {
    var coords = getSegnalazioneCoords(s);
    if (!coords) return;
    var color = s.stato === 'Aperta' ? '#E53935' : s.stato === 'In lavorazione' ? '#F57C00' : '#2E7D32';
    var m = L.circleMarker(coords, { radius: 8, fillColor: color, color: '#fff', weight: 2, fillOpacity: 0.9 })
      .addTo(map)
      .bindPopup('<strong>' + (s.segnalazioneId || s.id) + '</strong><br>' + s.categoria + '<br><em>' + s.stato + '</em>');
    m.on('click', function() { openDetail(s); });
    markers.push(m);
  });

  if (markers.length > 0) {
    var group = L.featureGroup(markers);
    map.fitBounds(group.getBounds().pad(0.2));
  }
}

// ── Detail Panel ──
function openDetail(s) {
  var panel = document.getElementById('detailPanel');
  var segId = s.segnalazioneId || s.id;
  document.getElementById('detailTitle').textContent = segId + ' – ' + s.categoria;

  document.getElementById('detailContent').innerHTML =
    '<div class="detail-row"><span class="label">ID segnalazione</span><span class="value"><strong>' + segId + '</strong></span></div>' +
    '<div class="detail-row"><span class="label">Data</span><span class="value">' + s.data + '</span></div>' +
    '<div class="detail-row"><span class="label">Categoria</span><span class="value">' + s.categoria + '</span></div>' +
    '<div class="detail-row"><span class="label">Utente</span><span class="value">' + (s.utenteDisplay || '-') + '</span></div>' +
    '<div class="detail-row"><span class="label">Descrizione</span><span class="value">' + s.descrizione + '</span></div>' +
    '<div class="detail-row"><span class="label">Posizione</span><span class="value">' + s.posizione + '</span></div>' +
    '<div class="detail-row"><span class="label">Stato attuale</span><span class="value"><span class="status ' + statusClass(s.stato) + '">' + s.stato + '</span></span></div>' +
    (s.foto && s.fotoUrl
      ? '<div style="margin-top:14px;"><span class="label" style="display:block;margin-bottom:6px;">📷 Foto allegata</span>' +
        '<div style="background:#f4f7fb;border-radius:10px;padding:10px;text-align:center;">' +
        '<img src="' + s.fotoUrl + '" alt="Foto segnalazione" style="max-width:100%;max-height:260px;border-radius:8px;cursor:pointer;" onclick="window.open(this.src,\'_blank\')">' +
        '<div style="margin-top:8px;"><a href="' + s.fotoUrl + '" download="foto_' + s.id + '.jpg" class="btn btn-outline" style="font-size:12px;">⬇️ Scarica foto</a></div>' +
        '</div></div>'
      : '<div class="detail-row"><span class="label">Foto allegata</span><span class="value">No</span></div>');

  var actions = document.getElementById('detailActions');
  actions.innerHTML = '';

  if (s.stato === 'Aperta') {
    actions.innerHTML =
      '<button class="btn btn-warning" onclick="cambiStato(\'' + s.id + '\',\'In lavorazione\')">Prendi in carico</button>' +
      '<button class="btn btn-success" onclick="cambiStato(\'' + s.id + '\',\'Risolta\')">Segna risolta</button>' +
      '<button class="btn btn-danger" onclick="deleteSegnalazioneFromDetail(\'' + s.id + '\')">Elimina</button>';
  } else if (s.stato === 'In lavorazione') {
    actions.innerHTML =
      '<button class="btn btn-success" onclick="cambiStato(\'' + s.id + '\',\'Risolta\')">Segna risolta</button>' +
      '<button class="btn btn-outline" onclick="cambiStato(\'' + s.id + '\',\'Aperta\')">Riapri</button>' +
      '<button class="btn btn-danger" onclick="deleteSegnalazioneFromDetail(\'' + s.id + '\')">Elimina</button>';
  } else {
    actions.innerHTML =
      '<button class="btn btn-outline" onclick="cambiStato(\'' + s.id + '\',\'Aperta\')">Riapri</button>' +
      '<button class="btn btn-danger" onclick="deleteSegnalazioneFromDetail(\'' + s.id + '\')">Elimina</button>';
  }

  panel.classList.add('open');
  document.body.classList.add('panel-open');
}

function closeDetail() {
  document.getElementById('detailPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}

function cambiStato(id, nuovoStato) {
  var seg = segnalazioni.find(function(s) { return s.id === id; });
  if (seg) {
    seg.stato = nuovoStato;
    saveSegnalazione(seg);
  }
  closeDetail();
}

async function deleteSegnalazioneFromDetail(id) {
  if (!id) return;
  var seg = segnalazioni.find(function(s) { return s.id === id; });
  var label = seg ? (seg.segnalazioneId || seg.id) : id;
  if (!confirm('Eliminare la segnalazione ' + label + '?')) return;
  try {
    await deleteSegnalazione(id);
    closeDetail();
  } catch (e) {
    console.error('[CivicOS] Errore eliminazione segnalazione:', e);
    alert('Impossibile eliminare la segnalazione.');
  }
}

// ── Listeners ──
document.getElementById('filterStato').addEventListener('change', render);
document.getElementById('filterCategoria').addEventListener('change', render);
document.getElementById('filterSearch').addEventListener('input', render);

// ── Init ──
loadSegnalazioni();
