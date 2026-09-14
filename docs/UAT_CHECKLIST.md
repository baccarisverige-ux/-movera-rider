# Movera Rider UAT checklist

Manual / live checks derived from QA live Rider flow, plus cancel-first and
book-later regressions. Public Pages builds do **not** expose `window.movera*`
hooks unless built with debug or `--dart-define=MOVERA_QA=true`.

## Smoke

- [ ] Home loads without fatal console errors
- [ ] Destination → pickup confirm → Select Ride categories
- [ ] Fare stepper and payment sheet (Cash) change UI
- [ ] Book now → Finding Drivers
- [ ] Matching eventually opens Waiting (or assign via QA build)

## Cancel-first

- [ ] On Finding, open cancel → **Cancel request** immediately stops matching
- [ ] Why-sheet is optional after Cancel request
- [ ] **Keep ride** on why-sheet does **not** restore Finding — stay Home
- [ ] Late assign after Cancel request does not open Waiting / Finding
- [ ] Same cancel-first behavior on Waiting

## Book later

- [ ] Book for later date/time → Ride scheduled (or schedule confirmation)
- [ ] Book-later must **not** open Finding Drivers

## Restore

- [ ] Seeded Finding restore (QA build) first surface is Finding, not Home
- [ ] Seeded Waiting restore first surface is Waiting, not Home
- [ ] After cancel, cold restore / resume stays Home

## Safety / map (QA or manual)

- [ ] Safety hub from menu
- [ ] Nested pickup map owner does not stick after back
- [ ] Select Ride → Finding → Waiting map owners advance

## Mock contract

- [ ] Quotes return `quoteId == id`, SEK, ~120s expiry
- [ ] Ride create / cancel / nearby / price bump work on in-process mock
