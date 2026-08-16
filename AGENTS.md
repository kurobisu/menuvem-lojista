# AGENTS.md — Menuvem Lojista

Pricing tool for small merchants: shopping lists with price/weight per item, price-fluctuation history per insumo, and cost/profit margin impact on the store's products. Today this repo contains only the **Android app** — single module `:app`, package `br.com.menuvem.lojista`, **100% online on Supabase** (email/password auth, RLS per user, Realtime sync). Class names, comments, and UI strings are in pt-BR (ListaCompras, Insumo, HistoricoPreco) — match that naming in new code.

## Secrets — read before touching git

- `local.properties` holds `supabase.url` + `supabase.anonKey` (injected via `buildConfigField`) and is **gitignored — never commit it**. The GitHub repo may be public.
- The Supabase **secret key (`sb_secret_...`) must never appear in this repo or in the app** — it bypasses RLS. Only the anon key belongs client-side.

## Roadmap

- **Supabase backend** — **done (Aug 2026)**: the app is 100% online, Supabase-only; the local Room database was *removed* (not kept as cache). Repository impls talk to the Supabase API and are bound in `di/RepositoryModule.kt` (the swap happened exactly there); the domain layer carried over unchanged. Motivation: unblock Windows desktop + Android sharing the same backend. The features queue (despesas, canais, fornecedor) will be built directly on Supabase.
- **Windows desktop** — next major step, unblocked: same repo, via Kotlin Multiplatform / Compose for Desktop sharing `domain`/`data` with Android. supabase-kt is KMP, so the client code ports directly. Expect the single `:app` module to be restructured into multi-module when this starts.
- **OpenDelivery integration** — sales data ingested via API, feeding net-profit (lucro líquido) graphs and other metrics (net-profit formula and sale→product mapping are decided below).

## Domain decisions (aligned with the owner)

Products & ficha técnica — **implemented** (domain + repositories + screens):
- **New concepts**: `Produto` (item the store sells, e.g. Pizza Grande de Calabresa) and its **ficha técnica** (composition: which insumos + how much of each per portion). Implemented: domain models, `ProdutoRepository`, the cost engine (`GetProdutosComCustoUseCase` recomputes all product costs reactively when any insumo price changes), screens in `presentation/products` (list + ficha técnica editor with duplicate-ficha shortcut) and `presentation/insumos` (library with category filter), plus margin-drop alerts on Home. `Insumo` has a `categoria` field (INSUMO/EMBALAGEM).
- **Variations & combos**: Pizza P/M/G or a "pizza + drink" combo = separate products, each with its own ficha técnica; duplicate-ficha shortcut exists for fast entry.
- **Units**: insumo has a purchase unit + conversion factor to a base usage unit (kg→g, L→ml, box→unit). Ficha técnica quantities are expressed in the base unit; cost is prorated automatically (e.g. calabresa at R$ 46,18/kg → 150 g costs R$ 6,93).
- **Loss/yield**: optional % loss per ficha técnica item (default 0%; e.g. 1 kg of tomato yields 800 g, raising the real portion cost).
- **Insumo cost source**: auto-updated from finalized shopping lists (HistoricoPreco), with manual override in the insumo library ("biblioteca").
- **Packaging = categorized insumo**: caixa/copo/sacola is an insumo of category "embalagem" — reuses shopping lists, price history and unit conversion, and enters the ficha técnica as a normal item.
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

## Toolchain quirks

