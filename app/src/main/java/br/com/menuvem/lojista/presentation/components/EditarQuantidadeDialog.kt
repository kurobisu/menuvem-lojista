package br.com.menuvem.lojista.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp

/**
 * Diálogo genérico de edição de quantidade + perda de um item de ficha
 * (usado tanto na ficha de produto quanto nos itens de um componente).
 */
@Composable
fun EditarQuantidadeDialog(
    titulo: String,
    unidadeUso: String,
    quantidadeInicial: Double,
    perdaInicial: Double,
    onDismiss: () -> Unit,
    onConfirm: (quantidade: Double, perda: Double) -> Unit
) {
    var quantidade by remember {
        mutableStateOf(formatarQuantidade(quantidadeInicial).replace('.', ','))
    }
    var perda by remember {
        mutableStateOf(
            if (perdaInicial % 1.0 == 0.0) perdaInicial.toInt().toString()
            else perdaInicial.toString().replace('.', ',')
        )
    }

    val quantidadeVal = quantidade.replace(",", ".").toDoubleOrNull()
    val perdaVal = perda.replace(",", ".").toDoubleOrNull()
    val isValid = quantidadeVal != null && quantidadeVal > 0 &&
            perdaVal != null && perdaVal in 0.0..99.9

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(titulo, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = quantidade,
                    onValueChange = { quantidade = it },
                    label = { Text("Quantidade ($unidadeUso)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = perda,
                    onValueChange = { perda = it },
                    label = { Text("Perda (%)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(quantidadeVal!!, perdaVal!!) },
                enabled = isValid
            ) { Text("Salvar") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}

fun formatarQuantidade(valor: Double): String =
    if (valor % 1.0 == 0.0) valor.toInt().toString() else String.format("%.2f", valor)