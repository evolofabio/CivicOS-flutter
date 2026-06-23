// ══════════════════════════════════════
// SECTION SWITCHER
// ══════════════════════════════════════
function switchSection() {
  var val = document.getElementById('sectionSelect').value;
  document.getElementById('sectionDifferenziata').style.display = val === 'differenziata' ? '' : 'none';
  document.getElementById('sectionIngombranti').style.display = val === 'ingombranti' ? '' : 'none';
  if (val === 'ingombranti') { renderIngWeekly(); renderIngCalendar(); }
}

// ══════════════════════════════════════
// SHARED
// ══════════════════════════════════════
var giorniNomi = ["Lunedì","Martedì","Mercoledì","Giovedì","Venerdì","Sabato","Domenica"];
var mesiNomi = ["Gennaio","Febbraio","Marzo","Aprile","Maggio","Giugno","Luglio","Agosto","Settembre","Ottobre","Novembre","Dicembre"];
var diffYear = 2026, diffMonth = 2;
var ingYear = 2026, ingMonth = 2;

function dateKey(d) {
  return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
}
function escapeHtml(str) {
  var div = document.createElement('div');
  div.appendChild(document.createTextNode(str));
  return div.innerHTML;
}

// ══════════════════════════════════════
// RACCOLTA DIFFERENZIATA
// ══════════════════════════════════════
var comuneNome = civicosGetComune() || 'Comune';

// Load frazioni from comune config (setup.html stores them)
var frazioniConfig = civicosGetFrazioni();
var frazioniNomi = frazioniConfig.length > 0 ? frazioniConfig.slice() : ['Centro'];
var frazioneSelezionata = frazioniNomi[0];

// Storage: solo Firestore

// Default weekly schedule generator for a fraction
function defaultCalendario(index) {
  var tipiBase = ['Umido','Plastica','Carta','Vetro','Metalli','Secco residuo'];
  // Rotate assignments based on fraction index for variety
  var offset = index % tipiBase.length;
  return [
    { giorno:"Lunedì",    idx:0, tipi:[tipiBase[(0+offset)%6], tipiBase[(1+offset)%6]], variazione:null },
    { giorno:"Martedì",   idx:1, tipi:[tipiBase[(2+offset)%6], tipiBase[(3+offset)%6]], variazione:null },
    { giorno:"Mercoledì", idx:2, tipi:[tipiBase[(0+offset)%6], tipiBase[(4+offset)%6]], variazione:null },
    { giorno:"Giovedì",   idx:3, tipi:[tipiBase[(5+offset)%6]],                         variazione:null },
    { giorno:"Venerdì",   idx:4, tipi:[tipiBase[(0+offset)%6], tipiBase[(2+offset)%6]], variazione:null },
    { giorno:"Sabato",    idx:5, tipi:[tipiBase[(4+offset)%6], tipiBase[(1+offset)%6]], variazione:null },
    { giorno:"Domenica",  idx:6, tipi:[],                                               variazione:"Nessuna raccolta" },
  ];
}

// Build calendariPerFrazione from saved data or generate defaults
var calendariPerFrazione = {};
frazioniNomi.forEach(function(f, i) {
  calendariPerFrazione[f] = defaultCalendario(i);
});

// Active calendar reference (changes with fraction selection)
var calendarioSettimanale = calendariPerFrazione[frazioneSelezionata];
var blockedDiffPerFrazione = {};
frazioniNomi.forEach(function(f) { blockedDiffPerFrazione[f] = {}; });

// blockedDiff is an alias for the current fraction
var blockedDiff = blockedDiffPerFrazione[frazioneSelezionata];

function selectFrazione(nome) {
  frazioneSelezionata = nome;
  calendarioSettimanale = calendariPerFrazione[nome];
  blockedDiff = blockedDiffPerFrazione[nome];
  renderFrazioni();
  renderWeekly();
  renderDiffCalendar();
}

// Persist calendar data su Firestore
function saveCalendari() {
  saveCalendariFirestore();
}