- Bleeding edge: Gradle 9.7.0 wrapper, AGP 9.3.0, Kotlin 2.3.0, KSP 2.3.10, compileSdk/targetSdk 36, minSdk 26, Compose BOM 2025.06.01, Java 17 target.
- There is intentionally **no `org.jetbrains.kotlin.android` plugin** — AGP 9 has built-in Kotlin support; only `org.jetbrains.kotlin.plugin.compose` + `org.jetbrains.kotlin.plugin.serialization` are applied. Do not add a kotlin-android plugin alias.
- All versions live in `gradle/libs.versions.toml`. supabase-kt **3.1.4** (stable; 3.2.x is beta) with Ktor **3.1.2** OkHttp engine — keep engine version aligned with supabase-kt's Ktor (check its `libs.versions.toml` when bumping).
- `local.properties` contains a machine-specific `sdk.dir` (`C:\Users\Usuário\...`) — fix it when moving machines.
- Dexing (D8) OOMs with the default daemon heap — `gradle.properties` sets `org.gradle.jvmargs=-Xmx4g` (the `java_pid*.hprof` in the root is a leftover from that OOM; safe to delete).
- Launcher icons are adaptive vectors only (`res/mipmap-anydpi-v26` + vector foreground) — sufficient because minSdk is 26; no PNG mipmaps exist.
- In `app/build.gradle.kts`, `java` resolves to an AGP extension, not the JDK package — `import java.util.Properties` at the top (needed for the local.properties reader).

## Commands (Windows PowerShell)

- Verify changes: `.\gradlew.bat :app:compileDebugKotlin` (fastest check; runs KSP + compile)
- Build APK: `.\gradlew.bat :app:assembleDebug` · Install: `.\gradlew.bat :app:installDebug` (verified working on a physical device)
- **No tests exist** — no `src/test`/`src/androidTest`, no test dependencies, no lint/detekt/ktlint. Compilation is the only automated verification.

## Architecture

Entry: `MenuvemApplication` (@HiltAndroidApp) → `MainActivity` (session gate: `SessionStatus.Authenticated` → `MenuvemNavGraph`, `Initializing` → splash, else → `LoginScreen`). Layers under `app/src/main/java/br/com/menuvem/lojista/`:

- `data/remote` — Supabase infra: `dto/` (serializable DTOs), `SupabaseTableFlow.kt` (reactive table flows), `AuthManager.kt`; `data/repository` — repository impls talking PostgREST
- `domain` — `model`, `repository` (interfaces), `usecase` (one class per use case) — untouched by the backend swap
- `presentation/<feature>` — Screen + ViewModel + UiState per feature (`auth`, `home`, `shopping`, `history`, `products`, `insumos`); shared composables in `presentation/components`
- `di` — Hilt modules (`SupabaseModule` provides the client; `RepositoryModule` binds impls)
- `supabase/schema.sql` — DDL to run once in the Supabase SQL editor (tables + RLS + Realtime publication)

Supabase conventions (follow these when adding tables/queries):

- **Reactive flows**: repository list/get flows use `client.tableListFlow(table, refreshSharedFlow) { fetch }` — emits initial snapshot, re-fetches on local mutations (each mutation does `refresh.tryEmit(Unit)`) and on Realtime postgres changes from other devices.
- **Insert DTOs never contain `id`/`user_id`** (the client serializer sends explicit nulls, which breaks identity columns); `user_id` is filled by the DB default `auth.uid()`. Read DTOs omit `user_id` too (serializer ignores unknown keys).
- **RLS is the only access control** — every table has `for all using (auth.uid() = user_id)`; the client never filters by user.
- Nullable columns updated to null need `JsonNull` explicitly (see `preco_venda_atual` in `ProdutoRepositoryImpl`); plain Kotlin null in the typed `set()` builder doesn't serialize.
- New table = also add it to `supabase_realtime` publication in schema.sql, or cross-device sync won't cover it.

Other conventions:

- New screen = add route to `presentation/navigation/Screen.kt` + a `composable()` in `MenuvemNavGraph.kt`. Routes are strings; args via `navArgument`, read in the ViewModel from `SavedStateHandle`.
- ViewModels are `@HiltViewModel` and expose an immutable `StateFlow<FeatureUiState>` mutated only via `_uiState.update { it.copy(...) }`.
- Numeric inputs parse the pt-BR decimal comma (`value.replace(",", ".").toDoubleOrNull()`); money display goes through `presentation/components/formatarMoeda`.
