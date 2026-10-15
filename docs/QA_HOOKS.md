# QA hooks (`window.movera*`)

Public GitHub Pages **release** builds do **not** expose:

- `moveraSeedActiveRide`
- `moveraClearActiveRide`
- `moveraAssignDriver`
- `moveraHoldMatching`
- `moveraOpenSafety`

Hooks install only when `kDebugMode` **or** `--dart-define=MOVERA_QA=true`.

`qa-live-rider-flow.yml` against public Pages skips matching/restore hook steps.
Those still require a QA-enabled web build. Do not leave hooks ungated just to
keep that workflow green.

## Ride check (`moveraSimulateRideCheck`)

QA builds only (same gate). On the in-trip screen or the ride summary:

```js
moveraSimulateRideCheck('longStop', {place: 'Odenplan'})   // or stoppedMinutes
moveraSimulateRideCheck('droppedFar', {distanceMeters: 1200})
moveraSimulateRideCheck('offRoute', {distanceMeters: 2400}) // or {longerPercent: 60}
moveraSimulateRideCheck('possibleCrash')
JSON.parse(window.moveraRideCheckSnapshotJson)              // read-only state
```

The card opens at once; called on another screen, it waits for the next ride
screen. A trigger that admin turned off, or a rider who switched Ride check
off, opens nothing (same rules as live detection). Older names
(`unexpectedStop`, `routeDeviation`) still work.