async function saveCalendariFirestore() {
  if (typeof comuneRef === 'undefined' || !comuneRef) return;
  try {
    await civicosEnsureFirebaseSession();
    await comuneRef.collection('calendari').doc('differenziata').set({
      perFrazione: calendariPerFrazione,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
  } catch(e) {
    console.error('[CivicOS] Errore salvataggio calendario Firestore:', e);
  }
}

async function loadCalendariFirestore() {
  if (typeof comuneRef === 'undefined' || !comuneRef) return false;
  try {
    await civicosEnsureFirebaseSession();
    var doc = await comuneRef.collection('calendari').doc('differenziata').get();
    if (!doc.exists) return false;
    var data = doc.data();
    if (!data || !data.perFrazione) return false;
    var perFrazione = data.perFrazione;
    frazioniNomi.forEach(function(f) {
      if (perFrazione[f]) {
        calendariPerFrazione[f] = perFrazione[f];
      }
    });
    calendarioSettimanale = calendariPerFrazione[frazioneSelezionata];
    return true;
  } catch(e) {
    console.error('[CivicOS] Errore caricamento calendario Firestore:', e);
    return false;
  }
}

function renderFrazioni() {
  var container = document.getElementById('frazioniList');
  container.innerHTML = '';
  frazioniNomi.forEach(function(f) {
    var isActive = f === frazioneSelezionata;
    var div = document.createElement('div');
    div.className = 'frazione-card' + (isActive ? ' active' : '');
    div.onclick = function() { selectFrazione(f); };
    var cal = calendariPerFrazione[f];
    var tipiCount = 0;
    cal.forEach(function(d) { tipiCount += d.tipi.length; });
    div.innerHTML =
      '<div class="frazione-name">' + escapeHtml(f) + '</div>' +
      '<div class="frazione-info">' + tipiCount + ' raccolte/settimana</div>';
    container.appendChild(div);
  });
}

function chipClass(tipo) {
  var t = tipo.toLowerCase();
  if (t==='umido') return 'chip-umido';
  if (t==='plastica') return 'chip-plastica';
  if (t==='carta') return 'chip-carta';
  if (t==='vetro') return 'chip-vetro';
  if (t==='metalli') return 'chip-metalli';
  return 'chip-secco';
}

function renderWeekly() {
  var tbody = document.getElementById('weeklyBody');
  tbody.innerHTML = '';
  calendarioSettimanale.forEach(function(day) {
    var tr = document.createElement('tr');
    var chips = day.tipi.map(function(t) {
      return '<span class="chip-inline '+chipClass(t)+'">'+t+'</span>';
    }).join('') || '<span style="color:#aaa;font-size:13px;">—</span>';
    var varHtml = day.variazione ? '<span class="variation-text">'+day.variazione+'</span>' : '<span style="color:#aaa;font-size:13px;">—</span>';
    tr.innerHTML =
      '<td><strong>'+day.giorno+'</strong></td><td>'+chips+'</td><td>'+varHtml+'</td>' +
      '<td><button class="btn btn-outline" style="font-size:12px;padding:4px 12px;" onclick="editWeekday('+day.idx+')">Modifica</button></td>';
    tbody.appendChild(tr);
  });
}

function editWeekday(idx) {
  var day = calendarioSettimanale[idx];
  document.getElementById('blockTitle').textContent = 'Modifica '+day.giorno;
  document.getElementById('blockContent').innerHTML =
    '<div class="detail-row"><span class="label">Tipi raccolta</span><span class="value">'+(day.tipi.join(', ')||'Nessuna')+'</span></div>' +
    '<div class="detail-row"><span class="label">Variazione attuale</span><span class="value">'+(day.variazione||'Nessuna')+'</span></div>';
  document.getElementById('blockReasonLabel').textContent = 'Variazione:';
  document.getElementById('blockReason').value = day.variazione || '';
  document.getElementById('blockReason').placeholder = 'Es: Raccolta posticipata, sospesa…';
  document.getElementById('blockActions').innerHTML =
    '<button class="btn btn-primary" onclick="saveWeekday('+idx+')">Salva variazione</button>' +
    '<button class="btn btn-outline" onclick="clearWeekday('+idx+')">Rimuovi variazione</button>';
  document.getElementById('blockPanel').classList.add('open');
  document.body.classList.add('panel-open');
}
function saveWeekday(idx) { calendarioSettimanale[idx].variazione = document.getElementById('blockReason').value.trim()||null; saveCalendari(); closeBlock(); renderWeekly(); }
function clearWeekday(idx) { calendarioSettimanale[idx].variazione = null; saveCalendari(); closeBlock(); renderWeekly(); }

function prevMonth(cal) {
  if (cal==='diff') { diffMonth--; if(diffMonth<0){diffMonth=11;diffYear--;} renderDiffCalendar(); }
  else { ingMonth--; if(ingMonth<0){ingMonth=11;ingYear--;} renderIngCalendar(); }
}
function nextMonth(cal) {
  if (cal==='diff') { diffMonth++; if(diffMonth>11){diffMonth=0;diffYear++;} renderDiffCalendar(); }
  else { ingMonth++; if(ingMonth>11){ingMonth=0;ingYear++;} renderIngCalendar(); }
}

function renderDiffCalendar() {
  document.getElementById('monthLabelDiff').textContent = mesiNomi[diffMonth]+' '+diffYear;
  var grid = document.getElementById('calGridDiff');
  grid.innerHTML = '';
  var first = new Date(diffYear,diffMonth,1);
  var last = new Date(diffYear,diffMonth+1,0);
  var startDow = (first.getDay()+6)%7;
  var today = new Date();
  var prevLast = new Date(diffYear,diffMonth,0);
  for (var i=startDow-1;i>=0;i--) { grid.appendChild(createDiffCell(new Date(diffYear,diffMonth-1,prevLast.getDate()-i),true,today)); }
  for (var d=1;d<=last.getDate();d++) { grid.appendChild(createDiffCell(new Date(diffYear,diffMonth,d),false,today)); }
  var total=startDow+last.getDate(); var rem=(7-(total%7))%7;
  for (var j=1;j<=rem;j++) { grid.appendChild(createDiffCell(new Date(diffYear,diffMonth+1,j),true,today)); }
}

function createDiffCell(date, otherMonth, today) {
  var div = document.createElement('div'); div.className='cal-day';
  if (otherMonth) div.classList.add('other-month');
  var key=dateKey(date); var isBlocked=blockedDiff[key];
  if (isBlocked) div.classList.add('blocked');
  if (date.getFullYear()===today.getFullYear()&&date.getMonth()===today.getMonth()&&date.getDate()===today.getDate()) div.classList.add('today');
  var dow=(date.getDay()+6)%7; var sched=calendarioSettimanale[dow];
  var html='<div class="day-num">'+date.getDate()+'</div>';
  if (isBlocked) { html+='<span class="cal-chip chip-blocked">🚫 Bloccato</span><div class="day-note">'+escapeHtml(isBlocked)+'</div>'; }
  else if (sched.tipi.length>0&&!otherMonth) {
    html+='<div class="day-types">';
    sched.tipi.forEach(function(t){ html+='<span class="cal-chip '+chipClass(t)+'">'+t+'</span>'; });
    html+='</div>';
    if (sched.variazione) html+='<div class="day-note">'+escapeHtml(sched.variazione)+'</div>';
  }
  div.innerHTML=html;
  if (!otherMonth) div.onclick=function(){ openDiffPanel(date,key,sched); };
  return div;
}

function openDiffPanel(date,key,sched) {
  var dayName=giorniNomi[(date.getDay()+6)%7];
  var dateStr=date.getDate()+' '+mesiNomi[date.getMonth()]+' '+date.getFullYear();
  document.getElementById('blockTitle').textContent=dayName+' '+dateStr;
  var isBlocked=blockedDiff[key]; var tipiStr=sched.tipi.join(', ')||'Nessuna raccolta';
  document.getElementById('blockContent').innerHTML=
    '<div class="detail-row"><span class="label">Raccolta prevista</span><span class="value">'+tipiStr+'</span></div>'+
    '<div class="detail-row"><span class="label">Stato</span><span class="value">'+(isBlocked?'<span class="status status-open">Bloccato</span>':'<span class="status status-done">Attivo</span>')+'</span></div>'+
    (isBlocked?'<div class="detail-row"><span class="label">Motivo</span><span class="value">'+escapeHtml(isBlocked)+'</span></div>':'');
  document.getElementById('blockReasonLabel').textContent='Motivo blocco:';
  document.getElementById('blockReasonLabel').style.display='';
  document.getElementById('blockReason').style.display='';
  document.getElementById('blockReason').value=isBlocked||'';
  document.getElementById('blockReason').placeholder='Es: Festa patronale, lavori stradali…';
  if (isBlocked) {
    document.getElementById('blockActions').innerHTML=
      '<button class="btn btn-success" onclick="unblockDiff(\''+key+'\')">Sblocca data</button>'+
      '<button class="btn btn-warning" onclick="updateBlockDiff(\''+key+'\')">Aggiorna motivo</button>';
  } else {
    document.getElementById('blockActions').innerHTML='<button class="btn btn-danger" onclick="blockDiff(\''+key+'\')">Blocca raccolta</button>';
  }
  document.getElementById('blockPanel').classList.add('open');
  document.body.classList.add('panel-open');
}
function blockDiff(key) { var r=document.getElementById('blockReason').value.trim(); if(!r){alert('Inserisci un motivo.');return;} blockedDiff[key]=r; saveCalendari(); closeBlock(); renderDiffCalendar(); }
function updateBlockDiff(key) { var r=document.getElementById('blockReason').value.trim(); if(!r){alert('Inserisci un motivo.');return;} blockedDiff[key]=r; saveCalendari(); closeBlock(); renderDiffCalendar(); }
function unblockDiff(key) { delete blockedDiff[key]; saveCalendari(); closeBlock(); renderDiffCalendar(); }

// ══════════════════════════════════════
// RACCOLTA INGOMBRANTI
// ══════════════════════════════════════
var ingSlotConfig = [
  { giorno: "Lunedì",    idx: 0, maxSlot: 5, fascia: "08:00 – 12:00" },
  { giorno: "Martedì",   idx: 1, maxSlot: 5, fascia: "08:00 – 12:00" },
  { giorno: "Mercoledì", idx: 2, maxSlot: 4, fascia: "08:00 – 12:00" },
  { giorno: "Giovedì",   idx: 3, maxSlot: 5, fascia: "14:00 – 18:00" },
  { giorno: "Venerdì",   idx: 4, maxSlot: 4, fascia: "08:00 – 12:00" },
  { giorno: "Sabato",    idx: 5, maxSlot: 3, fascia: "08:00 – 11:00" },
  { giorno: "Domenica",  idx: 6, maxSlot: 0, fascia: "—" },
];
var blockedIng = {};

// Bookings per date (mirrors prenotazioni data from the app)
var ingBookings = {
  "2026-03-20": [{ id:"PRE-001", tipo:"Mobili", indirizzo:"Via Roma 12, int. 3", note:"Divano e tavolo vecchi", stato:"Confermata" }],
  "2026-03-22": [{ id:"PRE-002", tipo:"Elettrodomestici", indirizzo:"Via dei Pini 5", note:"Lavatrice non funzionante", stato:"In attesa" }],
  "2026-03-18": [{ id:"PRE-003", tipo:"Materassi", indirizzo:"Piazza Italia 1, sc. B", note:"", stato:"Completata" }],
  "2026-03-25": [{ id:"PRE-004", tipo:"Elettronica", indirizzo:"Via Milano 33", note:"TV e monitor da smaltire", stato:"In attesa" }],
  "2026-03-19": [{ id:"PRE-005", tipo:"Mobili", indirizzo:"Viale Europa 8", note:"Armadio smontato, al piano terra", stato:"Confermata" }],
  "2026-03-23": [{ id:"PRE-006", tipo:"Altro", indirizzo:"Via Garibaldi 20", note:"Vecchie biciclette e attrezzi", stato:"In attesa" }],
};

function renderIngWeekly() {
  var tbody = document.getElementById('ingWeeklyBody');
  tbody.innerHTML = '';
  ingSlotConfig.forEach(function(day) {
    var tr = document.createElement('tr');
    tr.innerHTML =
      '<td><strong>'+day.giorno+'</strong></td>'+
      '<td><strong>'+day.maxSlot+'</strong> ritiri/giorno</td>'+
      '<td>'+day.fascia+'</td>'+
      '<td><button class="btn btn-outline" style="font-size:12px;padding:4px 12px;" onclick="editIngSlot('+day.idx+')">Modifica</button></td>';
    tbody.appendChild(tr);
  });
}

function editIngSlot(idx) {
  var day = ingSlotConfig[idx];
  document.getElementById('blockTitle').textContent = 'Modifica slot – '+day.giorno;
  document.getElementById('blockContent').innerHTML =
    '<div class="detail-row"><span class="label">Slot attuali</span><span class="value">'+day.maxSlot+' ritiri</span></div>'+
    '<div class="detail-row"><span class="label">Fascia oraria</span><span class="value">'+day.fascia+'</span></div>'+
    '<div style="margin-top:12px;"><label style="font-size:13px;color:#888;">Nuovi slot:</label>'+
    '<input type="number" id="editSlotNum" min="0" max="20" value="'+day.maxSlot+'" style="width:80px;padding:6px 10px;border:1px solid #ddd;border-radius:8px;margin-left:8px;font-size:14px;"/></div>'+
    '<div style="margin-top:8px;"><label style="font-size:13px;color:#888;">Fascia oraria:</label>'+
    '<input type="text" id="editSlotFascia" value="'+day.fascia+'" style="width:160px;padding:6px 10px;border:1px solid #ddd;border-radius:8px;margin-left:8px;font-size:14px;"/></div>';
  document.getElementById('blockReasonLabel').style.display='none';
  document.getElementById('blockReason').style.display='none';
  document.getElementById('blockActions').innerHTML =
    '<button class="btn btn-primary" onclick="saveIngSlot('+idx+')">Salva</button>';
  document.getElementById('blockPanel').classList.add('open');
  document.body.classList.add('panel-open');
}

function saveIngSlot(idx) {
  var numEl = document.getElementById('editSlotNum');
  var fasciaEl = document.getElementById('editSlotFascia');
  if (numEl) ingSlotConfig[idx].maxSlot = parseInt(numEl.value)||0;
  if (fasciaEl) ingSlotConfig[idx].fascia = fasciaEl.value.trim()||'—';
  closeBlock(); renderIngWeekly(); renderIngCalendar();
}

function renderIngCalendar() {
  document.getElementById('monthLabelIng').textContent = mesiNomi[ingMonth]+' '+ingYear;
  var grid = document.getElementById('calGridIng');
  grid.innerHTML = '';
  var first=new Date(ingYear,ingMonth,1); var last=new Date(ingYear,ingMonth+1,0);
  var startDow=(first.getDay()+6)%7; var today=new Date();
  var prevLast=new Date(ingYear,ingMonth,0);
  var totalSlots=0, bookedSlots=0, blockedCount=0;

  for (var i=startDow-1;i>=0;i--) grid.appendChild(createIngCell(new Date(ingYear,ingMonth-1,prevLast.getDate()-i),true,today));
  for (var d=1;d<=last.getDate();d++) {
    var date=new Date(ingYear,ingMonth,d);
    var key=dateKey(date); var dow=(date.getDay()+6)%7;
    var maxS=ingSlotConfig[dow].maxSlot;
    if (blockedIng[key]) { blockedCount++; }
    else if (maxS>0) { totalSlots+=maxS; bookedSlots+=(ingBookings[key]||[]).length; }
    grid.appendChild(createIngCell(date,false,today));
  }
  var total2=startDow+last.getDate(); var rem=(7-(total2%7))%7;
  for (var j=1;j<=rem;j++) grid.appendChild(createIngCell(new Date(ingYear,ingMonth+1,j),true,today));

  document.getElementById('statSlotTotal').textContent=totalSlots;
  document.getElementById('statSlotBooked').textContent=bookedSlots;
  document.getElementById('statSlotFree').textContent=totalSlots-bookedSlots;
  document.getElementById('statSlotBlocked').textContent=blockedCount;
}

function createIngCell(date,otherMonth,today) {
  var div=document.createElement('div'); div.className='cal-day';
  if (otherMonth) div.classList.add('other-month');
  var key=dateKey(date); var isBlocked=blockedIng[key];
  if (isBlocked) div.classList.add('blocked');
  if (date.getFullYear()===today.getFullYear()&&date.getMonth()===today.getMonth()&&date.getDate()===today.getDate()) div.classList.add('today');
  var dow=(date.getDay()+6)%7; var maxS=ingSlotConfig[dow].maxSlot;
  var booked=(ingBookings[key]||[]).length;
  var html='<div class="day-num">'+date.getDate()+'</div>';

  if (isBlocked) {
    html+='<span class="cal-chip chip-blocked">🚫 Bloccato</span><div class="day-note">'+escapeHtml(isBlocked)+'</div>';
  } else if (maxS===0) {
    html+='<span class="cal-chip chip-noservice">No servizio</span>';
  } else if (!otherMonth) {
    var pct=Math.round((booked/maxS)*100);
    var barClass = pct<60?'low':pct<90?'med':'high';
    html+='<div class="ing-slots">';
    html+='<span class="ing-label">'+booked+'/'+maxS+' prenotati</span>';
    html+='<div class="ing-bar"><div class="ing-bar-fill '+barClass+'" style="width:'+Math.min(pct,100)+'%"></div></div>';
    if (booked>=maxS) html+='<span class="cal-chip chip-full" style="margin-top:3px;">Completo</span>';
    html+='</div>';
  }
  div.innerHTML=html;
  if (!otherMonth) div.onclick=function(){ openIngPanel(date,key,maxS,booked); };
  return div;
}

function openIngPanel(date,key,maxS,booked) {
  var dayName=giorniNomi[(date.getDay()+6)%7];
  var dateStr=date.getDate()+' '+mesiNomi[date.getMonth()]+' '+date.getFullYear();
  document.getElementById('blockTitle').textContent='🚛 '+dayName+' '+dateStr;
  var isBlocked=blockedIng[key];
  var bookings=ingBookings[key]||[];

  document.getElementById('blockContent').innerHTML=
    '<div class="detail-row"><span class="label">Slot massimi</span><span class="value">'+maxS+'</span></div>'+
    '<div class="detail-row"><span class="label">Prenotati</span><span class="value">'+booked+'</span></div>'+
    '<div class="detail-row"><span class="label">Disponibili</span><span class="value">'+(maxS-booked)+'</span></div>'+
    '<div class="detail-row"><span class="label">Stato</span><span class="value">'+(isBlocked?'<span class="status status-open">Bloccato</span>':booked>=maxS?'<span class="status status-open">Completo</span>':'<span class="status status-done">Disponibile</span>')+'</span></div>'+
    (isBlocked?'<div class="detail-row"><span class="label">Motivo</span><span class="value">'+escapeHtml(isBlocked)+'</span></div>':'');

  document.getElementById('blockReasonLabel').style.display='';
  document.getElementById('blockReason').style.display='';
  document.getElementById('blockReasonLabel').textContent='Motivo blocco:';
  document.getElementById('blockReason').value=isBlocked||'';
  document.getElementById('blockReason').placeholder='Es: Mezzo guasto, festività…';

  if (isBlocked) {
    document.getElementById('blockActions').innerHTML=
      '<button class="btn btn-success" onclick="unblockIng(\''+key+'\')">Sblocca data</button>'+
      '<button class="btn btn-warning" onclick="updateBlockIng(\''+key+'\')">Aggiorna motivo</button>';
  } else {
    document.getElementById('blockActions').innerHTML=
      '<button class="btn btn-danger" onclick="blockIng(\''+key+'\')">Blocca ritiri</button>';
  }
  document.getElementById('blockPanel').classList.add('open');
  document.body.classList.add('panel-open');

  // Show day bookings table below
  var detail=document.getElementById('ingDayDetail');
  var tbody=document.getElementById('ingDayBody');
  if (bookings.length>0) {
    detail.hidden=false;
    document.getElementById('ingDayTitle').textContent='Prenotazioni – '+dayName+' '+dateStr;
    tbody.innerHTML='';
    bookings.forEach(function(b) {
      var sc=b.stato==='Confermata'?'status-confirmed':b.stato==='In attesa'?'status-open':'status-done';
      var tr=document.createElement('tr');
      tr.innerHTML='<td><strong>'+b.id+'</strong></td><td>'+b.tipo+'</td><td>'+b.indirizzo+'</td><td>'+(b.note||'–')+'</td><td><span class="status '+sc+'">'+b.stato+'</span></td>';
      tbody.appendChild(tr);
    });
  } else {
    detail.hidden=true;
  }
}

function blockIng(key) { var r=document.getElementById('blockReason').value.trim(); if(!r){alert('Inserisci un motivo.');return;} blockedIng[key]=r; closeBlock(); renderIngCalendar(); }
function updateBlockIng(key) { var r=document.getElementById('blockReason').value.trim(); if(!r){alert('Inserisci un motivo.');return;} blockedIng[key]=r; closeBlock(); renderIngCalendar(); }
function unblockIng(key) { delete blockedIng[key]; closeBlock(); renderIngCalendar(); }

// ══════════════════════════════════════
// COMMON
// ══════════════════════════════════════
function closeBlock() {
  document.getElementById('blockPanel').classList.remove('open');
  document.body.classList.remove('panel-open');
  document.getElementById('blockReasonLabel').style.display='';
  document.getElementById('blockReason').style.display='';
}

// ── INIT ──
async function initCalendario() {
  await loadCalendariFirestore();
  renderFrazioni();
  renderWeekly();
  renderDiffCalendar();
}

initCalendario();
