package br.com.menuvem.lojista.presentation.products

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
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.Produto

/**
 * Dialog de criação/edição de produto: nome, margem-alvo (%) e preço de
 * venda atual (opcional — usado para comparar a margem real com a meta).
 */
@Composable
fun ProdutoFormDialog(
    produto: Produto? = null,
    onDismiss: () -> Unit,
    onConfirm: (nome: String, margemAlvo: Double, precoVenda: Double?) -> Unit
) {
    var nome by remember { mutableStateOf(produto?.nome ?: "") }
    var margem by remember {
        mutableStateOf(
            produto?.margemAlvoPercentual?.let { m ->
                if (m % 1.0 == 0.0) m.toInt().toString() else m.toString().replace('.', ',')
            } ?: "30"
        )
    }
    var preco by remember {
        mutableStateOf(produto?.precoVendaAtual?.let { String.format("%.2f", it).replace('.', ',') } ?: "")
    }

    val margemVal = margem.replace(",", ".").toDoubleOrNull()
    val precoVal = preco.replace(",", ".").toDoubleOrNull()
    val isValid = nome.isNotBlank() &&
            margemVal != null && margemVal in 0.0..99.9 &&
            (preco.isBlank() || precoVal != null)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (produto == null) "Novo Produto" else "Editar Produto") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = nome,
                    onValueChange = { nome = it },
                    label = { Text("Nome") },
                    placeholder = { Text("Ex.: Pizza Grande de Calabresa") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = margem,
                    onValueChange = { margem = it },
                    label = { Text("Margem de lucro alvo (%)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = preco,
                    onValueChange = { preco = it },
                    label = { Text("Preço de venda atual (opcional)") },
                    placeholder = { Text("0,00") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onConfirm(nome.trim(), margemVal!!, if (preco.isBlank()) null else precoVal)
                },
                enabled = isValid
            ) { Text("Salvar") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}
