# AGENTS.md — Menuvem Lojista

Pricing tool for small merchants: shopping lists with price/weight per item, price-fluctuation history per insumo, and cost/profit margin impact on the store's products. This repo contains a **Flutter app targeting Windows + Android**, package `br.com.menuvem.lojista`, **100% online on Supabase** (email/password auth, RLS per user, Realtime sync). Class names, comments, and UI strings are in pt-BR (ListaCompras, Insumo, HistoricoPreco) — match that naming in new code.

## Secrets — read before touching git

- `lib/config/env.dart` holds `supabaseUrl` + `supabaseAnonKey` and is **gitignored — never commit it**. The GitHub repo may be public. `lib/config/env.example.dart` is the committed template; a fresh clone copies it to `env.dart` and fills in the values, otherwise the app won't compile.
- The Supabase **secret key (`sb_secret_...`) must never appear in this repo or in the app** — it bypasses RLS. Only the anon key belongs client-side.

## Roadmap

- **Supabase backend** — **done (Aug 2026)**: the app is 100% online, Supabase-only; there is no local database. Motivation: let Windows desktop + Android share the same backend. The features queue (despesas, canais, fornecedor) will be built directly on Supabase.
- **Windows desktop** — **done (Aug 2026)** via the Flutter rewrite (below). `flutter build windows` produces a working `lojista.exe`.
- **Flutter rewrite** — **done (2026-08-16)**: the app was a native Android app (Kotlin + Jetpack Compose) and was rewritten in Flutter to get Windows + Android from one codebase. A Kotlin Multiplatform / Compose-for-Desktop port was attempted first and abandoned after repeated AGP 9 / Compose-Multiplatform toolchain instability. The Kotlin code is **no longer in the working tree** — it is preserved in git history up to commit `20fe316`. Domain decisions below survived the rewrite unchanged and remain the spec.
- **OpenDelivery integration** — sales data ingested via API, feeding net-profit (lucro líquido) graphs and other metrics (net-profit formula and sale→product mapping are decided below).

## Domain decisions (aligned with the owner)

