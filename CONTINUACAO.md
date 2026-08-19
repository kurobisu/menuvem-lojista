# CONTINUACAO.md — Handoff Menuvem Lojista

Documento vivo de passagem de sessão: **onde paramos, o que já está validado, qual é a próxima ação**. Contexto durável (decisões de domínio, convenções, arquitetura) fica no `AGENTS.md`; este arquivo é só o estado corrente.

Última atualização: **19/08/2026** (sessão longa, fim do dia).

## 0. Feito nesta sessão (19/08, continuação) — ainda **não commitado**

Sessão em cima da anterior (layout responsivo/porções/tutorial, ver histórico git abaixo — essa parte já foi commitada). O dono testou no browser e foi reportando problemas em rodadas sucessivas; todas as rodadas abaixo têm `flutter analyze` limpo e foram **testadas ao vivo no browser contra o Supabase real**, com prova (print ou consulta SQL direta) antes de cada "resolvido".

**Correções de design e UX** (ícones/campos/botões apagados, teclado cobrindo formulário, etc.) — ver diffs em `lib/theme/app_theme.dart`, `lib/presentation/components/form_sheet_header.dart`, `emoji_picker_field.dart`, `unidades_medida.dart` (fator de conversão auto-preenchido para pares óbvios como kg→g).

**A causa raiz por trás de "excluir/salvar não funciona" (achada e corrigida) — a mais importante desta sessão**: métodos `update`/`delete` dos repositórios que faziam `return _client.from(...).delete()...` sem `async`/`await` retornam um `PostgrestBuilder` **preguiçoso** — só dispara a requisição quando algo dá `await` nele. Como os botões chamam esses métodos dentro de `VoidCallback`s, o `Future` nunca era aguardado em nenhum nível da cadeia, e a requisição **nunca era enviada** (confirmado via log de API do Supabase: zero DELETEs chegando ao servidor apesar dos toques repetidos). Afetava quase todo delete/update do app (insumos, componentes, produtos, porções, listas de compras — inclusive marcar item da lista como comprado). Corrigidos ~24 métodos em 4 repositórios (todos viraram `async { await ...; }`). Detalhe técnico completo no `AGENTS.md`, gotcha #7 — **leia antes de escrever um novo método de repositório**.

**Bug secundário relacionado, também corrigido**: mesmo depois do delete funcionar de verdade, a tela não atualizava sozinha até sair/voltar ou recarregar — `REPLICA IDENTITY` das tabelas filtradas por coluna não-PK (`porcao_id`, `componente_id`, `tamanho_componente_id`) estava no padrão do Postgres, que só manda a chave primária no evento de DELETE do Realtime. Setado `REPLICA IDENTITY FULL` em `porcoes`, `itens_ficha_tecnica`, `tipos_componente`, `tamanhos_componente`, `itens_componente`, `itens_lista`, `produto_componentes`. Ver `AGENTS.md`, nota nas convenções do Supabase.

**Feature nova: Tamanhos dentro de Componentes** (pedido do dono: "não quero duplicar um componente só por causa do tamanho"). Nova tabela `tamanhos_componente`; `itens_componente` passou a apontar pra `tamanho_componente_id` (não mais direto pro componente); `produto_componentes` ganhou `tamanho_componente_id`. **Envolveu migração no Supabase de produção — o dono aplicou manualmente pelo SQL editor** (o classificador do auto-mode bloqueia `DROP COLUMN` em banco vivo vindo do agente; script fornecido pronto). Ficha detalhada no `AGENTS.md`. Cobre: criar/renomear/excluir tamanho, copiar insumos de outro tamanho ao criar um novo, reordenar tamanhos por arrasto, e escolher qual tamanho de um componente aplicar ao montar um produto (só pergunta quando há mais de um).

**UX de confirmação**: novo `confirmarAcao` (`lib/presentation/components/confirm_dialog.dart`), aplicado em todo delete de item avulso, duplicar componente (que também ganhou spinner de carregamento — sem isso o toque parecia não fazer nada e convidava a tocar de novo, criando cópias repetidas) e copiar ficha técnica entre porções.

