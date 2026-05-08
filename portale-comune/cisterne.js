// ── Cisterne Acqua data – per-comune scoped ──

var cisterne = [];

// Listener real-time Firestore
function initCisterneListener() {
  comuneRef.collection('cisterne').orderBy('timestamp', 'desc')
    .onSnapshot(function(snapshot) {
      cisterne = [];
      snapshot.forEach(function(doc) {
        var data = doc.data();
        data.id = doc.id;
        cisterne.push(data);
      });
      render();
    }, function(e) {
      console.error('[CivicOS] Errore cisterne listener:', e);
    });
}

// Carica cisterne da Firestore (kept for compat)
async function loadCisterne() {
  initCisterneListener();
}

// Salva o aggiorna cisterna su Firestore
async function saveCisterna(data) {
  if (!data.id) {
    // Nuova cisterna
    const ref = await comuneRef.collection('cisterne').add(data);
    data.id = ref.id;
  } else {
    // Aggiorna esistente
    await comuneRef.collection('cisterne').doc(data.id).set(data);
  }
  await loadCisterne();
}

// Cancella cisterna da Firestore
async function deleteCisterna(id) {
  await comuneRef.collection('cisterne').doc(id.toString()).delete();
  await loadCisterne();
}

var motivazioni = [];

// ── Service activation config ──
var cisterneConfigKey = (typeof civicosStorageKey === 'function')
  ? civicosStorageKey('civicos_cisterne_config')
  : 'civicos_cisterne_config';

function loadServiceConfig() {
  var defaults = {
    // Default true per non bloccare una sezione storicamente operativa.
    attivo: true,
    modalita: 'sempre',
    dal: '',
    al: ''
  };
  try {
    var raw = localStorage.getItem(cisterneConfigKey);
    if (!raw) return defaults;
    var parsed = JSON.parse(raw) || {};
    return {
      attivo: typeof parsed.attivo === 'boolean' ? parsed.attivo : defaults.attivo,
      modalita: parsed.modalita === 'periodo' ? 'periodo' : 'sempre',
      dal: parsed.dal || '',
      al: parsed.al || ''
    };
  } catch (e) {
    return defaults;
  }
}

var serviceConfig = loadServiceConfig();

// ── Populate motivazione filter ──
var filterMotivazione = document.getElementById('filterMotivazione');
motivazioni.forEach(function(m) {
  var opt = document.createElement('option');
  opt.value = m; opt.textContent = m;
  filterMotivazione.appendChild(opt);
});

// ── Status ──
function statusClass(stato) {
  if (stato === 'In attesa') return 'status-open';
  if (stato === 'Confermata') return 'status-confirmed';
  if (stato === 'In consegna') return 'status-progress';
  return 'status-done';
}

// ── Render ──
function render() {

  var stato = document.getElementById('filterStato').value;
  var motivazione = document.getElementById('filterMotivazione').value;
  var soloUrgente = document.getElementById('filterUrgente').checked;
  var search = document.getElementById('filterSearch').value.toLowerCase();

  var filtered = cisterne.filter(function(c) {
    if (stato && c.stato !== stato) return false;
    if (motivazione && c.motivazione !== motivazione) return false;
    if (soloUrgente && !c.urgente) return false;
    if (search && c.indirizzo && c.indirizzo.toLowerCase().indexOf(search) === -1 && c.note && c.note.toLowerCase().indexOf(search) === -1) return false;
    return true;
  });

  document.getElementById('totalLabel').textContent = filtered.length + ' di ' + cisterne.length + ' richieste';
  document.getElementById('statTotal').textContent = cisterne.length;
  document.getElementById('statPending').textContent = cisterne.filter(function(c) { return c.stato === 'In attesa'; }).length;
  document.getElementById('statConfirmed').textContent = cisterne.filter(function(c) { return c.stato === 'Confermata'; }).length;
  document.getElementById('statDone').textContent = cisterne.filter(function(c) { return c.stato === 'Completata'; }).length;

  var tbody = document.getElementById('tableBody');
  tbody.innerHTML = '';

  filtered.forEach(function(c) {
    var tr = document.createElement('tr');
    tr.style.cursor = 'pointer';
    tr.onclick = function() { openDetail(c); };
    tr.innerHTML =
      '<td><strong>' + c.id + '</strong></td>' +
      '<td>' + c.data + '</td>' +
      '<td>' + c.motivazione + '</td>' +
      '<td>' + c.indirizzo + '</td>' +
      '<td>' + c.telefono + '</td>' +
      '<td>' + c.numPersone + '</td>' +
      '<td>' + (c.urgente ? '🔴 Sì' : 'No') + '</td>' +
      '<td><span class="status ' + statusClass(c.stato) + '">' + c.stato + '</span></td>' +
      '<td></td>';
    tbody.appendChild(tr);
  });
}