Products & ficha técnica — **implemented** (domain + repositories + screens):
- **New concepts**: `Produto` (item the store sells, e.g. Pizza Grande de Calabresa) and its **ficha técnica** (composition: which insumos + how much of each per portion). Implemented: domain models, `ProdutoRepository`, the cost engine (`getProdutosComCusto` in `lib/domain/usecase/cost_engine.dart` recomputes all product costs reactively when any insumo price changes), screens in `lib/presentation/products` (list + ficha técnica editor with duplicate-ficha shortcut) and `lib/presentation/insumos` (library with category filter), plus margin-drop alerts on Home. `Insumo` has a `categoria` field (INSUMO/EMBALAGEM).
- **Variations & combos**: Pizza P/M/G or a "pizza + drink" combo = separate products, each with its own ficha técnica; duplicate-ficha shortcut exists for fast entry.
- **Units**: insumo has a purchase unit + conversion factor to a base usage unit (kg→g, L→ml, box→unit). Ficha técnica quantities are expressed in the base unit; cost is prorated automatically (e.g. calabresa at R$ 46,18/kg → 150 g costs R$ 6,93).
- **Loss/yield**: optional % loss per ficha técnica item (default 0%; e.g. 1 kg of tomato yields 800 g, raising the real portion cost).
- **Insumo cost source**: auto-updated from finalized shopping lists (HistoricoPreco), with manual override in the insumo library ("biblioteca"). Finalizing a list records each paid price to `historico_precos` and sets the insumo's `custo_atual` to the last price paid (LIFO).
- **Packaging = categorized insumo**: caixa/copo/sacola is an insumo of category "embalagem" — reuses shopping lists, price history and unit conversion, and enters the ficha técnica as a normal item.
- **Componentes (blocos reutilizáveis de ficha técnica)** — **implemented**: a `Componente` is a reusable template of insumos (e.g. "Pizza - Massa Grande 35cm", "Pizza Sabor - Calabresa") stored in its own tables (`componentes`, `itens_componente`). A product's ficha técnica = **componentes aplicados** (`produto_componentes`, each with a `multiplicador`) + **insumos avulsos** (classic `itens_ficha_tecnica`). The multiplicador handles fractioning: sabor único = 1.0, 2 sabores na mesma massa = 0.5 (metade), 3 sabores = 1/3. Cost engine sums loose items + (component items × multiplicador). Screens: `lib/presentation/componentes` (library + editor) + "Componente"/"Insumo" buttons in product detail. "Copiar ficha" also copies `produto_componentes` — so a product can be fully cloned and its ficha edited. Sharing division is divisor-based (helpers `multiplicadorDeDivisor` / `divisorDeMultiplicador` / `descreverMultiplicador` in `lib/presentation/components/multiplicador_utils.dart`).
  - **Tipo de componente is user-defined, not a fixed enum** (changed 2026-08-18): originally `Componente.tipo` was a hardcoded `TipoComponente` enum (Massa/Sabor/Embalagem/Outro). It is now `Componente.tipoComponenteId` (nullable FK to its own `tipos_componente` table, `id`+`nome`+`ordem`+`data_criacao`, RLS'd per user). The type is entered as free text with autocomplete in `ComponenteFormDialog` (`lib/presentation/componentes/componente_form_dialog.dart`, a Flutter `Autocomplete<String>`) — typing an existing name reuses it (case-insensitive match), typing a new one creates it via `resolveTipoComponenteId` in `lib/domain/usecase/componente_usecases.dart`. No dedicated type-*management* screen exists (create/rename stays inline-only, by choice) but there IS a dedicated reorder screen (below) and types can be deleted from the filter chip's delete icon in `componentes_screen.dart` (`ComponenteRepository.deleteTipo` — FK is `on delete set null`, so components of that type just lose their type, they aren't deleted). `ComponenteComCusto` and `ProdutoComponenteCompleto` carry a resolved `tipoNome` (joined against `tipos_componente` inside `cost_engine.dart`'s `getComponentes`/`getProdutoComponentes`) so display code never needs to look the id up itself. The componentes-library filter chips (`componentes_screen.dart`) are built from the live `tiposComponenteProvider` stream, not a fixed list. Creating a componente while a type filter is active pre-fills that type in the form.
  - **Manual ordering** (added 2026-08-18): both `tipos_componente` and `componentes` have an `ordem integer` column (app-assigned on insert — new rows get `existentes.length`, i.e. appended at the end — not a DB default/trigger). Tipos are reordered on their own screen, `lib/presentation/componentes/tipos_reorder_screen.dart` (route `/componentes/tipos`, reached via the sort icon in the Componentes AppBar). Componentes are reordered inline in `componentes_screen.dart`, but **only when the "Todos" filter is active** — with a type filtered, only a subset of the list is visible, so dragging would silently reorder against components the user can't see; the screen falls back to a plain read-only list and shows a hint to switch to "Todos". Both screens follow the same pattern (mirrored from the sibling project **CofreNuvem**, `lib/screens/manage_categories_screen.dart`): reordering only touches local widget state (`ReorderableListView.builder` + `ReorderableDelayedDragStartListener`, which lets a short tap still fire `onTap` and a long-press start the drag — no separate drag-handle icon needed on the componente cards), an unsaved-changes flag shows a "Salvar" button in the AppBar, and only that Salvar batch-writes `ordem` to Supabase via `updateOrdensTipos`/`updateOrdensComponentes` (N individual `.update()` calls via `Future.wait`, not a single `.upsert()` — upsert would need every not-null column in the payload or risk clobbering `nome`/`user_id`). Use `onReorderItem` (not the deprecated `onReorder`) on this Flutter SDK — it already adjusts `newIndex` internally, don't re-subtract 1 manually.
- **Suppliers are optional** (not yet implemented): a finalized shopping list may record a fornecedor (never mandatory) — enables per-insumo price comparison across suppliers.

Pricing:
- **Suggested sale price** = custo ÷ (1 − margem%) — target-margin model, not markup.
- **Sales channels** (not yet implemented): the user registers a fee % per channel (salão 0%, iFood ~27%...) and the app suggests a different price per channel to preserve the same target margin.
- **Extra costs are ALL optional** (not yet implemented): platform fees (per channel, above), mão de obra, custos fixos rateados. Default view is insumos-only cost; the user may register store operational expenses (despesas da loja) in the app to enrich the cost basis — implies a future expense entity.
- **Price-fluctuation impact**: when an insumo price changes, product costs recalculate automatically and the app highlights products whose margin fell below target.

Dashboard & sales:
- **Home dashboard widgets**: gross vs net revenue over time; margin-drop alerts (implemented); top products by profit. Until OpenDelivery exists it shows app data only (purchase spending, margin alerts) — no manual sales entry.
- **Net profit** = gross sales − platform fees − CMV (ficha-técnica cost of sold items) − allocation of the period's registered expenses.
- **Sale→product mapping**: each sold item is linked to an app product once (manual, with automatic name-based suggestion) and the link is remembered — required to compute CMV per sale.
- **Inventory/stock control**: out of scope — OpenDelivery sales data feeds only the profit graphs.

## Commands (Windows PowerShell, from repo root)

- Verify changes: `flutter analyze` — the **only** automated gate; must stay clean (a handful of `unnecessary_underscores` / `deprecated_member_use` infos are known and cosmetic).
- Run on device/emulator: `flutter run -d <device>` (`flutter devices` to list)
- Android APK: `flutter build apk --debug`
- Windows desktop: `flutter build windows` → `build\windows\x64\runner\Release\lojista.exe`
- Quick UI check in a browser: `flutter run -d web-server --web-port=8765`
- Web build as CI does it: `flutter build web --release --base-href /menuvem-lojista/`

## Deploy web (GitHub Pages)

`.github/workflows/deploy-web.yml` publishes the web build to GitHub Pages on every push to `main` or `flutter-rewrite` (the second only until the rewrite is merged), and via manual `workflow_dispatch`. Pages is configured with "GitHub Actions" as the source. Live at `https://kurobisu.github.io/menuvem-lojista/`.

- **`lib/config/env.dart` is generated in CI** from the repository secrets `SUPABASE_URL` and `SUPABASE_ANON_KEY` (Settings → Secrets and variables → Actions). The workflow fails with an explicit message if either is missing, instead of shipping a broken site. The file stays gitignored — it is never committed, in CI or locally.
- **The anon key is visible in the published JS bundle**, and that is expected: Supabase anon keys are client-side by design and RLS is what actually protects the data. Using secrets keeps the key out of git, not out of the browser. Never put the `sb_secret_...` key anywhere near this.
- **`--base-href /menuvem-lojista/` is required** — Pages serves the site from a repo subpath, not the domain root. Change it if the repository is ever renamed.
- Routing works on Pages without any 404/rewrite trick because the app uses Flutter's default **hash** URL strategy (`#/home`). If anyone ever calls `usePathUrlStrategy()`, deep links will start 404-ing there and a `404.html` copy of `index.html` becomes necessary.
- The repo is **public**. `senha123` for the `lojista@teste.com` test account is in git history (commit `2c5d0c1` onward) and is therefore public — rotate that password in the Supabase dashboard.
- **No meaningful tests exist.** `test/widget_test.dart` is a placeholder — real screen tests need a fake Supabase client that doesn't exist yet.

## Architecture

Entry: `lib/main.dart` — initializes pt-BR date formatting, then Supabase, then runs `ProviderScope` + `MaterialApp.router`. Layers under `lib/`:

- `config/` — `env.dart` (gitignored secrets) + `env.example.dart` template
- `domain/model/` — 16 immutable model classes with `copyWith`; `domain/usecase/` — business logic as **top-level functions**, not classes
- `data/` — one repository class per aggregate, talking directly to Supabase PostgREST
- `presentation/<feature>/` — `*_screen.dart` + (where there's local UI state) `*_controller.dart` with a Riverpod `Notifier` + immutable UiState. Features: `auth`, `home`, `shopping`, `history`, `products`, `insumos`, `componentes`; shared widgets in `presentation/components/`
- `providers/` — `repository_providers.dart`, `auth_providers.dart`
- `router/app_router.dart` — go_router, auth-gated via `redirect`
- `theme/app_theme.dart` — Material 3 + Menuvem brand colors
- `supabase/schema.sql` — DDL to run once in the Supabase SQL editor (tables + RLS + Realtime publication). Unchanged by the rewrite; the Flutter app talks to the same schema the Kotlin app did.

Supabase conventions (follow these when adding tables/queries):

- **Reactive reads** use `client.from(table).stream(primaryKey: ['id'])` — Realtime-backed, emits an initial snapshot and re-emits on changes including from other devices. This replaces the Kotlin app's hand-rolled `tableListFlow`; no manual refresh trigger is needed.
- **Insert payloads never contain `id`/`user_id`**; `user_id` is filled by the DB default `auth.uid()`.
- **RLS is the only access control** — every table has `for all using (auth.uid() = user_id)`; the client never filters by user.
- New table = also add it to the `supabase_realtime` publication in `schema.sql`, or cross-device sync won't cover it.

Other conventions:

- New screen = add a `GoRoute` in `lib/router/app_router.dart`. Use `context.push()` for drill-down navigation (gives the automatic AppBar back button); `context.go()` replaces the route and should only be used for top-level switches.
- Reactive derived data (anything combining several tables, e.g. cost/margin) belongs in `domain/usecase/` as a function returning a `Stream`, composed with `rxdart`'s `Rx.combineLatestN` — see `cost_engine.dart`.
- Numeric inputs parse the pt-BR decimal comma via `parseDecimalPtBr`; money display goes through `formatarMoeda` (both in `lib/presentation/components/formatters.dart`).
- Prefer `.nonNulls` over the deprecated `whereNotNull()`.

## Gotchas already hit and fixed — don't reintroduce

1. **Auth in go_router's `redirect` — read the session live, never through a Riverpod provider.** This bug was introduced, "fixed" wrong, and only then fixed properly; both wrong versions produce the *same* symptom: the Entrar button animates, no error appears, and the user stays on the login screen even though Supabase authenticated fine.
   - First wrong version: a `StreamProvider` over `onAuthStateChange`. go_router's `refreshListenable` and the StreamProvider both subscribe to that same stream, and the redirect could run before Riverpod's cached value updated.
   - Second wrong version: a plain `Provider<bool>` reading `currentSession`. Worse — its only dependency (`authRepositoryProvider`) is never invalidated, so Riverpod caches the very first result (`false`, at startup) **forever** and the redirect never sees any later login.
   - Correct version (current): `redirect` calls `ref.read(authRepositoryProvider).currentSession != null` directly. `currentSession` is a live getter on the Supabase client, so there is nothing to go stale.
   - **Verification lesson:** reloading the page with a session already in `localStorage` does *not* exercise this path — it passes with the bug present. Always clear storage and perform an actual login.
2. **Locale.** `main()` must `await initializeDateFormatting('pt_BR')` before `runApp`, or any locale-aware `DateFormat` throws `LocaleDataException` at runtime.
3. **Back navigation.** `context.go()` everywhere meant no screen had a back button — see the navigation convention above.
4. **Multi-field forms on mobile must be a bottom sheet, not `AlertDialog`.** Found 2026-08-18 by the owner testing on his phone: `showDialog`/`AlertDialog` for a form with several fields (insumo form, add-insumo-to-componente form) let the on-screen keyboard cover the fields being filled and push the action button out of reach — it *looked* like the Salvar/Adicionar button "didn't work", but it was just unreachable. Fix used everywhere now: `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, ...)`, content built as `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: SingleChildScrollView(...))`, and — this is the part that actually fixes the unreachable-button symptom — the primary action button lives in a fixed header `Row` (Cancelar / title / Salvar) *outside* the scrolling content, so it's never the thing that gets pushed off-screen. Pattern lifted from the sibling project **CofreNuvem**'s `lib/widgets/produto_item_sheet.dart`. Applies to `insumo_form_dialog.dart` and the add-insumo sheet in `componente_detail_screen.dart`; reuse this shape for any new multi-field form instead of reaching for `AlertDialog`.
5. **Unit-of-measure fields are a closed dropdown, not free text** (changed 2026-08-18, same feedback round as #4): `Insumo.unidadeCompra`/`unidadeUso` used to be free `TextField`s. Now `DropdownButtonFormField<String>` populated from the fixed preset list in `lib/presentation/components/unidades_medida.dart` (kg/g → scale icon, L/ml → bottle icon, un/cx/pct/dz/fardo → box icon) — deliberately **not** an open enum with a "custom" escape hatch (owner's call, unlike the componente-tipo autocomplete above). Legacy insumos whose stored unit string doesn't case-insensitively match a preset get that raw string injected as an extra dropdown item just for that edit (`_itensUnidade` in `insumo_form_dialog.dart`) so old data doesn't crash the screen — don't remove that fallback without a data migration first.
6. **Switching accounts leaves the previous user's data on screen.** Riverpod keeps a `StreamProvider`'s last value cached for as long as something watches it, and the underlying Supabase `.stream()` subscription was opened under the old session — so after logout + login as another user, the old account's lists/insumos/produtos stay visible. `sessionResetProvider` (in `lib/providers/session_providers.dart`, kept alive by a `ref.watch` in `main.dart`) listens for a change of `session.user.id` and invalidates the five data repository providers; because every data provider watches one of those, the whole derived cache is dropped and the streams are rebuilt for the new user. It deliberately does **not** invalidate `authRepositoryProvider` or `supabaseClientProvider` — the router watches the auth one, and invalidating it would rebuild the whole `GoRouter` mid-transition. Any new data repository must be added to that invalidation list.

## Login rápido (contas salvas)

Marcar "Salvar dados de login" grava a conta em `SharedPreferences` (`ContasSalvasRepository`) e ela vira um avatar na tela de login; um toque entra direto. Pontos que não são óbvios:

- **Grava o refresh token, nunca a senha.** Decisão consciente do dono: o token dá o mesmo login de um toque, pode ser revogado pelo painel do Supabase e, se o arquivo vazar, não expõe uma senha provavelmente reusada em outros serviços. (O projeto CofreNuvem guarda a senha em base64, que é reversível — não replicar isso aqui.)
- **`signOut()` usa `SignOutScope.local`, e isso é obrigatório.** O padrão do Supabase é `global`, que revoga os refresh tokens no servidor — e aí o token recém-salvo morre exatamente no fluxo em que o recurso é usado (sair e entrar em outra conta). Voltar para o escopo padrão quebra o login rápido de forma silenciosa: o avatar aparece, mas sempre cai no "sessão expirada".
- **O token é rotacionado a cada renovação de sessão**, então `tokenSyncProvider` escuta `tokenRefreshed`/`signedIn` e regrava o token da conta salva. Sem isso o token guardado envelhece sozinho depois de algumas horas.
- Validade do refresh token é ajuste de **servidor** (painel do Supabase → Authentication → Sessions), não de código. Por padrão não expira por tempo.
- Quando `setSession` falha (token revogado/expirado), a tela preenche o e-mail e pede a senha; a conta continua salva e o próximo login normal renova o token.

## Toolchain notes

- **The Windows username on this machine is `Usuário` — with an accent — and that breaks Gradle.** Two mitigations are in place and must not be removed:
  - `android/gradle.properties` sets `-Dfile.encoding=UTF-8` in `org.gradle.jvmargs`. Without it the JVM mangles the path (`Usu?rio`).
  - `android/settings.gradle.kts` detects an accented `flutter.sdk` / `sdk.dir` in `local.properties` and rewrites them to the 8.3 short form (`C:\Users\USURIO~2\...`). This has to run at build time because Flutter regenerates `local.properties` on every build — Android Studio launches with the SDK at `C:\Users\Usuário\flutter`, so the accented path comes back each time. The sibling project `CofreNuvem` (same machine, same Flutter version) uses the same trick; it was the reference for this fix.
  - Do **not** add `systemProp.gradle.user.home` / `systemProp.android.user.home` redirects to `gradle.properties`. They were tried, pointed at a directory that didn't exist, and coincided with the build being broken.
- There are **two Flutter SDKs installed**: `D:\flutter` and `C:\Users\Usuário\flutter`, both 3.44.9. Android Studio uses the `C:` one; the `D:` one has no accent in its path and is what the agent should call. Neither is on PATH — call `D:\flutter\bin\flutter.bat` explicitly.
- `android/local.properties` (machine-specific `sdk.dir` + `flutter.sdk`) is generated by Flutter and gitignored.
- **The Android build cannot be verified by an AI agent here.** Gradle fails with `java.io.IOException: Unable to establish loopback connection` in the sandboxed environment. This was proven to be an environment limitation rather than a project problem: `CofreNuvem`, which builds fine for the owner, fails with the *same* error when an agent runs it. Changes touching the Android build must be tested by the owner; `flutter analyze` and `flutter build windows` do work for the agent.
