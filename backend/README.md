# Rider `backend/` — unused Node mock (R2)

**Decision (21 September 2026): do not adopt this tree.**

The live Rider mock is `lib/core/api/in_process_mock_client.dart`. Nothing in
the Flutter app calls this Node process. The two copies are not kept in parity
and must not be treated as a second source of truth.

Keep the folder frozen until P3 (`movera-contracts`) exists. Then either:

1. Delete this tree, or
2. Generate a server from the OpenAPI contract and add a parity test against
   `InProcessMockClient`.

Do not add routes here in the meantime.