// ── Detail Panel ──
function openDetail(c) {
  var panel = document.getElementById('detailPanel');
  document.getElementById('detailTitle').textContent = c.id + ' – Rifornimento Cisterna';

  document.getElementById('detailContent').innerHTML =
    '<div class="detail-row"><span class="label">Data richiesta</span><span class="value">' + c.data + '</span></div>' +
    '<div class="detail-row"><span class="label">Motivazione</span><span class="value">💧 ' + c.motivazione + '</span></div>' +
    '<div class="detail-row"><span class="label">Indirizzo</span><span class="value">' + c.indirizzo + '</span></div>' +
    '<div class="detail-row"><span class="label">Telefono</span><span class="value">' + c.telefono + '</span></div>' +
    '<div class="detail-row"><span class="label">Nucleo familiare</span><span class="value">' + c.numPersone + ' persone</span></div>' +
    '<div class="detail-row"><span class="label">Urgente</span><span class="value">' + (c.urgente ? '🔴 Sì' : 'No') + '</span></div>' +
    '<div class="detail-row"><span class="label">Note</span><span class="value">' + (c.note || 'Nessuna nota') + '</span></div>' +
    '<div class="detail-row"><span class="label">Stato attuale</span><span class="value"><span class="status ' + statusClass(c.stato) + '">' + c.stato + '</span></span></div>';

  var actions = document.getElementById('detailActions');
  actions.innerHTML = '';

  if (c.stato === 'In attesa') {
    actions.innerHTML =
      '<button class="btn btn-primary" onclick="cambiStato(\'' + c.id + '\',\'Confermata\')">Conferma</button>' +
      '<button class="btn btn-danger" onclick="cambiStato(\'' + c.id + '\',\'Annullata\')">Rifiuta</button>';
  } else if (c.stato === 'Confermata') {
    actions.innerHTML =
      '<button class="btn btn-primary" onclick="cambiStato(\'' + c.id + '\',\'In consegna\')">Segna in consegna</button>' +
      '<button class="btn btn-outline" onclick="cambiStato(\'' + c.id + '\',\'In attesa\')">Rimetti in attesa</button>';
  } else if (c.stato === 'In consegna') {
    actions.innerHTML =
      '<button class="btn btn-success" onclick="cambiStato(\'' + c.id + '\',\'Completata\')">Segna completata</button>' +
      '<button class="btn btn-outline" onclick="cambiStato(\'' + c.id + '\',\'Confermata\')">Torna a confermata</button>';
  } else {
    actions.innerHTML =
      '<button class="btn btn-outline" onclick="cambiStato(\'' + c.id + '\',\'In attesa\')">Riapri</button>';
  }

  panel.classList.add('open');
  document.body.classList.add('panel-open');
}

