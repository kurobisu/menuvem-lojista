# CONTINUACAO.md — Handoff Menuvem Lojista

Documento de continuidade: permite que outro modelo de IA (ou outra sessão) retome o trabalho exatamente de onde parou. **Ler junto com `AGENTS.md`** (contexto durável do projeto: arquitetura, convenções, decisões de domínio, gotchas). Última atualização: 16/08/2026.

Para retomar, basta dizer ao novo modelo: *"Leia AGENTS.md e CONTINUACAO.md na raiz do projeto e continue de onde parou."*

---

## 1. Estado atual — onde paramos (agora mesmo)

**Estamos no meio do teste ponta a ponta (E2E) no celular.** Situação exata:

- App com integração Supabase **instalado com sucesso** no Infinix X670 (`.\gradlew.bat :app:installDebug` → `BUILD SUCCESSFUL`).
- Usuário já rodou `supabase/schema.sql` no SQL Editor do Supabase **e desligou "Confirm email"** (Authentication → Providers → Email).
- **Próxima ação imediata**: abrir o app no device e executar o roteiro E2E da seção 4, dirigindo a UI via adb (técnica descrita na seção 5).

## 2. O que já foi concluído

| Marco | Detalhe |
|---|---|
| App base | Listas de compras, histórico de preços, tendências (Android/Compose/Hilt) |
| Produto + Ficha Técnica | Modelos, custo engine (margem-alvo, perda %, conversão de unidades), telas `products` e `insumos`, alertas de margem na Home |
| **Backend Supabase** | App **100% online**: Room removido; 4 repositories reescritos em PostgREST + Realtime; auth e-mail/senha com gate no MainActivity; sessão persistente |
| Schema no Supabase | 6 tabelas + RLS por usuário + publicação Realtime — **já aplicado pelo usuário** |
| GitHub | Repo conectado: `https://github.com/kurobisu/menuvem-lojista.git`, branch `main`, commit `d6fa4d2`, **tag `menuve-lojista_v0.0.01`** (escrita assim mesmo, com "menuve") |
| Credenciais | Em `local.properties` (**gitignored, verificado fora do commit**): `supabase.url` + `supabase.anonKey`. Anon key validada (HTTP 200 em `/auth/v1/settings`) |

## 3. Decisões do dono (resumo — detalhes no AGENTS.md)

- **100% online Supabase**, sem banco local (decisão de ago/2026, substituiu o plano offline-first) — motivo: desktop Windows + Android no mesmo backend.
- Preço sugerido = custo ÷ (1 − margem); custo do insumo vem das compras finalizadas (override manual); perda % por item de ficha; embalagem = insumo categorizado; variações/combos = produtos separados (atalho "copiar ficha"); recálculo + alerta de margem automáticos na flutuação de insumos.
- Fila de features (nesta ordem): **despesas operacionais** → **canais de venda** (taxa % → preço por canal) → **fornecedor opcional + comparador** → **desktop KMP** → **OpenDelivery** (vendas por API → gráficos de lucro líquido; mapeamento venda→produto manual com sugestão por nome; estoque fora do escopo).

## 4. Roteiro E2E pendente (executar agora)

1. Abrir app → deve mostrar **LoginScreen** (sem sessão).
2. Cadastrar conta de teste (ex.: `lojista@teste.com` / `senha123`) → deve entrar na **Home**.
3. Home → card **Insumos** → "Novo Insumo": Calabresa, un. compra `kg`, un. uso `g`, fator `1000`, custo `46,18` → aparece na biblioteca.
4. Home → **Produtos** → "Novo Produto": Pizza Grande de Calabresa, margem 30%, preço venda 49,90 → abre detalhe → "Insumo" → Calabresa `150` g, perda 0 → **custo ≈ R$ 6,93** e preço sugerido ≈ R$ 9,90.
5. Lista de compras: criar, adicionar item comprado com preço, finalizar → custo do insumo atualiza + histórico registra.
6. Fechar e reabrir o app → **sessão persiste** (entra direto na Home).
7. Monitorar logcat por erros (RLS, PostgrestException, FATAL) — comando na seção 5.

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

## 7. Regras de segurança (inegociáveis)

- `local.properties` **nunca** commitar (já está no `.gitignore`).
- **Secret key (`sb_secret_...`) nunca** no repo nem no app — só anon key no cliente. (Recomendado ao dono: rotacionar a secret e privar o repo no GitHub.)
- Push/commit só quando o dono pedir (ele já autorizou o fluxo: commit → push → tag por versão).
