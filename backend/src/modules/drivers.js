const store = new Map();
function handle(req, res, requestId) {
  return { code: 'OK', module: 'drivers', requestId, items: Array.from(store.values()) };
}
module.exports = { handle, store };
