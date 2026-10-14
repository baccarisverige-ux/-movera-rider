import 'package:movera_rider/core/auth/token_store.dart';

import 'package:movera_rider/core/auth/web_session_token_store_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/auth/web_session_token_store_web.dart';

/// The browser token store, or null where there is no browser.
///
/// Web keeps the tokens in this tab's sessionStorage so a reload keeps the
/// rider signed in (and their live ride on screen). Why sessionStorage:
/// - it is scoped to one tab and one origin and is gone when the tab closes,
///   so a later visitor on a shared computer does not inherit the session;
/// - unlike a cookie it is never sent with requests, so it adds no CSRF
///   surface;
/// - script injected into the page could read it, but such script could
///   already call the API with an in-memory token, so the added exposure is
///   the token outliving the page, bounded by the tab's lifetime.
/// localStorage was rejected because it outlives the tab and is shared by
/// every tab. An httpOnly refresh cookie set by the server would be better
/// still and can replace this once the backend offers it.
/// Sign-out and session expiry call [TokenStore.clear], which removes both
/// keys.
TokenStore? webSessionTokenStore() => createWebSessionTokenStore();
