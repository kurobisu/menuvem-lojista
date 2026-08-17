# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Start here

This repo has two hand-maintained docs written for AI agents — read them before making non-trivial changes; they are the source of truth and this file does not duplicate their detail:
- **`AGENTS.md`** — durable project context: domain decisions, Supabase conventions, roadmap, secrets handling.
- **`CONTINUACAO.md`** — session-to-session handoff: current state, the next immediate action, device-testing playbook. Check it first to know where the last session left off.

Menuvem Lojista is a pricing tool for small merchants (e.g. pizzerias): shopping lists with per-item price tracking, an insumo (raw-ingredient) price-history library, and products with a "ficha técnica" (bill of materials) that computes cost and margin. Everything is pt-BR — class names, comments, UI strings, and domain terms (`Insumo`, `Produto`, `ListaCompras`, `Componente`) — match that in new code.

## Stack

Flutter (Dart) app targeting **Windows + Android**, 100% online against Supabase — no local database. The Flutter project lives at the **repo root** (`lib/`, `android/`, `windows/`, `pubspec.yaml`).

A previous native Android app (Kotlin + Jetpack Compose) was rewritten in Flutter on 2026-08-16. That Kotlin code no longer exists in the working tree — if you need it as reference, it is preserved in git history (see commits up to `20fe316`, before the `feat: reescreve o app em Flutter` commit).

## Commands (Windows PowerShell, from repo root)

- Fastest correctness check: `flutter analyze` (the only automated verification — see below)
- Run on a device/emulator: `flutter run -d <device>` (`flutter devices` to list)
- Build Android APK: `flutter build apk --debug`
- Build Windows desktop: `flutter build windows` → `build\windows\x64\runner\Release\lojista.exe`
- Run in a browser (handy for quick UI checks): `flutter run -d web-server --web-port=8765`

**There are no meaningful tests.** `test/widget_test.dart` is a placeholder — testing the real screens needs a fake Supabase client that does not exist yet. `flutter analyze` is the only automated gate; it must be clean (the 5–6 `unnecessary_underscores` / `deprecated_member_use` infos are known and cosmetic).

## Architecture

Layers under `lib/`:
- `config/` — `env.dart` holds the Supabase URL + anon key and is **gitignored**; `env.example.dart` is the committed template. A fresh clone must copy the example to `env.dart` and fill it in, or the app won't compile.
- `domain/model/` — 16 plain Dart model classes (immutable, `copyWith`), backend-agnostic
- `domain/usecase/` — business logic as **top-level functions**, not classes (`cost_engine.dart`, `produto_usecases.dart`, …). `cost_engine.dart` is the heart: it combines multiple repository streams with `rxdart`'s `Rx.combineLatestN` so cost/margin recompute reactively whenever any insumo price changes.
- `data/` — one repository class per aggregate, talking directly to Supabase PostgREST. Reactive reads use `client.from(table).stream(primaryKey: ['id'])`, which is Realtime-backed.
- `presentation/<feature>/` — a `*_screen.dart` plus, where there is local UI state, a `*_controller.dart` with a Riverpod `Notifier` + immutable UiState. Features: `auth`, `home`, `shopping`, `history`, `products`, `insumos`, `componentes`; shared widgets in `presentation/components/`.
- `providers/` — `repository_providers.dart` (one provider per repository) and `auth_providers.dart`
- `router/app_router.dart` — go_router with auth gating via `redirect`
- `theme/app_theme.dart` — Material 3 theme + Menuvem brand colors
- `supabase/schema.sql` — DDL to run manually in the Supabase SQL editor (tables + RLS + Realtime publication). Shared with the old Kotlin app; unchanged by the rewrite.

## Conventions and gotchas

**Supabase** (full detail in `AGENTS.md`):
- RLS (`auth.uid() = user_id` on every table) is the only access control — never filter by user client-side.
- Insert payloads never set `id`/`user_id`; `user_id` comes from the DB default `auth.uid()`.
- New table → also add it to the `supabase_realtime` publication in `schema.sql`, or cross-device sync silently won't cover it.

**Three bugs already fixed here — don't reintroduce them:**
1. **Auth redirect race.** Do not read the auth session through a Riverpod `StreamProvider` in go_router's `redirect`. go_router's `refreshListenable` and the StreamProvider both subscribe to the same Supabase auth stream, and the redirect can run before Riverpod's cached value updates — leaving the user stuck on the login screen after a successful login. `isAuthenticatedProvider` reads `currentSession` synchronously from the SDK for exactly this reason.
2. **Locale.** `main()` must `await initializeDateFormatting('pt_BR')` before `runApp`, or any locale-aware `DateFormat` throws `LocaleDataException` at runtime.
3. **Navigation.** Use `context.push()` for drill-down navigation, not `context.go()` — `go()` replaces the route, so the AppBar gets no automatic back button.

**Dart/Flutter:**
- Money and quantities parse through `presentation/components/formatters.dart` (`parseDecimalPtBr` accepts comma decimals; `formatarMoeda` formats pt-BR).
- Prefer `.nonNulls` over the deprecated `whereNotNull()`.

## Domain model, in brief

`Produto` (sellable item) has a **ficha técnica** = loose `ItemFichaTecnica` insumos + applied `Componente`s (reusable insumo bundles like "Massa" or "Sabor", each with a `multiplicador` for fractional sharing across multiple flavors on one pizza). Cost flows: insumo `custoAtual` ÷ `fatorConversao` → cost per unit of use, adjusted by `perdaPercentual`. `precoSugerido = custoTotal / (1 - margemAlvo/100)`. Full domain reasoning (unit conversion, loss %, componentes, pricing model, what's not yet built) lives in `AGENTS.md`'s "Domain decisions" section — read it before changing pricing/costing logic.
