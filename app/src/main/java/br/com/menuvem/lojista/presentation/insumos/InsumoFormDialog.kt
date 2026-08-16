package br.com.menuvem.lojista.presentation.insumos

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
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
import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo

/**
 * Dialog de criação/edição de insumo da biblioteca: nome, categoria
 * (insumo/embalagem), unidade de compra, unidade de uso, fator de conversão
 * e custo atual (override manual do preço vindo do histórico de compras).
 */
@Composable
fun InsumoFormDialog(
    insumo: Insumo? = null,
    onDismiss: () -> Unit,
    onConfirm: (
        nome: String,
        categoria: CategoriaInsumo,
        unidadeCompra: String,
        unidadeUso: String,
        fatorConversao: Double,
        custoAtual: Double
    ) -> Unit
) {
    var nome by remember { mutableStateOf(insumo?.nome ?: "") }
    var categoria by remember { mutableStateOf(insumo?.categoria ?: CategoriaInsumo.INSUMO) }
    var unidadeCompra by remember { mutableStateOf(insumo?.unidadeCompra ?: "") }
    var unidadeUso by remember { mutableStateOf(insumo?.unidadeUso ?: "") }
    var fator by remember {
        mutableStateOf(
            insumo?.fatorConversao?.let { f ->
                if (f % 1.0 == 0.0) f.toInt().toString() else f.toString().replace('.', ',')
            } ?: ""
        )
    }
    var custo by remember {
        mutableStateOf(insumo?.custoAtual?.takeIf { it > 0 }?.let {
            String.format("%.2f", it).replace('.', ',')
        } ?: "")
    }

    val fatorVal = fator.replace(",", ".").toDoubleOrNull()
    val custoVal = custo.replace(",", ".").toDoubleOrNull()
    val isValid = nome.isNotBlank() &&
            unidadeCompra.isNotBlank() && unidadeUso.isNotBlank() &&
            fatorVal != null && fatorVal > 0 &&
            (custo.isBlank() || custoVal != null)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (insumo == null) "Novo Insumo" else "Editar Insumo") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = nome,
                    onValueChange = { nome = it },
                    label = { Text("Nome") },
                    placeholder = { Text("Ex.: Calabresa") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                    modifier = Modifier.fillMaxWidth()
                )
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(
                        selected = categoria == CategoriaInsumo.INSUMO,
                        onClick = { categoria = CategoriaInsumo.INSUMO },
                        label = { Text("Insumo") }
                    )
                    FilterChip(
                        selected = categoria == CategoriaInsumo.EMBALAGEM,
                        onClick = { categoria = CategoriaInsumo.EMBALAGEM },
                        label = { Text("Embalagem") }
                    )
                }
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = unidadeCompra,
                        onValueChange = { unidadeCompra = it },
                        label = { Text("Un. compra") },
                        placeholder = { Text("kg") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = unidadeUso,
                        onValueChange = { unidadeUso = it },
                        label = { Text("Un. uso") },
                        placeholder = { Text("g") },
                        singleLine = true,
                        modifier = Modifier.weight(1f)
                    )
                }
                OutlinedTextField(
                    value = fator,
                    onValueChange = { fator = it },
                    label = { Text("Fator de conversão") },
                    placeholder = { Text("Ex.: 1000 (1 kg = 1000 g)") },
                    supportingText = {
                        Text("Quantas unidades de uso cabem em 1 unidade de compra")
                    },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = custo,
                    onValueChange = { custo = it },
                    label = { Text("Custo por un. de compra (opcional)") },
                    placeholder = { Text("Ex.: 46,18") },
                    supportingText = {
                        Text("Atualizado automaticamente pelas compras finalizadas")
                    },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onConfirm(
                        nome.trim(),
                        categoria,
                        unidadeCompra.trim(),
                        unidadeUso.trim(),
                        fatorVal!!,
                        custoVal ?: 0.0
                    )
                },
                enabled = isValid
            ) { Text("Salvar") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}
