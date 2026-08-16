# CONTINUACAO.md — Handoff Menuvem Lojista

Documento de continuidade: permite que outro modelo de IA (ou outra sessão) retome o trabalho exatamente de onde parou. **Ler junto com `AGENTS.md`** (contexto durável do projeto: arquitetura, convenções, decisões de domínio, gotchas). Última atualização: 16/08/2026.

Para retomar, basta dizer ao novo modelo: *"Leia AGENTS.md e CONTINUACAO.md na raiz do projeto e continue de onde parou."*

---

## 1. Estado atual — onde paramos (agora mesmo)

**Teste E2E no device CONCLUÍDO e validado de ponta a ponta (16/08/2026).** Durante o teste foram encontrados e corrigidos **4 bugs** (3 de preço + 1 crash Realtime) e, na feature de Componentes, **2 bugs** (chip "Outro" cortado no dialog + crash `Key "2" was already used` no LazyColumn). Todos corrigidos e revalidados no device com rebuild + reinstall.

**Próxima ação imediata**: revisar e commitar/pushear as alterações (feature Componentes + 6 fixes) — fluxo de commit autorizado na seção 7. Depois, seguir a fila de features (seção 3).

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
| **Componentes (blocos reutilizáveis)** | **Implementado e E2E validado no device** (16/08/2026): `Componente` (tipo MASSA/SABOR/EMBALAGEM/OUTRO) + `itens_componente` + `produto_componentes` (com `multiplicador`). Cost engine soma insumos avulsos + (itens do componente × multiplicador). Telas: biblioteca (`presentation/componentes`), editor de componente, botão "Componente" no produto (com seletor de divisão inteiro/1/2/1/3/1/4), "Copiar ficha" agora copia componentes. Schema aplicado (HTTP 200 nas 3 tabelas). Resultado: pizza 35cm refeita com Massa (R$ 1,95) + Sabor (R$ 22,74) + 3 embalagens avulsas = **custo R$ 28,14**; fração 1/2 no sabor = R$ 11,37; cópia de produto com ficha completa |

**Pendências**: feature **Componentes** (toda a implementação) + 6 fixes (3 preço + crash Realtime + 2 bugs da feature) estão **não commitados** — commit + push em aberto (seção 7 autoriza o fluxo).

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
- Push/commit só quando o dono pedir (ele já autorizou o fluxo: commit → push → tag por versão). **Correções já commitadas e pusheadas** no commit `97b3f47` (main) em 16/08/2026.

## 8. Cadastro de produto completo — CONCLUÍDO (ficha técnica da pizza)

O dono pediu para cadastrar a ficha técnica completa de **"Pizza de Calabresa com Muçarela (Tamanho Grande 35cm / 8 fatias)"** via UI no device, para ver o fluxo. Dados fornecidos pelo dono (quantidades por pizza):

- **Massa (por disco 350g)**: Farinha 200g · Água 115ml · Azeite 15ml · Açúcar 6g · Sal 4g · Fermento 2g
- **Molho/cobertura (pizza inteira)**: Molho de tomate 70g · Muçarela 250g · Calabresa 180g · Cebola 60g · Azeitonas 40g · Orégano 2g
- **Embalagem (opcional, incluir)**: Caixa oitavada 35cm 1un · Disco papelão 1un · Lacre 1un
- Validação de pesos: Massa 342g + Molho/recheio 602g ≈ **944g bruto**

Decisões do dono (confirmadas): custos = **valores realistas de exemplo**; embalagens = **incluir**; massa = **por pizza inteira**.

### Dados de cadastro (tabela de referência)

