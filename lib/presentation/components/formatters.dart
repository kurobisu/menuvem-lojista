import 'package:intl/intl.dart';

final _moedaFormat = NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2);

/// Formata um valor como "1.234,56" (sem o prefixo "R$" — cada tela adiciona).
String formatarMoeda(double valor) => _moedaFormat.format(valor).trim();

/// Converte texto digitado com vírgula decimal pt-BR (ex.: "50,00") em double.
double? parseDecimalPtBr(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));
