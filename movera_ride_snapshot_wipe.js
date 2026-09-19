// Movera public web: wipe active-ride snapshot keys only (not theme/prefs).
(function() {
  var needle = 'movera_active_ride';
  function wipeLocal() {
    try {
      var remove = [];
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (k && k.indexOf(needle) !== -1) remove.push(k);
      }
      for (var j = 0; j < remove.length; j++) localStorage.removeItem(remove[j]);
    } catch (_) {}
  }
  function keyMatches(key) {
    try { return String(key).indexOf(needle) !== -1; } catch (_) { return false; }
  }
  function wipeStore(store) {
    return new Promise(function(resolve) {
      try {
        var req = store.openCursor();
        req.onsuccess = function(ev) {
          var cursor = ev.target.result;
          if (!cursor) { resolve(); return; }
          if (keyMatches(cursor.key)) {
            try { cursor.delete(); } catch (_) {}
          }
          cursor.continue();
        };
        req.onerror = function() { resolve(); };
      } catch (_) { resolve(); }
    });
  }
  function wipeDb(name) {
    return new Promise(function(resolve) {
      var open;
      try { open = indexedDB.open(name); } catch (_) { resolve(); return; }
      open.onerror = function() { resolve(); };
      open.onsuccess = function() {
        var db = open.result;
        try {
          var names = Array.prototype.slice.call(db.objectStoreNames || []);
          if (!names.length) { db.close(); resolve(); return; }
          var tx = db.transaction(names, 'readwrite');
          var tasks = names.map(function(n) { return wipeStore(tx.objectStore(n)); });
          Promise.all(tasks).then(function() { try { db.close(); } catch (_) {} resolve(); });
          tx.onerror = function() { try { db.close(); } catch (_) {} resolve(); };
        } catch (_) { try { db.close(); } catch (_) {} resolve(); }
      };
    });
  }
  function wipeIdb() {
    if (!window.indexedDB) return;
    var known = [
      'flutter_IndexedDB',
      'flutterLocalStorageDb',
      '_flutter_web_db',
      'FlutterSharedPreferences',
      'shared_preferences'
    ];
    var listPromise = indexedDB.databases
      ? indexedDB.databases().catch(function() { return []; })
      : Promise.resolve([]);
    listPromise.then(function(dbs) {
      var names = known.slice();
      (dbs || []).forEach(function(d) {
        if (d && d.name && names.indexOf(d.name) === -1) names.push(d.name);
      });
      return Promise.all(names.map(wipeDb));
    }).catch(function() {});
  }
  // An installed PWA is the rider's own app, not a link a stranger tapped, so
  // its in-progress ride must survive a reload. iOS evicts standalone web apps
  // readily -- a system permission dialog is enough -- and wiping here left
  // riders stranded on Home mid-booking. Browser tabs still get wiped: that is
  // what stops a leftover ride greeting whoever opens the public link.
  //
  // Both signals are needed. display-mode: standalone covers Android WebAPKs
  // and modern iOS; navigator.standalone is the only signal older iOS Safari
  // gives, and is undefined elsewhere.
  function isInstalledApp() {
    try {
      if (window.matchMedia &&
          window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }
    } catch (_) {}
    try { return navigator.standalone === true; } catch (_) { return false; }
  }

  window.moveraIsInstalledApp = isInstalledApp;
  window.moveraWipeRideSnapshotStorage = function() {
    wipeLocal();
    wipeIdb();
  };
  if (!isInstalledApp()) window.moveraWipeRideSnapshotStorage();
})();
