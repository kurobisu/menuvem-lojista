import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_version.dart';
import '../../data/contas_salvas_repository.dart';
import '../../theme/app_theme.dart';
import '../components/responsive.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.modoTroca = false});

  /// Alcançada por "Trocar de conta" com uma sessão já ativa. Nesse caso a
  /// sessão atual **não** passa por logout (o que revogaria o refresh token
  /// salvo dela); a troca acontece direto por `setSession`.
  final bool modoTroca;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrarComConta(ContaSalva conta) async {
    final emailQueFalhou = await ref
        .read(authControllerProvider.notifier)
        .entrarComContaSalva(conta);
    if (!mounted) return;
    if (emailQueFalhou != null) {
      // Token expirado: preenche o e-mail para o usuário só digitar a senha.
      _emailController.text = emailQueFalhou;
      _senhaController.clear();
      return;
    }
    // No modo troca já havia sessão, então o redirect do router não dispara
    // sozinho — a navegação precisa ser explícita.
    if (widget.modoTroca) context.go('/home');
  }

  Future<void> _submit(String email, String senha) async {
    await ref.read(authControllerProvider.notifier).submit(email, senha);
    if (!mounted) return;
    final deuCerto = ref.read(authControllerProvider).error == null;
    if (widget.modoTroca && deuCerto) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text;
    final senha = _senhaController.text;
    final isValid =
        email.contains('@') && senha.length >= 6 && !uiState.isLoading;

    return Scaffold(
      appBar: widget.modoTroca
          ? AppBar(
              title: const Text('Trocar de conta'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
                onPressed: () => context.go('/home'),
              ),
            )
          : null,
      body: MaxWidthCenter(
        maxWidth: kFormMaxWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [purplePrimary, purpleLight],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menuvem',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                      Text(
                        'Lojista',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Precifique com dados, não com achismo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (uiState.contasSalvas.isNotEmpty &&
                        !uiState.isSignUpMode) ...[
                      _ContasSalvas(
                        contas: uiState.contasSalvas,
                        habilitado: !uiState.isLoading,
                        onEntrar: _entrarComConta,
                        onRemover: controller.removerConta,
                      ),
                      const Divider(height: 32),
                    ],
                    Text(
                      uiState.isSignUpMode ? 'Criar conta' : 'Entrar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _senhaController,
                      obscureText: !uiState.senhaVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha (mín. 6 caracteres)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            uiState.senhaVisivel
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          tooltip: uiState.senhaVisivel
                              ? 'Ocultar senha'
                              : 'Mostrar senha',
                          onPressed: controller.toggleSenhaVisivel,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: uiState.salvarLogin,
                          onChanged: (v) =>
                              controller.setSalvarLogin(v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                controller.setSalvarLogin(!uiState.salvarLogin),
                            child: Text(
                              'Salvar dados de login',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: uiState.isLoading
                              ? null
                              : () => controller.resetarSenha(
                                  _emailController.text.trim(),
                                ),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ],
                    ),
                    if (uiState.error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        uiState.error!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: errorRed),
                      ),
                    ],
                    if (uiState.aviso != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        uiState.aviso!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: successGreen),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: isValid ? () => _submit(email, senha) : null,
                      child: uiState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              uiState.isSignUpMode ? 'Criar conta' : 'Entrar',
                            ),
                    ),
                    TextButton(
                      onPressed: controller.toggleMode,
                      child: Text(
                        uiState.isSignUpMode
                            ? 'Já tem conta? Entrar'
                            : 'Não tem conta? Cadastre-se',
                        style: const TextStyle(color: purplePrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Text(
                    appVersionLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa horizontal de avatares das contas salvas. Um toque entra direto.
class _ContasSalvas extends StatelessWidget {
  const _ContasSalvas({
    required this.contas,
    required this.habilitado,
    required this.onEntrar,
    required this.onRemover,
  });

  final List<ContaSalva> contas;
  final bool habilitado;
  final void Function(ContaSalva) onEntrar;
  final void Function(String email) onRemover;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrar rapidamente',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: contas.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final conta = contas[index];
              return SizedBox(
                width: 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: habilitado ? () => onEntrar(conta) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: purpleContainer,
                              child: Text(
                                conta.inicial,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: purpleOnContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              conta.apelido,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: habilitado ? () => onRemover(conta.email) : null,
                        customBorder: const CircleBorder(),
                        child: Tooltip(
                          message: 'Remover ${conta.email}',
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: errorRed, width: 1),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: errorRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
