
# ProxSync

A modular Swift Package suite for **nearby ingest → local health (optional) → cloud upload** with a **Supabase** backend and **SwiftData** offline queue.
Use any payload (not concussion-specific).

**Modules**
- ProxSyncCore – core protocols & types
- ProxSyncNearby – MultipeerConnectivity wrapper (optional)
- ProxSyncHealth – HealthKit writer (optional)
- ProxSyncREST – minimal REST client + uploader
- ProxSyncLocal – SwiftData outbox & local cache
- ProxSyncSupabase – Supabase store (PostgREST + GoTrue)

Target iOS 16+. HealthKit is optional (only link when used).
