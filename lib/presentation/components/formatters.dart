import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _moedaFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: '',
  decimalDigits: 2,
);

/// Formata um valor como "1.234,56" (sem o prefixo "R$" — cada tela adiciona).
String formatarMoeda(double valor) => _moedaFormat.format(valor).trim();

/// Converte texto digitado com vírgula decimal pt-BR (ex.: "50,00") em double.
double? parseDecimalPtBr(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Restringe a dígitos e no máximo uma vírgula decimal -- mesmo formato que
/// parseDecimalPtBr espera. Usado em quantidade, perda % e outros campos
/// numéricos que não são dinheiro (esses usam MoedaInputFormatter). Sem essa
/// trava o campo aceitava qualquer caractere, incluindo letras, o que dava
/// null silencioso no parse e podia estragar o cálculo do custo.
final decimalPtBrInputFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  if (newValue.text.isEmpty) return newValue;
  if (!RegExp(r'^\d*,?\d*$').hasMatch(newValue.text)) return oldValue;
  return newValue;
});

/// Lê um campo formatado por [MoedaInputFormatter] ("1.234,56") como double.
///
/// Considera só os dígitos e trata os dois últimos como centavos — o mesmo
/// contrato da máscara. Usar [parseDecimalPtBr] aqui daria `null` a partir de
/// mil, porque o separador de milhar vira um segundo ponto decimal.
double? parseMoedaPtBr(String texto) {
  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitos.isEmpty) return null;
  return int.parse(digitos) / 100;
}

/// Máscara de dinheiro: o que for digitado entra pela direita, em centavos.
///
/// Digitar `4`, `2`, `5` mostra `0,04` → `0,42` → `4,25`. É o comportamento de
/// caixa eletrônico que o lojista já conhece de outros apps, e evita a dúvida
/// de "digitei 425, isso é quatro reais ou quatrocentos?". O símbolo `R$` fica
/// no `prefixText` do campo, fora do texto editável — assim o cursor nunca cai
/// dentro dele e o parse não precisa limpá-lo.
///
/// Padrão herdado do projeto irmão CofreNuvem
/// (`lib/utils/currency_input_formatter.dart`).
class MoedaInputFormatter extends TextInputFormatter {
  const MoedaInputFormatter();

  /// ~13 dígitos já passam de um trilhão de reais; o corte só existe para um
  /// colar acidental não estourar o `int.parse`.
  static const _maxDigitos = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return const TextEditingValue();
    if (digitos.length > _maxDigitos) {
      digitos = digitos.substring(0, _maxDigitos);
    }
    final texto = formatarMoeda(int.parse(digitos) / 100);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
