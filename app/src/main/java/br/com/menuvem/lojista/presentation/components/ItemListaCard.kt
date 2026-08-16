package br.com.menuvem.lojista.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.ItemLista
import br.com.menuvem.lojista.domain.model.TendenciaPreco
import java.util.Locale

/**
 * Card de item na lista de compras com:
 * - Checkbox de marcação
 * - Nome e quantidade/unidade
 * - Preço e subtotal (editável)
 * - Indicador de tendência (se o item estiver vinculado a insumo)
 * - Tachado quando comprado
 */
@Composable
fun ItemListaCard(
    item: ItemLista,
    tendencia: TendenciaPreco?,
    onToggle: (Boolean, Double) -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    var preco by remember(item.id, item.precoUnitario) {
        mutableStateOf(if (item.precoUnitario > 0) item.precoUnitario.toString() else "")
    }
    var showDeleteDialog by remember { mutableStateOf(false) }

    val bgColor by animateColorAsState(
        targetValue = if (item.comprado)
            MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.6f)
        else
            MaterialTheme.colorScheme.surface,
        animationSpec = spring(),
        label = "bg"
    )

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Remover item?") },
            text = { Text("\"${item.nomeItem}\" será removido da lista.") },
            confirmButton = {
                TextButton(onClick = {
                    onDelete()
                    showDeleteDialog = false
                }) { Text("Remover", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) { Text("Cancelar") }
            }
        )
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = bgColor),
        elevation = CardDefaults.cardElevation(defaultElevation = if (item.comprado) 0.dp else 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Checkbox
            Checkbox(
                checked = item.comprado,
                onCheckedChange = { checked ->
                    val precoFinal = preco.replace(",", ".").toDoubleOrNull() ?: 0.0
                    onToggle(checked, precoFinal)
                },
                colors = CheckboxDefaults.colors(
                    checkedColor = MaterialTheme.colorScheme.primary,
                    checkmarkColor = Color.White
                )
            )

            Spacer(modifier = Modifier.width(8.dp))

            // Conteúdo principal
            Column(modifier = Modifier.weight(1f)) {
                // Nome + badge de insumo + tendência
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = item.nomeItem,
                        style = MaterialTheme.typography.titleSmall,
                        textDecoration = if (item.comprado) TextDecoration.LineThrough else TextDecoration.None,
                        color = if (item.comprado)
                            MaterialTheme.colorScheme.onSurfaceVariant
                        else
                            MaterialTheme.colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )

                    if (item.estaVinculado) {
                        Surface(
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primaryContainer
                        ) {
                            Icon(
                                imageVector = Icons.Default.ShoppingCart,
                                contentDescription = "Insumo cadastrado",
                                tint = MaterialTheme.colorScheme.primary,
                                modifier = Modifier
                                    .padding(3.dp)
                                    .size(10.dp)
                            )
                        }
                    }

                    tendencia?.let {
                        TendenciaIndicador(tendencia = it)
                    }
                }

                Spacer(modifier = Modifier.height(2.dp))

                // Quantidade e unidade
                Text(
                    text = "${formatarNumero(item.quantidade)} ${item.unidade}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Preço e subtotal
            Column(horizontalAlignment = Alignment.End) {
                if (!item.comprado) {
                    // Campo editável de preço
                    OutlinedTextField(
                        value = preco,
                        onValueChange = { preco = it.filter { c -> c.isDigit() || c == '.' || c == ',' } },
                        label = { Text("R$", style = MaterialTheme.typography.labelSmall) },
                        modifier = Modifier.width(90.dp),
                        singleLine = true,
                        textStyle = MaterialTheme.typography.bodySmall,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f)
                        )
                    )
                } else {
                    // Preço final
                    Text(
                        text = "R$ ${formatarMoeda(item.precoUnitario)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "= R$ ${formatarMoeda(item.precoTotal)}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
            }

            // Botão deletar
            IconButton(
                onClick = { showDeleteDialog = true },
                modifier = Modifier.size(32.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Remover",
                    tint = MaterialTheme.colorScheme.error.copy(alpha = 0.6f),
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }
}

private fun formatarNumero(value: Double): String =
    if (value == value.toLong().toDouble()) value.toLong().toString()
    else String.format(Locale("pt", "BR"), "%.2f", value)

fun formatarMoeda(value: Double): String =
    String.format(Locale("pt", "BR"), "%.2f", value)
