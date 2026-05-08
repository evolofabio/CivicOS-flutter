/* Stemmi dei comuni (URL immagini) – aggiungere qui gli stemmi disponibili */
var _comuniStemmi = {
  'Mileto': 'stemmi/mileto.png',
  'Vibo Valentia': 'stemmi/vibo-valentia.png',
  'Tropea': 'stemmi/tropea.png',
  'Serra San Bruno': 'stemmi/serra-san-bruno.png',
  'Nicotera': 'stemmi/nicotera.png'
};

/* ── CivicOS Portale – Auth & Comune shared logic ── */

(function () {
  // Auth guard
  var auth = sessionStorage.getItem('civicos_auth');
  if (!auth || !JSON.parse(auth).loggedIn) {
    window.location.href = 'portale.html';
    return;
  }

  var parsed = JSON.parse(auth);

  // Ensure comune is set
  if (!parsed.comune) {
    sessionStorage.removeItem('civicos_auth');
    window.location.href = 'portale.html';
    return;
  }

  var comuneName = parsed.comune;

  setupSidebarLogo();

  // Update browser tab title with comune name
  var baseTitle = document.title.replace(/CivicOS\s*[–—-]?\s*/, '').trim();
  document.title = 'CivicOS – ' + (baseTitle || 'Dashboard') + ' – ' + comuneName;

  // Set comune name in sidebar
  var h2 = document.querySelector('.sidebar h2');
  if (h2) {
    h2.innerHTML = '<small style="font-size:10px;opacity:0.7;display:block;letter-spacing:0.5px;">CivicOS+</small>' + escapeH(comuneName);
    h2.style.fontSize = '16px';
    h2.style.lineHeight = '1.3';
  }

  // Populate comune header in sidebar
  var comuneHeader = document.getElementById('comuneHeader');
  if (comuneHeader) {
    var stemmaUrl = _comuniStemmi[comuneName] || null;
    var avatarHtml;
    if (stemmaUrl) {
      avatarHtml = '<img class="comune-stemma" src="' + stemmaUrl + '" alt="Stemma ' + escapeH(comuneName) + '" onerror="this.outerHTML=\'<div class=comune-avatar>' + escapeH(comuneName).charAt(0).toUpperCase() + '</div>\'">';
    } else {
      avatarHtml = '<div class="comune-avatar">' + escapeH(comuneName).charAt(0).toUpperCase() + '</div>';
    }
    comuneHeader.innerHTML = avatarHtml +
      '<div class="comune-nome">Comune di ' + escapeH(comuneName) + '</div>' +
      '<div class="comune-provincia">Provincia di Vibo Valentia</div>';
  }

  // Set page title comune name on all h1 elements in .main
  var allH1 = document.querySelectorAll('.main h1');
  allH1.forEach(function(h1) {
    if (!h1.querySelector('.comune-context')) {
      var comuneSpan = document.createElement('small');
      comuneSpan.className = 'comune-context';
      comuneSpan.style.cssText = 'display:block;font-size:13px;color:#888;font-weight:400;margin-top:2px;';
      comuneSpan.textContent = 'Comune di ' + comuneName;
      h1.appendChild(comuneSpan);
    }
  });

  // Replace any static comune placeholder in page content
  var comuneLabels = document.querySelectorAll('[data-comune-label]');
  comuneLabels.forEach(function(el) {
    el.textContent = el.getAttribute('data-comune-label').replace('{comune}', comuneName);
  });

  // Set user info badge if sidebar supports it
  var logoutLink = document.querySelector('.sidebar .logout-link');
  if (logoutLink && parsed.nome) {
    var userBadge = document.createElement('div');
    userBadge.style.cssText = 'padding:10px 28px 8px;font-size:11px;color:rgba(255,255,255,.5);border-top:1px solid rgba(255,255,255,.1);';
    userBadge.innerHTML = '👤 ' + escapeH(parsed.nome) + ' ' + escapeH(parsed.cognome || '') +
      '<br><span style="font-size:10px;text-transform:capitalize;">' + escapeH((parsed.role || '').replace('_', ' ')) + '</span>';
    logoutLink.parentNode.insertBefore(userBadge, logoutLink);
  }

  setupA11yAndMobileSidebar();

  function setupSidebarLogo() {
    var logoImg = document.querySelector('.sidebar > div img, .sidebar .sidebar-brand img');
    if (!logoImg) return;

    var container = logoImg.closest('div');
    if (container) container.classList.add('sidebar-brand');

    if (!logoImg.parentElement.classList.contains('sidebar-brand-shell')) {
      var shell = document.createElement('div');
      shell.className = 'sidebar-brand-shell';
      logoImg.parentNode.insertBefore(shell, logoImg);
      shell.appendChild(logoImg);
    }

    logoImg.loading = 'eager';
    logoImg.decoding = 'async';
    logoImg.referrerPolicy = 'no-referrer';

    logoImg.addEventListener('error', function onErr() {
      if (!logoImg.dataset.fallbackTried) {
        logoImg.dataset.fallbackTried = '1';
        logoImg.src = 'CivicOS-Remove.png';
        return;
      }
      logoImg.style.display = 'none';
      var shell = logoImg.closest('.sidebar-brand-shell');
      if (shell) {
        shell.innerHTML = '<span style="font-weight:800;font-size:18px;color:#0D3B66;letter-spacing:.5px">CivicOS</span>';
      }
    }, { once: true });
  }

  function setupA11yAndMobileSidebar() {
    var main = document.querySelector('.main');
    var sidebar = document.querySelector('.sidebar');
    if (!main || !sidebar) return;

    if (!main.id) main.id = 'mainContent';

    var skip = document.createElement('a');
    skip.className = 'skip-link';
    skip.href = '#mainContent';
    skip.textContent = 'Salta al contenuto';
    document.body.insertBefore(skip, document.body.firstChild);

    var toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'sidebar-toggle';
    toggle.setAttribute('aria-label', 'Apri menu navigazione');
    toggle.setAttribute('aria-controls', 'civicosSidebar');
    toggle.setAttribute('aria-expanded', 'false');
    toggle.innerHTML = '&#9776;';

    if (!sidebar.id) sidebar.id = 'civicosSidebar';

    var backdrop = document.createElement('div');
    backdrop.className = 'sidebar-backdrop';
    backdrop.setAttribute('aria-hidden', 'true');

    document.body.appendChild(toggle);
    document.body.appendChild(backdrop);

    function openSidebar() {
      document.body.classList.add('sidebar-open');
      toggle.setAttribute('aria-expanded', 'true');
      toggle.setAttribute('aria-label', 'Chiudi menu navigazione');
    }

    function closeSidebar() {
      document.body.classList.remove('sidebar-open');
      toggle.setAttribute('aria-expanded', 'false');
      toggle.setAttribute('aria-label', 'Apri menu navigazione');
    }

    toggle.addEventListener('click', function() {
      if (document.body.classList.contains('sidebar-open')) closeSidebar();
      else openSidebar();
    });

    backdrop.addEventListener('click', closeSidebar);

    document.addEventListener('keydown', function(ev) {
      if (ev.key === 'Escape') closeSidebar();
    });

    sidebar.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function() {
        if (window.matchMedia('(max-width: 900px)').matches) closeSidebar();
      });
    });
  }

  function escapeH(t) {
    var d = document.createElement('div');
    d.textContent = t;
    return d.innerHTML;
  }
})();

