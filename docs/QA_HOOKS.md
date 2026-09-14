# QA hooks (`window.movera*`)

Public GitHub Pages **release** builds do **not** expose:

- `moveraSeedActiveRide`
- `moveraClearActiveRide`
- `moveraAssignDriver`
- `moveraHoldMatching`
- `moveraOpenSafety`

Hooks install only when `kDebugMode` **or** `--dart-define=MOVERA_QA=true`.

`qa-live-rider-flow.yml` depends on these hooks — run it against a QA-enabled
web build, not the ungated public release. Do not leave hooks ungated just to
keep that workflow green.
