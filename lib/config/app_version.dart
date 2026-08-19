/// Versão exibida na UI (rodapé do Login e cabeçalho da Home).
///
/// **Manter em sincronia com `version:` no `pubspec.yaml`.**
///
/// É uma constante, e não o pacote `package_info_plus`, de propósito: aquele
/// pacote é um plugin nativo, e o build Android desta máquina é sensível
/// (ver a seção "Toolchain notes" do AGENTS.md) e não pode ser verificado
/// automaticamente por um agente. O custo dessa escolha é ter que atualizar
/// os dois lugares ao subir a versão.
const String appVersion = '1.4.0';
const String appBuildNumber = '7';

/// Rótulo curto usado na UI, ex.: `v1.1.0 (2)`.
const String appVersionLabel = 'v$appVersion ($appBuildNumber)';