**Pendências conhecidas:**
- **A reordenação de tamanhos por arrasto (segurar e arrastar) não foi testada por clique** — a ferramenta de automação usada nesta sessão não consegue simular o "segurar antes de arrastar" (~500ms) que o gesto exige. O código espelha exatamente o padrão já comprovado de `tipos_reorder_screen.dart`/`componentes_screen.dart` (mesma técnica de `ReorderableDelayedDragStartListener` + `_pendingSavedIds`), então a confiança é alta, mas **vale o dono confirmar no próprio teste**.
- Nada disso foi testado no **Android** ainda (só web) — ver limitação da seção 2.
- Dados de teste ficaram na conta de teste durante a validação (ex.: componente "Massa de Pizza" com tamanhos Família/Grande/Pequena/Média, uma cópia dele, produto "Pizza Calabresa" com 4 porções) — apagar quando quiser.

## 1. Estado atual — onde paramos

O app está **reescrito em Flutter** (Dart), rodando em **Windows + Android + Web** a partir de uma única base de código. O projeto Flutter fica na **raiz do repositório** (`lib/`, `android/`, `windows/`, `pubspec.yaml`).

O PR `flutter-rewrite` **já foi mergeado em `main`** (`9d43ab6`). `main` é o branch de trabalho atual; `flutter-rewrite` ainda existe no remoto mas está obsoleto. Versão atual: **1.4.0+6** (`pubspec.yaml` + `lib/config/app_version.dart`, bump feito nesta sessão — ainda não commitado).

Desde o merge, o trabalho girou em torno de:
- **Deploy web automático via GitHub Pages** (CI em `.github/workflows/deploy-web.yml`, dispara em todo push para `main`): https://kurobisu.github.io/menuvem-lojista/
- **UX de login**: olhinho de mostrar senha, contas salvas com login rápido, reset de senha, limpeza de cache ao trocar de conta.
- **Tipos e componentes de ficha técnica**: cadastro livre de tipos pelo usuário, exclusão/reordenação de tipos e componentes, ícone de unidade, folhas (bottom sheets) mobile-friendly, emoji e teclado corrigidos no formulário de Produto.
- Correção da tendência de preço invertida no dashboard.

## 2. O que está validado (e o que não está)

Validado:
- `flutter analyze` limpo (só infos cosméticos conhecidos — ver nota do `--no-fatal-infos` no workflow de deploy).
- `flutter build windows` gera `build\windows\x64\runner\Release\lojista.exe`, que abre sem crash.
- **Web publicado e ao vivo** em https://kurobisu.github.io/menuvem-lojista/ via CI, contra o Supabase real de produção.
- **APK Android gerado e validado no device** (Infinix X670): `flutter build apk --debug` + Run pelo Android Studio. App sobe, Supabase conecta, locale pt_BR detectado.

As três plataformas (Android, Windows, Web) estão validadas em algum momento, mas as features mais recentes (tipos/componentes livres, reordenação, folhas mobile) foram validadas majoritariamente **via web/desktop** — vale conferir no device Android na próxima sessão se ainda não foi feito.

**Atenção para agentes:** o build Android **não pode ser verificado pelo agente** — o Gradle falha com `java.io.IOException: Unable to establish loopback connection` no ambiente sandbox (limitação do ambiente, não do projeto — confirmado comparando com o projeto vizinho CofreNuvem, que tem o mesmo sintoma). Portanto: mudanças que afetem o build Android precisam ser testadas pelo dono; `flutter analyze` e `flutter build windows` funcionam para o agente e cobrem boa parte. O deploy web (CI) também serve como verificação indireta de build.

## 3. Bugs relevantes já corrigidos

Histórico completo dos três bugs "clássicos" do rewrite (race de auth no redirect, locale pt_BR, navegação sem botão de voltar) e como não reintroduzi-los está na seção "Gotchas" do `AGENTS.md` — não duplicado aqui.

