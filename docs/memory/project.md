# Stable Project Facts

- CollabTasks is a Flutter/Dart application. See [`pubspec.yaml`](../../pubspec.yaml) for the dependency and SDK source
  of truth.
- The project uses Clean Architecture with Domain, Data, and UI layers, `flutter_bloc`, GetIt, Drift/SQLite, and
  `flutter_quill`. See [`AGENTS.md`](../../AGENTS.md) for binding rules and [`architecture.md`](../architecture.md) for
  the system overview.
- Feature documentation follows [`docs/features/template.md`](../features/template.md); tests are organized under
  `test/` by layer and feature.
- Backend service references are maintained in [`backend_services.md`](../backend_services.md).

Do not duplicate detailed architecture rules or transient task state here. Update this file only when a stable fact or
its source changes.
