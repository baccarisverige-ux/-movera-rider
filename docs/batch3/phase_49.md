# Batch 3 — Phase 49

**Status:** Draft workstream created from the Batch 3 baseline. Implementation must be investigated against the latest merged `main` before certification and merge.

## Scope
Scheduled rides, PIN, waiting/no-show and remaining flows.

## Batch 3 safety rules
- One phase / one PR.
- No redesign unless required by this phase.
- Preserve existing working lifecycle behavior.
- Replace source-text assertions with behavioral coverage where this phase touches them.
- Run phase-specific tests plus Architecture gates, Global E2E UAT, Deep Safe Recertification, and Backend Readiness Gate.
- Before merge, update against the latest `main`, inspect the final diff, and rerun certification.
- Never merge while red, conflicted, or behind an earlier required Batch 3 dependency.

## Dependency note
Phase 42 is intentionally not created/implemented yet because payment timing is a product decision gate.
