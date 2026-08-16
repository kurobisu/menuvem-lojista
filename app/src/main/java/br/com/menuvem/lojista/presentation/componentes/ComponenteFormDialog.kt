package br.com.menuvem.lojista.presentation.componentes

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.FilterChip
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
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.Componente
import br.com.menuvem.lojista.domain.model.TipoComponente
import br.com.menuvem.lojista.presentation.components.formatarTipo

/**
 * Dialog de criação/edição de componente: nome + tipo (Massa, Sabor,
 * Embalagem, Outro). O tipo organiza a biblioteca e sugere divisões.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ComponenteFormDialog(
    componente: Componente? = null,
    onDismiss: () -> Unit,
    onConfirm: (nome: String, tipo: TipoComponente) -> Unit
) {
    var nome by remember { mutableStateOf(componente?.nome ?: "") }
    var tipo by remember { mutableStateOf(componente?.tipo ?: TipoComponente.OUTRO) }

    val isValid = nome.isNotBlank()

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (componente == null) "Novo Componente" else "Editar Componente") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = nome,
                    onValueChange = { nome = it },
                    label = { Text("Nome") },
                    placeholder = { Text("Ex.: Pizza - Massa Grande 35cm") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                    modifier = Modifier.fillMaxWidth()
                )
                Text("Tipo", style = androidx.compose.material3.MaterialTheme.typography.labelMedium)
                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TipoComponente.entries.forEach { opcao ->
                        FilterChip(
                            selected = tipo == opcao,
                            onClick = { tipo = opcao },
                            label = { Text(formatarTipo(opcao)) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(nome.trim(), tipo) },
                enabled = isValid
            ) { Text("Salvar") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}