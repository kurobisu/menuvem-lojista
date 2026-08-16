package br.com.menuvem.lojista.presentation.shopping

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.Insumo

/**
 * Bottom Sheet para adicionar um item à lista de compras.
 * Suporta busca de insumos cadastrados e adição livre.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddItemBottomSheet(
    searchQuery: String,
    searchResults: List<Insumo>,
    isSearching: Boolean,
    onSearchChanged: (String) -> Unit,
    onAddFreeItem: (nome: String, quantidade: Double, unidade: String, preco: Double) -> Unit,
    onAddInsumo: (insumo: Insumo, quantidade: Double) -> Unit,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var selectedInsumo by remember { mutableStateOf<Insumo?>(null) }
    var nomeItem by remember { mutableStateOf("") }
    var quantidade by remember { mutableStateOf("1") }
    var unidade by remember { mutableStateOf("un") }
    var preco by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current
    val searchFocus = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        kotlinx.coroutines.delay(100)
        searchFocus.requestFocus()
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        dragHandle = {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                BottomSheetDefaults.DragHandle()
                Text(
                    text = "Adicionar Item",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .navigationBarsPadding()
                .imePadding()
        ) {
            if (selectedInsumo == null) {
                // Campo de busca
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = { query ->
                        onSearchChanged(query)
                        nomeItem = query
                    },
                    label = { Text("Nome do item ou insumo") },
                    leadingIcon = {
                        if (isSearching) CircularProgressIndicator(modifier = Modifier.size(20.dp))
                        else Icon(Icons.Default.Search, contentDescription = null)
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { onSearchChanged(""); nomeItem = "" }) {
                                Icon(Icons.Default.Clear, contentDescription = "Limpar")
                            }
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .focusRequester(searchFocus),
                    keyboardOptions = KeyboardOptions(
                        capitalization = KeyboardCapitalization.Words,
                        imeAction = ImeAction.Search
                    ),
                    keyboardActions = KeyboardActions(
                        onSearch = { focusManager.clearFocus() }
                    ),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.primary
                    )
                )

                // Resultados da busca
                AnimatedVisibility(visible = searchResults.isNotEmpty()) {
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxWidth()
                            .heightIn(max = 200.dp)
                    ) {
                        items(searchResults) { insumo ->
                            InsumoSuggestionItem(
                                insumo = insumo,
                                onClick = {
                                    selectedInsumo = insumo
                                    nomeItem = insumo.nome
                                    unidade = insumo.unidadeCompra
                                    preco = if (insumo.custoAtual > 0) insumo.custoAtual.toString() else ""
                                }
                            )
                        }
                    }
                }

                // Separador "adicionar como item livre"
                if (searchQuery.isNotEmpty() && searchResults.isEmpty() && !isSearching) {
                    Row(
                        modifier = Modifier.padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        HorizontalDivider(modifier = Modifier.weight(1f))
                        Text(
                            text = "  Adicionar como item livre  ",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        HorizontalDivider(modifier = Modifier.weight(1f))
                    }
                }
            } else {
                // Insumo selecionado
                InsumoSelectedBanner(
                    insumo = selectedInsumo!!,
                    onClear = {
                        selectedInsumo = null
                        nomeItem = ""
                        preco = ""
                    }
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Campos de quantidade e unidade
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedTextField(
                    value = quantidade,
                    onValueChange = { quantidade = it },
                    label = { Text("Qtd") },
                    modifier = Modifier.weight(1f),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Next
                    ),
                    singleLine = true
                )

                if (selectedInsumo == null) {
                    OutlinedTextField(
                        value = unidade,
                        onValueChange = { unidade = it },
                        label = { Text("Unidade") },
                        modifier = Modifier.weight(1f),
                        keyboardOptions = KeyboardOptions(
                            capitalization = KeyboardCapitalization.None,
                            imeAction = ImeAction.Next
                        ),
                        singleLine = true
                    )
                } else {
                    Surface(
                        modifier = Modifier
                            .weight(1f)
                            .height(56.dp),
                        shape = MaterialTheme.shapes.extraSmall,
                        color = MaterialTheme.colorScheme.surfaceVariant
                    ) {
                        Box(contentAlignment = Alignment.Center) {
                            Text(
                                text = selectedInsumo!!.unidadeCompra,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.SemiBold,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                OutlinedTextField(
                    value = preco,
                    onValueChange = { preco = it },
                    label = { Text("R$ Preço") },
                    modifier = Modifier.weight(1.5f),
                    keyboardOptions = KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = { focusManager.clearFocus() }
                    ),
                    singleLine = true,
                    prefix = { Text("R$") }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Botão adicionar
            val isValid = (selectedInsumo != null || nomeItem.isNotBlank()) &&
                    quantidade.toDoubleOrNull() != null && quantidade.toDouble() > 0

            Button(
                onClick = {
                    val qtd = quantidade.toDoubleOrNull() ?: 1.0
                    val precoVal = preco.replace(",", ".").toDoubleOrNull() ?: 0.0

                    if (selectedInsumo != null) {
                        onAddInsumo(selectedInsumo!!, qtd)
                    } else {
                        onAddFreeItem(nomeItem, qtd, unidade, precoVal)
                    }
                },
                enabled = isValid,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Icon(Icons.Default.Add, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Adicionar à lista", fontWeight = FontWeight.SemiBold)
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun InsumoSuggestionItem(insumo: Insumo, onClick: () -> Unit) {
    ListItem(
        headlineContent = { Text(insumo.nome) },
        supportingContent = {
            Text(
                text = "${insumo.unidadeCompra} · R$ ${
                    String.format("%.2f", insumo.custoAtual)
                }",
                style = MaterialTheme.typography.bodySmall
            )
        },
        leadingContent = {
            Icon(
                imageVector = Icons.Outlined.ShoppingCart,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        },
        modifier = Modifier.clickable(onClick = onClick)
    )
    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
}

@Composable
private fun InsumoSelectedBanner(insumo: Insumo, onClear: () -> Unit) {
    Surface(
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.primaryContainer,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Outlined.ShoppingCart,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = insumo.nome,
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "Insumo cadastrado · ${insumo.unidadeCompra}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                )
            }
            IconButton(onClick = onClear, modifier = Modifier.size(32.dp)) {
                Icon(
                    Icons.Default.Close,
                    contentDescription = "Remover seleção",
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
    }
}