| # | Nome | Categoria | Un.compra | Un.uso | Fator | Custo | Qtd ficha |
|---|---|---|---|---|---|---|---|
| 1 | Farinha de trigo especial | Insumo | kg | g | 1000 | 6,00 | 200 |
| 2 | Água | Insumo | L | ml | 1000 | 1,00 | 115 |
| 3 | Azeite de oliva | Insumo | L | ml | 1000 | 28,00 | 15 |
| 4 | Açúcar cristal | Insumo | kg | g | 1000 | 5,00 | 6 |
| 5 | Sal refinado | Insumo | kg | g | 1000 | 2,00 | 4 |
| 6 | Fermento biológico seco | Insumo | kg | g | 1000 | 90,00 | 2 |
| 7 | Molho de tomate temperado | Insumo | kg | g | 1000 | 9,00 | 70 |
| 8 | Queijo muçarela | Insumo | kg | g | 1000 | 45,00 | 250 |
| 9 | Calabresa (**já existe**, custo 50,00) | Insumo | kg | g | 1000 | 50,00 | 180 |
| 10 | Cebola roxa | Insumo | kg | g | 1000 | 8,00 | 60 |
| 11 | Azeitonas pretas | Insumo | kg | g | 1000 | 30,00 | 40 |
| 12 | Orégano desidratado | Insumo | kg | g | 1000 | 90,00 | 2 |
| 13 | Caixa de pizza oitavada 35cm | **Embalagem** | un | un | 1 | 2,50 | 1 |
| 14 | Disco de papelão / protetor térmico | **Embalagem** | un | un | 1 | 0,80 | 1 |
| 15 | Lacre de segurança adesivo | **Embalagem** | un | un | 1 | 0,15 | 1 |

Produto: **Pizza de Calabresa com Muçarela (Grande 35cm)** · margem 30% · preço venda R$ 45,00 (deixar em branco se preferir; sem preço venda não há margem "atual").

### Estado do cadastro (ponto exato de parada)

**CADASTRO COMPLETO — tudo feito e validado no device (16/08/2026):**
- **15 insumos cadastrados** via UI (14 novos + Calabresa reutilizada). Obs.: o Gboard autocorrigiu alguns nomes para formas acentuadas ("Acucar" → **Açúcar cristal**, "Oregano" → **Orégano desidratado**) — por isso buscar na ficha por "cristal"/"oregano" e não pelos termos acentuados. Nomes dos itens 13–15 ficaram: "Caixa de pizza oitavada 35cm", "Disco de papelao", "Lacre de seguranca" (sem acento — correto no DB).
- **Produto criado**: "Pizza de calabresa com muçarela 35cm" · margem 30% · preço venda **R$ 45,00**.
- **Ficha técnica 15/15 itens adicionados** (na ordem real de inserção): Farinha 200g 1,20 · Agua 115ml 0,12 · Azeite 15ml 0,42 · Açúcar 6g 0,03 · Sal 4g 0,01 · Fermento 2g 0,18 · Molho 70g 0,63 · Queijo 250g 11,25 · Calabresa 180g 9,00 · Cebola 60g 0,48 · Azeitona 40g 1,20 · Orégano 2g 0,18 · Caixa 1un 2,50 · Disco 1un 0,80 · Lacre 1un 0,15.

**Resultado final validado (dump u51)**: **Custo por porção R$ 28,14** · Preço sugerido (margem 30%) **R$ 40,20** · Preço praticado R$ 45,00 · **Margem atual 37,5%**. Logcat limpo (sem AndroidRuntime:E).

**Próxima ação sugerida**: alerta na Home — produto acima da meta de margem (37,5% > 30%) → não deve aparecer em alerta de margem; conferir se a Home lista o produto com custo R$ 28,14 na biblioteca de produtos. Se o dono quiser testar a **duplicação de ficha** (atalho "Copiar ficha"), criar uma variação M/P copiando esta ficha. Commit/push NÃO necessário (só dados, sem código).

### Fluxo de ficha técnica (testado — item a item, SEMPRE com dump de verificação)

1. Botão **"Insumo"** no detalhe do produto: **(931, 856)**.
2. Sheet abre (teclado fechado): campo busca em **(540, 1872)** → tocar e digitar nome (espaço = `%s`).
3. **Aguardar ~2s** (busca é debounce) e DUMPAR antes de tocar o resultado — se não aparecer resultado (nome acentuado), buscar por substring sem acento.
4. Com teclado aberto: resultado em **(508, 1054)** · campo quantidade **(291, 1099)** · botão **"Adicionar à ficha técnica" (540, 1315)** (fica acima do teclado, pode tocar com teclado aberto).
5. Após adicionar, o card "Custo por porção" recalcula na hora (validar o incremento esperado). Lista da ficha rola; itens novos entram abaixo dos visíveis.

### Técnica de UI (testada e confiável — usar SEMPRE)