Bugs adicionais corrigidos após o merge (branch `main`):
- Login parava de navegar de novo, dessa vez porque um `Provider<bool>` cacheava a sessão indefinidamente (`dadb33e`).
- Cache de dados de outra conta vazava ao trocar de usuário logado (`a28e02b`).
- Tendência de preço no dashboard aparecia invertida (`0d2f604`).
- Reordenar tipos/componentes salvava e depois revertia a ordem visualmente (`db963d9`).
- `flutter analyze` no CI de deploy derrubava o build por causa de infos, não só erros/warnings — corrigido com `--no-fatal-infos` (`1aa84b9`).

## 4. Contexto operacional (máquina do dono)

- **Windows PowerShell**; projeto em `D:\Projetos Antigravity\menuvem_lojista`.
- **Flutter SDK em `D:\flutter` e NÃO está no PATH** — usar `D:\flutter\bin\flutter.bat` quando `flutter` não for encontrado.
- adb: `C:\Users\Usuário\AppData\Local\Android\Sdk\platform-tools\adb.exe`; device Infinix X670 (Android 13, serial `089092525K001974`) via USB debug.
- **Dirigir a UI via adb** (técnica testada e confiável): screenshot com `adb shell screencap -p /sdcard/s.png` + `adb pull /sdcard/s.png <temp>`, ler a imagem com a ferramenta Read para decidir coordenadas; tocar com `adb shell input tap X Y` (tela 1080×2400); texto com `adb shell input text "texto"` (espaço = `%s`). Logs: `adb logcat -d | Select-String "menuvem|flutter|FATAL"`.
- **Checagem rápida de UI sem device**: `flutter run -d web-server --web-port=8765` e abrir no browser, ou direto no site publicado (https://kurobisu.github.io/menuvem-lojista/).
- Erro transitório conhecido do shell: `ChildProcess.kill` → simplesmente repetir o comando.
- **Sem `gh` CLI instalado** (confirmado 19/08/2026); push funciona via credenciais Git já cacheadas no Windows. PR é criado manualmente pela URL que o `git push` imprime. Repo: `kurobisu/menuvem-lojista`.

## 5. Conta de teste

Existe uma conta de teste criada no roteiro E2E da época do Kotlin — o e-mail é `lojista@teste.com`. A senha está no histórico do git (commit `2c5d0c1` em diante), mas **não é repetida aqui de propósito**: o `AGENTS.md` avisa que o repo pode ser público. Se o login falhar, basta recriar pelo botão "Cadastre-se". Considere trocar essa senha caso o repositório seja público.

## 6. Regras de segurança (inegociáveis)

- `lib/config/env.dart` (URL + anon key do Supabase) **nunca** commitar — já está no `.gitignore`. O template versionado é `lib/config/env.example.dart`. No CI de deploy web, esse arquivo é gerado a partir dos secrets `SUPABASE_URL`/`SUPABASE_ANON_KEY` do GitHub Actions.
- **Secret key (`sb_secret_...`) nunca** no repo nem no app — só a anon key no cliente. (Recomendado ao dono: rotacionar a secret e deixar o repo privado no GitHub.)
- Commit/push só quando o dono pedir.

## 7. Próximos passos sugeridos

0. **Confirmar a reordenação de tamanhos por arrasto** (segurar e arrastar um chip na barra de tamanhos de um componente) — é a única coisa desta sessão que não foi testada por clique, ver seção 0.
1. **Validar no Android** tudo desta sessão e da anterior (layout responsivo, porções, tamanhos em componentes, ajuda contextual, tutorial) — só passou por web até agora.
2. Fila de features (todas já especificadas no `AGENTS.md`, roadmap "not yet implemented"): despesas da loja, canais de venda com taxa %, fornecedor opcional na lista, integração OpenDelivery (alimenta gráficos de lucro líquido).
3. Branch `flutter-rewrite` no remoto está obsoleto desde o merge — considerar apagar (`git push origin --delete flutter-rewrite`) quando o dono confirmar que não precisa mais dele.
4. Limpar os dados de teste deixados na conta de teste durante a validação desta sessão (ver seção 0).
