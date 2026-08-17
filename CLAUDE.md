# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Start here

This repo has two hand-maintained docs written for AI agents — read them before making non-trivial changes; they are the source of truth and this file does not duplicate their detail:
- **`AGENTS.md`** — durable project context: architecture, Supabase conventions, domain decisions, roadmap, toolchain quirks, secrets handling.
- **`CONTINUACAO.md`** — session-to-session handoff: current state, the next immediate action, and a device-testing/adb playbook. Check it first to know where the last session left off.

Menuvem Lojista is a pricing tool for small merchants (e.g. pizzerias): shopping lists with per-item price tracking, an insumo (raw-ingredient) price-history library, and products with a "ficha técnica" (bill of materials) that computes cost and margin. Everything is pt-BR — class names, comments, UI strings, and domain terms (`Insumo`, `Produto`, `ListaCompras`, `Componente`) — match that in new code.

## Commands (Windows PowerShell, from repo root)

- Fastest correctness check: `.\gradlew.bat :app:compileDebugKotlin` (runs KSP + compiles)
- Build APK: `.\gradlew.bat :app:assembleDebug`
- Install on connected device: `.\gradlew.bat :app:installDebug` (~1m20s; needs the `-Xmx4g` heap already set in `gradle.properties` or D8 dexing OOMs)
- **No tests, no lint/detekt/ktlint exist.** Compilation is the only automated verification — there is no single-test command to reach for.

## Architecture

Native Android app (Kotlin + Jetpack Compose), single Gradle module `:app`, 100% online against Supabase — no local database (Room was removed). Entry: `MenuvemApplication` (`@HiltAndroidApp`) → `MainActivity`, which gates on `SessionStatus` (`Authenticated` → `MenuvemNavGraph`, `Initializing` → splash, else → `LoginScreen`).

Layers under `app/src/main/java/br/com/menuvem/lojista/`:
- `data/remote` — Supabase infra: `dto/` (serializable DTOs), `SupabaseTableFlow.kt` (reactive table flows, see below), `AuthManager.kt`
- `data/repository` — repository impls talking to PostgREST
- `domain` — `model` / `repository` (interfaces) / `usecase` (one class per use case); backend-agnostic, untouched by the Room→Supabase swap
- `presentation/<feature>` — Screen + `@HiltViewModel` + immutable `UiState` per feature (`auth`, `home`, `shopping`, `history`, `products`, `insumos`, `componentes`); shared composables in `presentation/components`; routes in `presentation/navigation/Screen.kt` + `MenuvemNavGraph.kt`
- `di` — Hilt modules: `SupabaseModule` provides the client, `RepositoryModule` binds repository impls (the one place a backend swap happens)
- `supabase/schema.sql` — DDL to run manually in the Supabase SQL editor (tables + RLS + Realtime publication)

Supabase conventions to follow when touching data code (full detail in `AGENTS.md`):
- Reactive lists use `client.tableListFlow(table, refreshSharedFlow) { fetch }` — mutations call `refresh.tryEmit(Unit)`; Realtime changes from other devices also trigger a re-fetch. Each flow needs a unique Realtime channel id (see `SupabaseTableFlow.kt`) — reusing one crashes.
- Insert DTOs never set `id`/`user_id`; `user_id` comes from the DB default `auth.uid()`. RLS (`auth.uid() = user_id` on every table) is the only access control — never filter by user client-side.
- Nulling a nullable column on update needs an explicit `JsonNull`; a plain Kotlin `null` in the typed `set()` builder doesn't serialize.
- New table → also add it to the `supabase_realtime` publication in `schema.sql`, or cross-device sync silently won't cover it.

Domain model, in brief: `Produto` (sellable item) has a **ficha técnica** = loose `ItemFichaTecnica` insumos + applied `Componente`s (reusable insumo bundles like "Massa" or "Sabor", each with a `multiplicador` for fractional sharing across multiple flavors on one pizza). `GetProdutosComCustoUseCase` reactively recomputes cost/margin whenever any insumo price changes. Full domain reasoning (unit conversion, loss %, componentes, pricing model, what's not yet built) lives in `AGENTS.md`'s "Domain decisions" section — read it before changing pricing/costing logic.

## Toolchain quirks (full list in `AGENTS.md`)

Bleeding-edge versions (Gradle 9.7.0, AGP 9.3.0, Kotlin 2.3.0) — notably **no `org.jetbrains.kotlin.android` plugin** (AGP 9 has built-in Kotlin support; don't add it back). In `app/build.gradle.kts`, `import java.util.Properties` is required at the top because `java` resolves to an AGP extension there, not the JDK package.

## Roadmap direction

**Update (2026-08-16): the app is being rewritten in Flutter/Dart for Windows + Android** (a Kotlin Multiplatform desktop port was attempted and abandoned after repeated AGP9/Compose-Multiplatform toolchain instability — see git history around this date if reviving that attempt is ever considered). This file still describes the last known-good Kotlin/Android app, kept for reference while the Flutter rewrite is in progress; it will need a full rewrite once the Flutter app is the primary codebase. The domain decisions in `AGENTS.md` remain the spec to follow regardless of implementation language.