function closeDetail() {
  document.getElementById('detailPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
}

function cambiStato(id, nuovoStato) {
  var c = cisterne.find(function(x) { return x.id === id; });
  if (c) {
    c.stato = nuovoStato;
    saveCisterna(c);
  }
  closeDetail();
}

// ── Listeners ──
document.getElementById('filterStato').addEventListener('change', render);
document.getElementById('filterMotivazione').addEventListener('change', render);
document.getElementById('filterUrgente').addEventListener('change', render);
document.getElementById('filterSearch').addEventListener('input', render);

// ── Init ──
loadCisterne();
initServicePanel();

// ── Service activation/deactivation ──

function saveServiceConfig() {
  try { localStorage.setItem(cisterneConfigKey, JSON.stringify(serviceConfig)); } catch(e){}
}

function initServicePanel() {
  var toggle = document.getElementById('serviceToggle');
  toggle.checked = serviceConfig.attivo;

  if (serviceConfig.modalita === 'periodo') {
    document.getElementById('modePeriodo').checked = true;
  } else {
    document.getElementById('modeSempre').checked = true;
  }

  if (serviceConfig.dal) document.getElementById('dataDal').value = serviceConfig.dal;
  if (serviceConfig.al) document.getElementById('dataAl').value = serviceConfig.al;

  refreshServiceUI();
}

function toggleService() {
  serviceConfig.attivo = document.getElementById('serviceToggle').checked;
  saveServiceConfig();
  refreshServiceUI();
}

function updateServiceMode() {
  var isPeriodo = document.getElementById('modePeriodo').checked;
  serviceConfig.modalita = isPeriodo ? 'periodo' : 'sempre';
  document.getElementById('periodoFields').style.display = isPeriodo ? 'block' : 'none';
  updatePeriodLabel();
}

function updateServiceDates() {
  serviceConfig.dal = document.getElementById('dataDal').value;
  serviceConfig.al = document.getElementById('dataAl').value;
  updatePeriodLabel();
}

function updatePeriodLabel() {
  var label = document.getElementById('periodoDaysLabel');
  if (serviceConfig.dal && serviceConfig.al) {
    var d1 = new Date(serviceConfig.dal);
    var d2 = new Date(serviceConfig.al);
    var diff = Math.round((d2 - d1) / (1000 * 60 * 60 * 24));
    if (diff > 0) {
      label.textContent = 'Durata: ' + diff + ' giorni';
    } else if (diff === 0) {
      label.textContent = 'Durata: 1 giorno';
    } else {
      label.textContent = '⚠️ La data di fine deve essere successiva a quella di inizio';
    }
  } else {
    label.textContent = '';
  }
}

function formatDateIT(isoStr) {
  if (!isoStr) return '';
  var parts = isoStr.split('-');
  return parts[2] + '/' + parts[1] + '/' + parts[0];
}

function isServiceActive() {
  if (!serviceConfig.attivo) return false;
  if (serviceConfig.modalita === 'sempre') return true;
  if (serviceConfig.modalita === 'periodo' && serviceConfig.dal && serviceConfig.al) {
    var today = new Date(); today.setHours(0,0,0,0);
    var dal = new Date(serviceConfig.dal); dal.setHours(0,0,0,0);
    var al = new Date(serviceConfig.al); al.setHours(23,59,59,999);
    return today >= dal && today <= al;
  }
  return false;
}

function refreshServiceUI() {
  var attivo = serviceConfig.attivo;
  var icon = document.getElementById('serviceIcon');
  var statusLabel = document.getElementById('serviceStatusLabel');
  var periodLabel = document.getElementById('servicePeriodLabel');
  var dateRange = document.getElementById('serviceDateRange');
  var filtersAndTable = document.querySelectorAll('.filters, .table-box, .stats');

  // Toggle switch UI
  dateRange.style.display = attivo ? 'block' : 'none';

  if (attivo) {
    var live = isServiceActive();
    icon.textContent = '\u25cf';
    icon.style.color = live ? '#2E7D32' : '#F57C00';
    statusLabel.textContent = live ? 'Servizio attivo' : 'Servizio attivo (fuori periodo)';

    if (serviceConfig.modalita === 'periodo' && serviceConfig.dal && serviceConfig.al) {
      periodLabel.textContent = 'Periodo: ' + formatDateIT(serviceConfig.dal) + ' – ' + formatDateIT(serviceConfig.al);
    } else if (serviceConfig.modalita === 'sempre') {
      periodLabel.textContent = 'Attivo senza scadenza';
    } else {
      periodLabel.textContent = '';
    }

    // Show date fields if in periodo mode
    document.getElementById('periodoFields').style.display =
      document.getElementById('modePeriodo').checked ? 'block' : 'none';
  } else {
    icon.textContent = '\u25cf';
    icon.style.color = '#999';
    statusLabel.textContent = 'Servizio disattivato';
    periodLabel.textContent = 'I cittadini non possono inviare richieste';
  }

  // Dim tables when disabled
  filtersAndTable.forEach(function(el) {
    if (!attivo) {
      el.classList.add('service-disabled-overlay');
    } else {
      el.classList.remove('service-disabled-overlay');
    }
  });
}
