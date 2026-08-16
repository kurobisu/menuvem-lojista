# CONTINUACAO.md — Handoff Menuvem Lojista

Documento de continuidade: permite que outro modelo de IA (ou outra sessão) retome o trabalho exatamente de onde parou. **Ler junto com `AGENTS.md`** (contexto durável do projeto: arquitetura, convenções, decisões de domínio, gotchas). Última atualização: 16/08/2026.

Para retomar, basta dizer ao novo modelo: *"Leia AGENTS.md e CONTINUACAO.md na raiz do projeto e continue de onde parou."*

---

## 1. Estado atual — onde paramos (agora mesmo)

**Teste E2E no device CONCLUÍDO e validado de ponta a ponta (16/08/2026).** Durante o teste foram encontrados e corrigidos **4 bugs** (3 de preço + 1 crash Realtime). Todos corrigidos e revalidados no device com rebuild + reinstall.

**Próxima ação imediata**: revisar e commitar/pushear as correções (seção 2 → "Pendências"), e seguir a fila de features (seção 3).

## 2. O que já foi concluído

| Marco | Detalhe |
|---|---|
| App base | Listas de compras, histórico de preços, tendências (Android/Compose/Hilt) |
| Produto + Ficha Técnica | Modelos, custo engine (margem-alvo, perda %, conversão de unidades), telas `products` e `insumos`, alertas de margem na Home |
| **Backend Supabase** | App **100% online**: Room removido; 4 repositories reescritos em PostgREST + Realtime; auth e-mail/senha com gate no MainActivity; sessão persistente |
| Schema no Supabase | 6 tabelas + RLS por usuário + publicação Realtime — **já aplicado pelo usuário** |
| GitHub | Repo conectado: `https://github.com/kurobisu/menuvem-lojista.git`, branch `main`, commit `d6fa4d2`, **tag `menuve-lojista_v0.0.01`** (escrita assim mesmo, com "menuve") |
| Credenciais | Em `local.properties` (**gitignored, verificado fora do commit**): `supabase.url` + `supabase.anonKey`. Anon key validada (HTTP 200 em `/auth/v1/settings`) |
| **E2E no device** | Roteiro completo validado (login/cadastro, sessão persistente após reinstall, insumo, produto+ficha, lista finalizada → custo atualizado → histórico → produto recalculado). Sem crashes no logcat |

**Pendências**: as correções (4 arquivos de fix, seção 6) estão **não commitadas** — commit + push em aberto (seção 7 autoriza o fluxo).

## 3. Decisões do dono (resumo — detalhes no AGENTS.md)

- **100% online Supabase**, sem banco local (decisão de ago/2026, substituiu o plano offline-first) — motivo: desktop Windows + Android no mesmo backend.
- Preço sugerido = custo ÷ (1 − margem); custo do insumo vem das compras finalizadas (override manual); perda % por item de ficha; embalagem = insumo categorizado; variações/combos = produtos separados (atalho "copiar ficha"); recálculo + alerta de margem automáticos na flutuação de insumos.
- Fila de features (nesta ordem): **despesas operacionais** → **canais de venda** (taxa % → preço por canal) → **fornecedor opcional + comparador** → **desktop KMP** → **OpenDelivery** (vendas por API → gráficos de lucro líquido; mapeamento venda→produto manual com sugestão por nome; estoque fora do escopo).

## 4. Roteiro E2E — CONCLUÍDO (resultados validados)

1. LoginScreen sem sessão ✓
2. Cadastro `lojista@teste.com` / `senha123` → Home ✓
3. Insumo Calabresa (kg→g fator 1000, R$ 46,18) ✓
4. Produto Pizza Grande de Calabresa (margem 30%, preço 49,90) + ficha 150 g Calabresa → **custo R$ 6,93 / preço sugerido R$ 9,90 / margem atual 86,1%** ✓
5. Lista "Compra teste" → Calabresa 1 kg a **R$ 50,00** → finalizada → custo do insumo **46,18 → 50,00**, histórico registra **"R$ 50,00 em 16/08/2026 às 16:01 (Compra teste)"**, produto recalculado para **custo R$ 7,50 / preço sugerido R$ 10,71 / margem 85,0%** ✓
6. Sessão persiste após fechar/reinstalar (entra direto na Home) ✓
7. Logcat limpo (sem FATAL/RLS/PostgrestException) ✓

