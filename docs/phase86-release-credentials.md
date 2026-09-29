# Phase 86: release credentials and branch controls

The native Maps key found in the repository's earlier Git history must be **rotated in Google Cloud**. Removing it from the current tree does not revoke a key already exposed in history. Use a new Android restricted key for `com.movera.rider`, restricted to the app's release certificate SHA-1 and only the Maps SDK for Android APIs actually used. Update the CI or local `MAPS_API_KEY` secret with that new key. Revoke the old key after the replacement is working. Do not paste either key into an issue or PR.

The web key served in `index.html` is public by design. In Google Cloud, restrict it to HTTP referrers `https://baccarisverige-ux.github.io/*` (and any other **actual** deployed origin) and only Maps JavaScript API, with appropriate quota limits. Verify the restrictions in the Cloud console. The repository cannot assert that account-side changes were made.

For Android release signing, set these GitHub Actions secrets:

- `MOVERA_RELEASE_KEYSTORE_BASE64`: base64 of the private release keystore.
- `MOVERA_RELEASE_STORE_PASSWORD`, `MOVERA_RELEASE_KEY_ALIAS`, `MOVERA_RELEASE_KEY_PASSWORD`.

Run the manual **Android release signing check** workflow after setting the secrets. The build fails if signing variables are absent, and the workflow verifies the resulting APK certificate. Store the keystore and passwords in a durable credential vault; losing the signing key can prevent future app updates. The fixed application ID is `com.movera.rider`.

Protect `main` in GitHub repository rules: require a pull request and passing checks, disallow bypass by GitHub Actions, and restrict direct pushes. The retired upload extraction workflow was removed because it retained a `HEAD:main` push. The web publish job now uses a regular push to `web-live`, so a non-fast-forward update fails instead of force-replacing branch history. Only that job receives repository write permission; all other workflow code runs read-only. These branch rules and Google Cloud restrictions must be applied and verified by an account administrator.