- **Não usar screenshots** (este modelo não lê imagens). Usar `adb shell uiautomator dump /sdcard/ui.xml` + `adb pull` + parsing PowerShell `[xml]`, listando nós com `text != ""` → mostrar `bounds | text`. Os **bounds já são pixels de device** (tela 1080×2172), tocar direto no centro.
- **Teclado desloca o diálogo** (AlertDialog): posições mudam quando o teclado abre. Campos do "Novo Insumo" **sem teclado**: Nome (540,582) · Insumo chip (252,786) · Embalagem chip (559,786) · Un.compra (327,990) · Un.uso (753,990) · Fator (540,1272) · Custo (540,1644) · Cancelar (609,1974) · **Salvar (851,1938)**. **Com teclado**: Nome (540,420) · Salvar (851,1740).
- **Espaço no `adb shell input text` = `%s`** (ex.: `Farinha%sde%strigo%sespecial`). NÃO usar `%20` (é digitado literalmente!).
- **IMPORTANTE: SEMPRE fechar o teclado (`keyevent 4`) ANTES de tocar Salvar.** Com o teclado aberto, o toque na linha do botão (ex.: y=1740) cai **na tecla do teclado** e digita caracteres no campo (apareceu "i" extra no nome) em vez de salvar. Salvar **sem teclado** = (851, 1938).
- Para apagar: tocar no fim do campo, depois vários `keyevent 67` (DEL). Vírgula decimal é aceita direto no `input text` (`6,00`).
- Acentos aparecem "quebrados" no dump (`biolA3gico` = "biológico", `AA�car` = "Açúcar") — é só encoding do uiautomator, o texto real está correto. Não "corrigir" nomes acentuados já salvos com base no dump.
- Fluxo por insumo: tocar campo → digitar → `keyevent 4` (fecha teclado, restaura posições sem teclado) → próximo campo. Ao final, dump → tocar Salvar.
- FAB "+" da Biblioteca: (797, 2118). Filtros Todos/Insumos/Embalagens: (156,384)/(420,384)/(742,384).
- Comando de checagem de crash: `adb logcat -d -s AndroidRuntime:E` (limpo até agora).

## 9. Feature: Componentes (blocos reutilizáveis) — CONCLUÍDO (schema + código + E2E)

**Problema que resolve**: ficha técnica "amontoada" de insumos — agora o produto é montado com **componentes reutilizáveis** + **insumos avulsos**. Ex.: "Pizza - Massa Grande 35cm" (MASSA) e "Pizza Sabor - Calabresa" (SABOR) são cadastrados uma vez e aplicados a várias pizzas; o sabor aceita **divisão** (sabor único = inteiro; 2 sabores = 1/2; 3 = 1/3). Embalagem continua como insumo avulso (1 caixa = 1 pizza). Insumo avulso continua disponível no produto (ex.: Hambúrguer de Calabresa usa os mesmos insumos em proporções diferentes).

**SQL pendente no Supabase (SQL Editor)** — ~~criar/rodar (idempotente; pode rodar o `schema.sql` inteiro): tabelas `componentes`, `itens_componente`, `produto_componentes` (com indexes, RLS `auth.uid() = user_id` e publicação `supabase_realtime`). Sem isso o app mostra erro nas telas de produtos/componentes~~. **Aplicado pelo dono — validado HTTP 200 nas 3 tabelas.**

**O que foi feito no código** (compilado + APK instalado no device):
- Domain: `TipoComponente` (MASSA/SABOR/EMBALAGEM/OUTRO), `Componente`, `ItemComponente`, `ItemComponenteComInsumo`, `ProdutoComponente` (multiplicador), `ProdutoComponenteCompleto`, `ComponenteComCusto`.
- Data: `ComponenteRepository(+Impl)`, `ProdutoRepository`/Impl ganharam `produto_componentes`; DTOs `ComponenteDto`/`ItemComponenteDto`/`ProdutoComponenteDto` (+Insert). DI bind em `RepositoryModule`.
- Use cases: `GetComponentesUseCase`, `SaveComponenteUseCase`, `DeleteComponenteUseCase`, `SaveItemComponenteUseCase`, `DeleteItemComponenteUseCase`, `AddComponenteToProdutoUseCase`, `UpdateProdutoComponenteUseCase`, `DeleteProdutoComponenteUseCase`, `GetProdutoComponentesUseCase`; `GetProdutosComCustoUseCase` agora soma componentes × multiplicador; `DuplicateFichaTecnicaUseCase` copia `produto_componentes`; `DeleteInsumoUseCase` valida uso em componentes.
- UI: `presentation/componentes` (biblioteca com filtro por tipo + editor com busca de insumo), `AddComponenteSheet` (busca + divisor inteiro/1/2/1/3/1/4/custom) no produto, card de componente no detalhe do produto (com multiplicador e custo no produto), `SeletorDivisaoDialog` p/ editar fração. Shared: `InsumoQuantidadeRow`, `EditarQuantidadeDialog`, `DivisorPizzaSelector` (+ `multiplicadorDeDivisor`/`divisorDeMultiplicador`/`descreverMultiplicador`), `formatarTipo`. Home ganhou card "Componentes". Rotas: `componentes`, `componente/{componenteId}`.