/* Global helpers */
function civicosGetAuth() {
  var raw = sessionStorage.getItem('civicos_auth');
  return raw ? JSON.parse(raw) : null;
}

function civicosGetComune() {
  var auth = civicosGetAuth();
  return auth ? auth.comune : null;
}

function civicosGetComuneConfig() {
  var comune = civicosGetComune();
  if (!comune) return null;
  var raw = localStorage.getItem('civicos_comuni_config');
  if (!raw) return null;
  var all = JSON.parse(raw);
  return all[comune] || null;
}

function civicosGetFrazioni() {
  var config = civicosGetComuneConfig();
  return (config && config.frazioni) ? config.frazioni : [];
}

function civicosStorageKey(prefix) {
  var comune = civicosGetComune();
  return comune ? prefix + '_' + comune : prefix;
}

/* Coordinate GPS dei comuni della provincia di Vibo Valentia */
var _comuniCoords = {
  'Acquaro':[38.5536,16.1892],'Arena':[38.5617,16.2125],'Briatico':[38.7283,16.0336],
  'Brognaturo':[38.5853,16.3453],'Capistrano':[38.6861,16.2889],'Cessaniti':[38.6656,16.0250],
  'Dasà':[38.5611,16.1964],'Dinami':[38.5286,16.1528],'Drapia':[38.6697,15.9128],
  'Fabrizia':[38.4817,16.3003],'Filadelfia':[38.7222,16.2897],'Filandari':[38.6186,16.0281],
  'Francavilla Angitola':[38.7775,16.2753],'Francica':[38.6175,16.1006],
  'Gerocarne':[38.5858,16.2211],'Ionadi':[38.6686,16.0667],'Joppolo':[38.5867,15.8989],
  'Limbadi':[38.5575,15.9656],'Maierato':[38.7072,16.1878],'Mileto':[38.6078,16.0692],
  'Mongiana':[38.5136,16.3208],'Monterosso Calabro':[38.7236,16.2842],
  'Nardodipace':[38.4703,16.3456],'Nicotera':[38.5492,15.9344],'Parghelia':[38.6811,15.9211],
  'Pizzo':[38.7344,16.1589],'Pizzoni':[38.6250,16.2528],'Polia':[38.7478,16.3111],
  'Ricadi':[38.6286,15.8714],'Rombiolo':[38.5939,16.0017],
  'San Calogero':[38.5758,16.0178],'San Costantino Calabro':[38.6311,16.0750],
  "San Gregorio d'Ippona":[38.6411,16.1017],'San Nicola da Crissa':[38.6667,16.2917],
  "Sant'Onofrio":[38.6972,16.1456],'Serra San Bruno':[38.5697,16.3289],
  'Simbario':[38.6083,16.3375],'Soriano Calabro':[38.5950,16.2297],
  'Spadola':[38.5858,16.3417],'Spilinga':[38.6272,15.9006],
  'Stefanaconi':[38.6758,16.1228],'Tropea':[38.6719,15.8969],
  'Vallelonga':[38.6458,16.2897],'Vazzano':[38.6350,16.2486],
  'Vibo Valentia':[38.6758,16.0994],'Zaccanopoli':[38.6567,15.9361],
  'Zambrone':[38.6967,15.9811],'Zungri':[38.6539,15.9825]
};

function civicosGetComuneCoords() {
  var comune = civicosGetComune();
  if (!comune) return [38.67, 16.10];
  return _comuniCoords[comune] || [38.67, 16.10];
}

function civicosLogout() {
  sessionStorage.removeItem('civicos_auth');
  window.location.href = 'portale.html';
}
