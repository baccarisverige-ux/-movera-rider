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
