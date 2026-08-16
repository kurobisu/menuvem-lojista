package br.com.menuvem.lojista.presentation.products

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.presentation.components.DivisorPizzaSelector
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.presentation.components.formatarTipo
import br.com.menuvem.lojista.presentation.components.multiplicadorDeDivisor
import br.com.menuvem.lojista.ui.theme.PurplePrimary

/**
 * Bottom sheet para aplicar um componente a um produto: busca na biblioteca,
 * seleciona e define a divisão (multiplicador) — inteiro (1 sabor) ou 1/n
 * (2 sabores = metade, 3 = um terço...).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddComponenteSheet(
    componentes: List<ComponenteComCusto>,
    onAddComponente: (componenteId: Long, multiplicador: Double) -> Unit,
    onGerenciarComponentes: () -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var busca by remember { mutableStateOf("") }
    var selecionado by remember { mutableStateOf<ComponenteComCusto?>(null) }
    var divisor by remember { mutableStateOf("1") }

    val filtrados = remember(busca, componentes) {
        val q = busca.trim()
        if (q.isBlank()) componentes
        else componentes.filter {
            it.componente.nome.contains(q, ignoreCase = true) ||
                formatarTipo(it.componente.tipo).contains(q, ignoreCase = true)
        }
    }
    val multiplicador = multiplicadorDeDivisor(divisor)
    val isValid = selecionado != null && multiplicador != null && multiplicador > 0

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {
            Text(
                text = "Adicionar componente",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = busca,
                onValueChange = { busca = it },
                label = { Text("Buscar componente") },
                leadingIcon = {
                    Icon(Icons.Outlined.Settings, contentDescription = null)
                },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            LazyColumn(modifier = Modifier.heightIn(max = 200.dp)) {
                items(filtrados, key = { it.componente.id }) { item ->
                    val selecionadoId = selecionado?.componente?.id
                    ListItem(
                        headlineContent = {
                            Text(item.componente.nome, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        },
                        supportingContent = {
                            Text(
                                "${formatarTipo(item.componente.tipo)} · ${item.quantidadeItens} insumo(s) · R$ ${formatarMoeda(item.custo)}",
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        },
                        leadingContent = {
                            Icon(
                                imageVector = Icons.Filled.Widgets,
                                contentDescription = null,
                                tint = if (selecionadoId == item.componente.id) PurplePrimary
                                else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        },
                        colors = ListItemDefaults.colors(
                            containerColor = if (selecionadoId == item.componente.id)
                                MaterialTheme.colorScheme.secondaryContainer
                            else MaterialTheme.colorScheme.surface
                        ),
                        modifier = Modifier.clickable { selecionado = item }
                    )
                    HorizontalDivider()
                }
            }

            selecionado?.let {
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "Como aplicar \"${it.componente.nome}\"?",
                    style = MaterialTheme.typography.labelMedium
                )
                Spacer(modifier = Modifier.height(8.dp))
                DivisorPizzaSelector(divisor = divisor, onDivisorChange = { divisor = it })
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "1 parte = inteiro · 2 partes = metade dos insumos (ex.: 2 sabores na mesma massa) · 3 = um terço",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    selecionado?.let { onAddComponente(it.componente.id, multiplicador!!) }
                },
                enabled = isValid,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Adicionar componente")
            }

            TextButton(
                onClick = onGerenciarComponentes,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            ) {
                Text("Criar/gerenciar componentes", style = MaterialTheme.typography.labelMedium)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SeletorDivisaoDialog(
    titulo: String,
    divisorInicial: String,
    onDismiss: () -> Unit,
    onConfirm: (multiplicador: Double) -> Unit
) {
    var divisor by remember { mutableStateOf(divisorInicial) }
    val multiplicador = multiplicadorDeDivisor(divisor)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(titulo) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text(
                    "A divisão multiplica os insumos do componente. Ex.: metade (2 sabores) = × 1/2.",
                    style = MaterialTheme.typography.bodyMedium
                )
                DivisorPizzaSelector(divisor = divisor, onDivisorChange = { divisor = it })
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(multiplicador!!) },
                enabled = multiplicador != null && multiplicador > 0
            ) { Text("Salvar") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancelar") }
        }
    )
}