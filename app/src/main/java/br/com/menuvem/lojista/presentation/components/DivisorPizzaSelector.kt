package br.com.menuvem.lojista.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.FilterChip
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import kotlin.math.roundToInt

/**
 * Seletor de divisão de um componente (ex.: sabor) aplicado a um produto.
 * O divisor n significa que o componente entra com 1/n (n sabores na mesma
 * base): inteiro (1), meio (2), terço (3), quarto (4) ou valor livre.
 */
@Composable
fun DivisorPizzaSelector(
    divisor: String,
    onDivisorChange: (String) -> Unit
) {
    val selecionado = { valor: Int -> divisor.trim() == valor.toString() }
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("Divisão do componente", style = androidx.compose.material3.MaterialTheme.typography.labelMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            FilterChip(
                selected = selecionado(1),
                onClick = { onDivisorChange("1") },
                label = { Text("Inteiro") }
            )
            FilterChip(
                selected = selecionado(2),
                onClick = { onDivisorChange("2") },
                label = { Text("1/2") }
            )
            FilterChip(
                selected = selecionado(3),
                onClick = { onDivisorChange("3") },
                label = { Text("1/3") }
            )
            FilterChip(
                selected = selecionado(4),
                onClick = { onDivisorChange("4") },
                label = { Text("1/4") }
            )
        }
        OutlinedTextField(
            value = divisor,
            onValueChange = onDivisorChange,
            label = { Text("Dividir por (nº de partes/sabores)") },
            placeholder = { Text("1 = inteiro · 2 = metade · 3 = um terço") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

/** Converte o divisor digitado (n) no multiplicador 1/n. Null se inválido. */
fun multiplicadorDeDivisor(divisor: String): Double? {
    val valor = divisor.replace(",", ".").toDoubleOrNull() ?: return null
    return if (valor > 0) 1.0 / valor else null
}

/** Converte um multiplicador no divisor correspondente para edição. */
fun divisorDeMultiplicador(multiplicador: Double): String {
    if (multiplicador <= 0) return "1"
    val inverso = 1.0 / multiplicador
    val n = inverso.roundToInt()
    return if (Math.abs(inverso - n) < 0.001) n.toString()
    else String.format("%.2f", inverso).replace('.', ',')
}

/** Descreve o multiplicador para exibição (ex.: "× 1/2 · 2 sabores"). */
fun descreverMultiplicador(multiplicador: Double): String {
    if (multiplicador == 1.0) return "× 1 · inteiro"
    val inverso = 1.0 / multiplicador
    val n = inverso.roundToInt()
    return if (n > 1 && Math.abs(inverso - n) < 0.001) {
        "× 1/$n · $n partes"
    } else {
        "× ${String.format("%.2f", multiplicador).replace('.', ',')}"
    }
}