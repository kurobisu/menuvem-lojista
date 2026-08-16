package br.com.menuvem.lojista.presentation.products

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.PurplePrimary

/**
 * Bottom sheet para adicionar um insumo à ficha técnica do produto:
 * busca o insumo na biblioteca e informa quantidade (na unidade de uso)
 * e perda/rendimento (%).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddFichaItemBottomSheet(
    searchQuery: String,
    searchResults: List<Insumo>,
    isSearching: Boolean,
    onSearchChanged: (String) -> Unit,
    onAddItem: (insumo: Insumo, quantidade: Double, perda: Double) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var selectedInsumo by remember { mutableStateOf<Insumo?>(null) }
    var quantidade by remember { mutableStateOf("") }
    var perda by remember { mutableStateOf("0") }

    val quantidadeVal = quantidade.replace(",", ".").toDoubleOrNull()
    val perdaVal = perda.replace(",", ".").toDoubleOrNull()
    val isValid = selectedInsumo != null &&
            quantidadeVal != null && quantidadeVal > 0 &&
            perdaVal != null && perdaVal in 0.0..99.9

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
                text = "Adicionar insumo à ficha",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )
            Spacer(modifier = Modifier.height(12.dp))

            OutlinedTextField(
                value = searchQuery,
                onValueChange = onSearchChanged,
                label = { Text("Buscar insumo") },
                leadingIcon = {
                    Icon(Icons.Outlined.Search, contentDescription = null)
                },
                singleLine = true,
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(modifier = Modifier.height(8.dp))

            if (isSearching) {
                Box(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    contentAlignment = Alignment.Center
                ) { CircularProgressIndicator(color = PurplePrimary) }
            } else {
                LazyColumn(modifier = Modifier.heightIn(max = 220.dp)) {
                    items(searchResults, key = { it.id }) { insumo ->
                        val selecionado = selectedInsumo?.id == insumo.id
                        ListItem(
                            headlineContent = {
                                Text(insumo.nome, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            },
                            supportingContent = {
                                val categoria = if (insumo.categoria == CategoriaInsumo.EMBALAGEM)
                                    " · embalagem" else ""
                                Text(
                                    "R$ ${formatarMoeda(insumo.custoAtual)}/${insumo.unidadeCompra}$categoria",
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            },
                            leadingContent = {
                                Icon(
                                    imageVector = Icons.Outlined.Inventory2,
                                    contentDescription = null,
                                    tint = if (selecionado) PurplePrimary
                                    else MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            },
                            colors = ListItemDefaults.colors(
                                containerColor = if (selecionado)
                                    MaterialTheme.colorScheme.secondaryContainer
                                else MaterialTheme.colorScheme.surface
                            ),
                            modifier = Modifier.clickable {
                                selectedInsumo = insumo
                            }
                        )
                        HorizontalDivider()
                    }
                }
            }

            selectedInsumo?.let { insumo ->
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "Quantidade por porção (${insumo.unidadeUso})",
                    style = MaterialTheme.typography.labelMedium
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    OutlinedTextField(
                        value = quantidade,
                        onValueChange = { quantidade = it },
                        label = { Text(insumo.unidadeUso) },
                        placeholder = { Text("Ex.: 150") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                    OutlinedTextField(
                        value = perda,
                        onValueChange = { perda = it },
                        label = { Text("Perda (%)") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = {
                    selectedInsumo?.let { onAddItem(it, quantidadeVal!!, perdaVal!!) }
                },
                enabled = isValid,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Adicionar à ficha técnica")
            }
        }
    }
}
