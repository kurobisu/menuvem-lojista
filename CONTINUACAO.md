# CONTINUACAO.md — Handoff Menuvem Lojista

Documento vivo de passagem de sessão: **onde paramos, o que já está validado, qual é a próxima ação**. Contexto durável (decisões de domínio, convenções, arquitetura) fica no `AGENTS.md`; este arquivo é só o estado corrente.

Última atualização: **17/08/2026**.

## 1. Estado atual — onde paramos

O app foi **reescrito em Flutter** (Dart) mirando **Windows + Android** a partir de uma única base de código. O projeto Flutter agora fica na **raiz do repositório** (`lib/`, `android/`, `windows/`, `pubspec.yaml`).

O app Kotlin/Compose anterior **foi removido da árvore de trabalho** em 17/08/2026 — ele estava atrapalhando (o Android Studio abria o projeto Kotlin em vez do Flutter). Está preservado no histórico do git até o commit `20fe316`, e no branch `main` enquanto o PR do rewrite não for mergeado.

**Branch atual**: `flutter-rewrite` (PR aberto para `main`).

## 2. O que está validado (e o que não está)

Validado:
- `flutter analyze` limpo (só infos cosméticos conhecidos).
- `flutter build windows` gera `build\windows\x64\runner\Release\lojista.exe`, que abre sem crash.
- App testado rodando em `flutter run -d web-server` contra o **Supabase real de produção**: login, home com listas/tendências reais, biblioteca de insumos, e Produtos mostrando fichas técnicas de 15 insumos com custo e margem calculados corretamente. Os números batem com o que o app Kotlin produzia.

- **APK Android gerado e rodando no device** (Infinix X670, 17/08/2026): `flutter build apk --debug` + Run pelo Android Studio. App sobe, Supabase conecta, locale pt_BR detectado. As três plataformas (Android, Windows, web) estão validadas.

**Atenção para agentes:** o build Android **não pode ser verificado pelo agente** — o Gradle falha com `java.io.IOException: Unable to establish loopback connection` no ambiente sandbox. Isso foi comprovado como limitação do ambiente e não do projeto: o projeto vizinho CofreNuvem, que builda normalmente na máquina do dono, falha com o **mesmo erro** quando rodado pelo agente. Portanto: mudanças que afetem o build Android precisam ser testadas pelo dono; `flutter analyze` e `flutter build windows` funcionam para o agente e cobrem boa parte.

## 3. Bugs encontrados no teste manual do dono (todos corrigidos)

Três bugs reais apareceram só quando o dono testou de verdade — vale lembrar que teste manual pegou o que a verificação automática não pegou:

1. **Login não fazia nada** (botão animava, sem erro, sem navegar). Race entre o `refreshListenable` do go_router e um `StreamProvider` do Riverpod, ambos ouvindo o mesmo stream de auth do Supabase: o `redirect` rodava com valor em cache desatualizado. Corrigido lendo `currentSession` direto do SDK (síncrono) em `isAuthenticatedProvider`.
2. **Crash de locale** na Home ao formatar data pt-BR — faltava `initializeDateFormatting('pt_BR')` no `main()`.
3. **Nenhuma tela tinha botão de voltar** — a navegação usava `context.go()` (substitui a rota) em vez de `context.push()` (empilha). Trocado em todos os 16 pontos de drill-down.

Detalhe completo desses três (e como não reintroduzir) na seção "Gotchas" do `AGENTS.md`.

## 4. Contexto operacional (máquina do dono)

- **Windows PowerShell**; projeto em `D:\Projetos Antigravity\menuvem_lojista`.
- **Flutter SDK em `D:\flutter` e NÃO está no PATH** — usar `D:\flutter\bin\flutter.bat` quando `flutter` não for encontrado.
- adb: `C:\Users\Usuário\AppData\Local\Android\Sdk\platform-tools\adb.exe`; device Infinix X670 (Android 13, serial `089092525K001974`) via USB debug.
- **Dirigir a UI via adb** (técnica testada e confiável): screenshot com `adb shell screencap -p /sdcard/s.png` + `adb pull /sdcard/s.png <temp>`, ler a imagem com a ferramenta Read para decidir coordenadas; tocar com `adb shell input tap X Y` (tela 1080×2400); texto com `adb shell input text "texto"` (espaço = `%s`). Logs: `adb logcat -d | Select-String "menuvem|flutter|FATAL"`.
- **Checagem rápida de UI sem device**: `flutter run -d web-server --web-port=8765` e abrir no browser — foi assim que a validação contra o Supabase real foi feita.
- Erro transitório conhecido do shell: `ChildProcess.kill` → simplesmente repetir o comando.
- **Sem `gh` CLI instalado**; push funciona via credenciais Git já cacheadas no Windows. PR é criado manualmente pela URL que o `git push` imprime.

## 5. Conta de teste

Existe uma conta de teste criada no roteiro E2E da época do Kotlin — o e-mail é `lojista@teste.com`. A senha está no histórico do git (commit `2c5d0c1` em diante), mas **não é repetida aqui de propósito**: o `AGENTS.md` avisa que o repo pode ser público. Se o login falhar, basta recriar pelo botão "Cadastre-se". Considere trocar essa senha caso o repositório seja público.

## 6. Regras de segurança (inegociáveis)

- `lib/config/env.dart` (URL + anon key do Supabase) **nunca** commitar — já está no `.gitignore`. O template versionado é `lib/config/env.example.dart`.
- **Secret key (`sb_secret_...`) nunca** no repo nem no app — só a anon key no cliente. (Recomendado ao dono: rotacionar a secret e deixar o repo privado no GitHub.)
- Commit/push só quando o dono pedir.

## 7. Próximos passos sugeridos

1. **Gerar e testar o APK no device** (bloqueador — ver seção 2). Rodar o roteiro E2E: login → criar lista → adicionar insumo → finalizar compra → conferir que o custo do produto recalculou.
2. Mergear o PR `flutter-rewrite` → `main` depois que o APK estiver validado.
3. Fila de features (todas já especificadas no `AGENTS.md`): despesas da loja, canais de venda com taxa %, fornecedor opcional na lista, integração OpenDelivery.