**Observação E2E**: `uiautomator dump` + parsing do XML (via PowerShell `[xml]`) mostra os textos e **bounds em pixels de device** (1080×2172) — melhor que screenshot (que este modelo não consegue ler).

## 5. Contexto operacional (máquina do usuário)

- **Windows PowerShell**; projeto em `D:\Projetos Antigravity\menuvem_lojista`.
- adb: `C:\Users\Usuário\AppData\Local\Android\Sdk\platform-tools\adb.exe`; device Infinix X670 (Android 13, serial `089092525K001974`) via USB debug.
- Comandos: compilar `.\gradlew.bat :app:compileDebugKotlin`; instalar `.\gradlew.bat :app:installDebug` (demora ~1min20s; dexing precisa do `-Xmx4g` já configurado em `gradle.properties`).
- **Dirigir a UI via adb**: screenshot com `adb shell screencap -p /sdcard/s.png` + `adb pull /sdcard/s.png <temp>` e ler a imagem com a ferramenta Read para decidir coordenadas; tocar com `adb shell input tap X Y` (tela 1080×2400); texto com `adb shell input text "texto"` (espaço = `%s`). Logcat: `adb logcat -d | Select-String "menuvem|AndroidRuntime|FATAL|Supabase|postgrest"`.
- Erro transitório conhecido do shell: `ChildProcess.kill` → **simplesmente repetir o comando**.
- Sem gh CLI; push funciona via credenciais Git já cacheadas no Windows.

## 6. Gotchas técnicos já resolvidos (não repetir investigação)

- `app/build.gradle.kts`: `java` resolve para extensão AGP → usar `import java.util.Properties` no topo (leitor do local.properties).
- supabase-kt **3.1.4**: pacote é `io.github.jan.supabase` (não `jan_tennert`); `SessionStatus.Initializing` (não existe LoadingFromStorage); `removeChannel` é de `client.realtime`; serializer usa `explicitNulls=true` → **insert DTOs nunca têm `id`/`user_id`** e null em update exige `JsonNull` explícito.
- Ktor engine: `ktor-client-okhttp:3.1.2` (alinhado com o Ktor do supabase-kt).
- Ícones adaptive-only (minSdk 26) já criados; OOM do D8 já resolvido com heap 4g.
- Fluxos reativos: `client.tableListFlow(tabela, refresh) { fetch }` em `data/remote/SupabaseTableFlow.kt` — mutações fazem `refresh.tryEmit(Unit)`.
- **Crash Realtime (corrigido)**: `IllegalStateException: You cannot call postgresChangeFlow after joining the channel` — canais Realtime com **id único** (`AtomicLong` em `SupabaseTableFlow.kt`) + `.catch` nos coletores de busca de `ProdutoDetailViewModel` e `ShoppingListViewModel` (removido `.take(1)` da busca em ShoppingList).
- **Bug preço vírgula pt-BR (corrigido)**: `ItemListaCard.kt:85` — `"50,00".toDoubleOrNull()` é `null` (não parseia vírgula) → marcava comprado com preço 0.0. Corrigido com `preco.replace(",", ".").toDoubleOrNull()`.
- **Bug preço ignorado ao vincular insumo (corrigido)**: `ShoppingListScreen.kt` `onAddInsumo` ignorava o campo "R$ Preço" do bottom sheet (usava `insumo.custoAtual`). Corrigido passando o preço digitado (assinatura de `onAddInsumo` agora inclui `preco`).
- **Bug uso de caso sobrescrevia preço (corrigido)**: `AddItemToListaUseCase.kt:28` forçava `precoUnitario = insumo.custoAtual` sempre. Corrigido para respeitar o preço informado, com fallback p/ `custoAtual` apenas quando `<= 0.0`.

## 7. Regras de segurança (inegociáveis)

- `local.properties` **nunca** commitar (já está no `.gitignore`).
- **Secret key (`sb_secret_...`) nunca** no repo nem no app — só anon key no cliente. (Recomendado ao dono: rotacionar a secret e privar o repo no GitHub.)
- Push/commit só quando o dono pedir (ele já autorizou o fluxo: commit → push → tag por versão). **As correções de hoje (crash Realtime + 3 bugs de preço) ainda não foram commitadas/pusheadas.**