**E2E CONCLUÍDO e validado no device (16/08/2026)**:
1. ✅ Criado componente **"Pizza - Massa Grande 35cm"** (MASSA) com 6 insumos → **custo R$ 1,95** (Farinha 1,20 · Agua 0,12 · Azeite 0,42 · Açúcar 0,03 · Sal 0,01 · Fermento 0,18).
2. ✅ Criado componente **"Pizza Sabor - Calabresa"** (SABOR) com 6 insumos → **custo R$ 22,74** (Molho 0,63 · Queijo 11,25 · Calabresa 9,00 · Cebola 0,48 · Azeitona 1,20 · Orégano 0,18).
3. ✅ Aplicados ao produto via **"Componente"** (AddComponenteSheet) com divisor **inteiro** (× 1) → custo 52,84 (28,14 avulsos + 1,95 + 22,74).
4. ✅ **Fração**: editar o Sabor → divisor **1/2** → card do componente mostra "× 1/2 · 2 partes", custo no produto **R$ 11,37** (exata metade), custo total 52,84 → 41,47. Voltou a inteiro (52,84).
5. ✅ Removidos os 12 insumos avulsos de massa/recheio (mantidas as 3 embalagens) via ícone de exclusão (x=912) → **custo por porção R$ 28,14** (3,45 + 1,95 + 22,74) — ficha agora é component-based. **Bug corrigido**: `Key "2" was already used` (crash ao aplicar o 2º componente) — chaves do `LazyColumn` em `ProdutoDetailScreen.kt` colidiam entre `produto_componentes` e `itens_ficha_tecnica` (ids de tabelas diferentes); prefixadas com `comp_`/`item_`.
6. ✅ **"Copiar ficha"** no produto novo "Pizza de Calabresa 35cm copia" → copiou os 2 componentes (× 1 inteiro) + 3 embalagens → **custo R$ 28,14 / sugerido R$ 40,20**. Cópia validada.
7. ✅ Biblioteca com **filtros por tipo** (Todos/Massa/Sabor/Embalagem) funcionando; logcat limpo (0 erros após limpar).

**Bug corrigido no dialog**: chip **"Outro"** ficava cortado fora do AlertDialog (não cabia na `Row` de chips) em `ComponenteFormDialog.kt` — trocado por `FlowRow` (chips quebram linha; "Outro" agora visível e selecionável).

**Gotcha de UI descoberto no E2E**: no `AddFichaItemBottomSheet`, o campo **Quantidade é o ESQUERDO** (291,1099) e **Perda (%) é o DIREITO** (789,1099). Digitar no direito põe a perda como "200" (inválido, máx 99,9) e desabilita o botão "Adicionar" (enabled=false). Sempre preencher o campo esquerdo (apagar o "0" com keyevent 67 antes).

**Coordensadas conhecidas (device 1080×2172)**: detalhe do produto — "Componente" (876,856) · "Copiar ficha" (554,856) · "Insumo" (931,723/651 conforme scroll). Biblioteca de Componentes — FAB + (797,2118), filtros Todos/Massa/Sabor/Embalagem (156,384)/(401,384)/(643,384)/(890,384). Dialog Novo/Editar Componente — Nome (540,945), chips Massa/Sabor/Embalagem (245,1227)/(487,1227)/(779,1227), Outro (233,1395), Salvar (851,1611). Editor de componente — botão "Insumo" (931,651). Seletor de divisão — chips Inteiro/1/2/1/3/1/4 (242,1185)/(458,1185)/(644,1185)/(830,1185), Salvar (851,1617). Sheet componente — "Adicionar componente" (540,1968). Exclusão de item avulso — ícone lixeira x=912 (y = centro da linha, listar de cima para baixo).
