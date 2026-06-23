// ── CivicOS Dashboard – Firestore per-comune ──

var segnData = [];
var prenData = [];
var cisterneData = [];
var aziendeData = [];
var mezziData = [];
var scadenzeData = [];
var dashboardChart = null;

function setText(id, value) {
  var el = document.getElementById(id);
  if (el) el.textContent = value;
}

function renderDashboardStats() {
  var totale = segnData.length;
  var lavorazione = segnData.filter(function(s) { return s.stato === 'In lavorazione'; }).length;
  var risolte = segnData.filter(function(s) { return s.stato === 'Risolta'; }).length;
  var now = new Date();
  var scadenzeProssime = scadenzeData.filter(function(s) {
    if (!s.data) return false;
    var d = new Date(s.data);
    var diff = (d - now) / (1000 * 60 * 60 * 24);
    return diff >= 0 && diff <= 30;
  }).length;

  setText('statSegnalazioni', totale);
  setText('statLavorazione', lavorazione);
  setText('statRisolte', risolte);
  setText('statPrenotazioni', prenData.length);
  setText('statCisterne', cisterneData.length);
  setText('statAziende', aziendeData.length);
  setText('statMezzi', mezziData.length);
  setText('statScadenze', scadenzeProssime);

  var tbody = document.getElementById('recentTableBody');
  if (!tbody) return;
  if (segnData.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:#999;padding:20px;">Nessuna segnalazione</td></tr>';
    return;
  }
  tbody.innerHTML = '';
  segnData.slice(0, 5).forEach(function(s) {
    var cls = s.stato === 'Aperta' ? 'open' : s.stato === 'In lavorazione' ? 'progress' : 'done';
    var tr = document.createElement('tr');
    tr.innerHTML = '<td>' + (s.id || '–') + '</td><td>' + (s.categoria || s.tipo || '–') + '</td><td>' + (s.posizione || '–') + '</td><td class="' + cls + '">' + s.stato + '</td>';
    tbody.appendChild(tr);
  });

  renderDashboardChart();
  renderDashboardMap();
}

function renderDashboardChart() {
  var ctx = document.getElementById('chart');
  if (!ctx || typeof Chart === 'undefined') return;
  var chartLabels = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  var chartData = [0, 0, 0, 0, 0, 0, 0];
  segnData.forEach(function(s) {
    var raw = s.timestamp && s.timestamp.toDate ? s.timestamp.toDate() : (s.data ? new Date(s.data) : null);
    if (!raw || isNaN(raw.getTime())) return;
    var dow = (raw.getDay() + 6) % 7;
    chartData[dow]++;
  });
  if (dashboardChart) dashboardChart.destroy();
  dashboardChart = new Chart(ctx, {
    type: 'bar',
    data: {
      labels: chartLabels,
      datasets: [{ label: 'Segnalazioni', data: chartData, backgroundColor: '#1E4E8C', borderRadius: 4 }]
    },
    options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
  });
}

var dashboardMap = null;
function renderDashboardMap() {
  var mapEl = document.getElementById('map');
  if (!mapEl || typeof L === 'undefined') return;
  var mapCenter = civicosGetComuneCoords();
  if (!dashboardMap) {
    dashboardMap = L.map('map').setView(mapCenter, 14);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap'
    }).addTo(dashboardMap);
  } else {
    dashboardMap.eachLayer(function(layer) {
      if (layer instanceof L.CircleMarker) dashboardMap.removeLayer(layer);
    });
  }
  segnData.forEach(function(s) {
    if (s.lat && s.lng) {
      var color = s.stato === 'Aperta' ? '#E53935' : s.stato === 'In lavorazione' ? '#F57C00' : '#2E7D32';
      L.circleMarker([s.lat, s.lng], { radius: 7, fillColor: color, color: '#fff', weight: 2, fillOpacity: 0.9 })
        .addTo(dashboardMap)
        .bindPopup('<strong>' + (s.id || '') + '</strong><br>' + (s.categoria || '') + '<br><em>' + s.stato + '</em>');
    }
  });
}

async function initDashboard() {
  var comuneConfig = civicosGetComuneConfig();
  var popEl = document.getElementById('statPopolazione');
  if (popEl) {
    var pop = comuneConfig && (comuneConfig.pop || (comuneConfig.ident && comuneConfig.ident.pop));
    popEl.textContent = pop ? parseInt(pop, 10).toLocaleString('it-IT') : '—';
  }

  if (typeof comuneRef === 'undefined' || !comuneRef) {
    renderDashboardStats();
    return;
  }

  await civicosEnsureFirebaseSession();

  civicosListenCollection('segnalazioni', function(rows) {
    segnData = rows.sort(function(a, b) {
      var ta = a.timestamp && a.timestamp.toMillis ? a.timestamp.toMillis() : 0;
      var tb = b.timestamp && b.timestamp.toMillis ? b.timestamp.toMillis() : 0;
      return tb - ta;
    });
    renderDashboardStats();
  }, 'timestamp', 'desc');

  civicosListenCollection('prenotazioni', function(rows) { prenData = rows; renderDashboardStats(); }, 'timestamp', 'desc');
  civicosListenCollection('cisterne', function(rows) { cisterneData = rows; renderDashboardStats(); });
  civicosListenCollection('aziende', function(rows) { aziendeData = rows; renderDashboardStats(); }, 'ragioneSociale');
  civicosListenCollection('mezzi', function(rows) { mezziData = rows; renderDashboardStats(); });
  civicosListenCollection('scadenze', function(rows) { scadenzeData = rows; renderDashboardStats(); }, 'data');
}

initDashboard();
