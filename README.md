# Movera Rider

This repository is the canonical source of truth for the **Movera Rider** Flutter application.

## Architecture

- `lib/features/rider/` — Rider-only product features and screens
- `lib/core/constants/` — app-wide constants, colors, assets and typography configuration
- `lib/core/services/` — Rider app services
- `lib/shared/models/` — Rider data models used across features
- `lib/shared/widgets/` — reusable UI widgets
- `lib/shared/presentation/` — shared presentation such as splash/onboarding
- `assets/` — original app assets, kept intact

Driver application code belongs only in the separate Movera Driver repository.
Generated Flutter/Gradle files, temporary upload ZIPs, and build output are intentionally not source-controlled.

## Google Maps configuration

Never commit Maps API keys. Android reads `MAPS_API_KEY` from a Gradle property or environment variable. iOS reads `GOOGLE_MAPS_API_KEY` from the Xcode build setting exposed through `Info.plist`.

## Web deployment

The Rider web build publishes to GitHub Pages from `main`. Pages deployments are serialized by the publish workflow so overlapping updates do not race each other.
