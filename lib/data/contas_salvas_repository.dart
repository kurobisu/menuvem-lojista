import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Uma conta que o usuário marcou "Salvar dados de login".
///
/// Guarda o **refresh token** do Supabase, nunca a senha: o token dá o mesmo
/// login de um toque, pode ser revogado pelo painel do Supabase e, se vazar,
/// não expõe uma senha que o dono provavelmente reusa em outros lugares.
class ContaSalva {
  const ContaSalva({required this.email, required this.refreshToken});

  final String email;
  final String refreshToken;

  /// Nome curto para o avatar: o trecho antes do @.
  String get apelido => email.split('@').first;

  /// Inicial exibida no círculo do avatar.
  String get inicial => apelido.isEmpty ? '?' : apelido[0].toUpperCase();

  Map<String, dynamic> toJson() => {'email': email, 'refresh_token': refreshToken};

  static ContaSalva? fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final token = json['refresh_token'] as String?;
    if (email == null || token == null || email.isEmpty || token.isEmpty) {
      return null;
    }
    return ContaSalva(email: email, refreshToken: token);
  }
}

const _chave = 'contas_salvas';

/// Lista de contas salvas para o login rápido, persistida em SharedPreferences.
///
/// A ordem importa: a conta usada mais recentemente vai para o começo, que é
/// a ordem em que os avatares aparecem na tela de login.
class ContasSalvasRepository {
  Future<List<ContaSalva>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getStringList(_chave) ?? [];
    return bruto
        .map((linha) {
          try {
            return ContaSalva.fromJson(jsonDecode(linha) as Map<String, dynamic>);
          } catch (_) {
            // entrada corrompida ou de um formato antigo: ignora
            return null;
          }
        })
        .nonNulls
        .toList();
  }

  /// Insere ou atualiza a conta e a move para o começo da lista.
  Future<void> salvar(ContaSalva conta) async {
    final atuais = await listar();
    final semEla = atuais.where((c) => c.email != conta.email);
    await _gravar([conta, ...semEla]);
  }

  Future<void> remover(String email) async {
    final atuais = await listar();
    await _gravar(atuais.where((c) => c.email != email).toList());
  }

  /// Atualiza só o token de uma conta já salva, preservando a posição dela.
  ///
  /// Necessário porque o Supabase **rotaciona** o refresh token a cada
  /// renovação de sessão: sem isto o token guardado envelhece e o login
  /// rápido daquela conta passa a falhar.
  Future<void> atualizarToken(String email, String refreshToken) async {
    final atuais = await listar();
    if (!atuais.any((c) => c.email == email)) return;
    await _gravar([
      for (final conta in atuais)
        if (conta.email == email)
          ContaSalva(email: email, refreshToken: refreshToken)
        else
          conta,
    ]);
  }

  Future<void> _gravar(List<ContaSalva> contas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _chave,
      contas.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
