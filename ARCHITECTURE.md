# CLAUDE.md

Guidance for AI agents working in this repo.

## What this project is

A Flutter portfolio app being migrated module-by-module from a setState demo to **Clean Architecture + Riverpod (hand-written, no codegen) + go_router**. The canonical spec is [docs/BUILD_SPEC.md](docs/BUILD_SPEC.md) — read it before touching any module. Migration progress is tracked in [docs/MIGRATION_STATUS.md](docs/MIGRATION_STATUS.md).

## Conventions (non-negotiable, enforced across every module)

- **No Riverpod codegen.** Providers/Notifiers are hand-written (`Ref` directly, Riverpod 3.x — no `XxxProviderRef` subclasses).
- **`Result<F extends Failure, T>` is the only error-carrying return type** from `data/` and `domain/` layers. No layer above `data/` uses `try/catch` for *expected* failures (validation, not-found, conflict, network). `try/catch` is only legitimate at the actual I/O boundary inside a datasource, where it gets translated into a typed `Failure` and wrapped in `Result`.
- **Usecases only where they earn their keep** (real validation/coordination/business rules) — a plain field read goes straight from repository to Notifier. Don't wrap every repository call in a `GetXUseCase` for its own sake.
- **JSON-file-backed mock persistence**, not in-memory-only: datasources depend on the `LocalApiClient` interface (`core/storage/local_api_client.dart`), implemented by `JsonLocalApiClient`, which reads/writes copies of `assets/mock/*.json` seeded into the app documents directory by `AssetSeeder`, so writes (register, place order, edit profile) actually persist across app restarts. Tests inject `FakeLocalApiClient` (`test/helpers/`) instead — an in-memory double, no real file I/O.
- **Module boundaries**: `domain/` has no Flutter or data-layer imports; `data/` implements `domain/repositories/*` contracts and knows about JSON shapes; `presentation/` never imports datasources directly, only usecases/repositories through providers.

## Required gate before every commit

```
flutter analyze && flutter test
```
Must be clean/green. For UI-affecting changes, also smoke-test via the `run` skill (boot the app, exercise the golden path) before calling a module done.

## Testing conventions

See `docs/BUILD_SPEC.md` §12. Summary: fake repositories for usecase tests (no Riverpod/Flutter imports), `ProviderContainer` + overrides for Notifier tests, `fake_async` (never a real `Future.delayed` wait) for anything touching `Debouncer`. Shared fakes live in `test/helpers/`.
