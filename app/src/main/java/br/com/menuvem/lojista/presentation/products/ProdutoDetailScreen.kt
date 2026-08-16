package br.com.menuvem.lojista.presentation.products

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.Receipt
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProdutoDetailScreen(
    onBack: () -> Unit,
    viewModel: ProdutoDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(uiState.deleted) {
        if (uiState.deleted) onBack()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = uiState.produtoComCusto?.produto?.nome ?: "Produto",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Voltar"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = viewModel::onShowEditDialog) {
                        Icon(Icons.Default.Edit, contentDescription = "Editar produto")
                    }
                    IconButton(onClick = viewModel::onShowDeleteDialog) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "Excluir produto",
                            tint = ErrorRed
                        )
                    }
                }
            )
        }
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) { CircularProgressIndicator(color = PurplePrimary) }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(
                    start = 16.dp, top = 8.dp, end = 16.dp, bottom = 32.dp
                ),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    uiState.produtoComCusto?.let { ResumoCustoCard(it) }
                }

                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "Ficha Técnica",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
                        Row {
                            TextButton(
                                onClick = viewModel::onShowDuplicateDialog,
                                enabled = uiState.outrosProdutos.isNotEmpty()
                            ) {
                                Icon(
                                    Icons.Default.ContentCopy,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Copiar ficha", style = MaterialTheme.typography.labelMedium)
                            }
                            TextButton(onClick = viewModel::onShowAddSheet) {
                                Icon(
                                    Icons.Default.Add,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Insumo", style = MaterialTheme.typography.labelMedium)
                            }
                        }
                    }
                }

                if (uiState.itensFicha.isEmpty()) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.Receipt,
                            title = "Ficha técnica vazia",
                            subtitle = "Adicione os insumos que compõem este produto para calcular o custo por porção"
                        )
                    }
                } else {
                    items(uiState.itensFicha, key = { it.item.id }) { itemComInsumo ->
                        FichaItemRow(
                            item = itemComInsumo,
                            onClick = { viewModel.onEditItem(itemComInsumo) },
                            onDelete = { viewModel.removeItem(itemComInsumo.item) }
                        )
                    }
                }
            }
        }
    }

    // ── Dialogs ──────────────────────────────────────────────────────────────

    if (uiState.showEditDialog) {
        ProdutoFormDialog(
            produto = uiState.produtoComCusto?.produto,
            onDismiss = viewModel::onHideEditDialog,
            onConfirm = viewModel::updateProduto
        )
    }

    if (uiState.showAddSheet) {
        AddFichaItemBottomSheet(
            searchQuery = uiState.searchQuery,
            searchResults = uiState.searchResults,
            isSearching = uiState.isSearching,
            onSearchChanged = viewModel::onSearchQueryChanged,
            onAddItem = viewModel::addItem,
            onDismiss = viewModel::onHideAddSheet
        )
    }

    uiState.itemEmEdicao?.let { itemComInsumo ->
        EditFichaItemDialog(
            item = itemComInsumo,
            onDismiss = viewModel::onHideEditItem,
            onConfirm = { quantidade, perda ->
                viewModel.updateItem(itemComInsumo.item, quantidade, perda)
            }
        )
    }

    if (uiState.showDuplicateDialog) {
        AlertDialog(
            onDismissRequest = viewModel::onHideDuplicateDialog,
            title = { Text("Copiar ficha técnica") },
            text = {
                Column {
                    Text(
                        "Substitui a ficha atual pela ficha de:",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    uiState.outrosProdutos.forEach { outro ->
                        TextButton(
                            onClick = { viewModel.duplicateFrom(outro.id) },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(outro.nome, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = viewModel::onHideDuplicateDialog) { Text("Cancelar") }
            }
        )
    }

    if (uiState.showDeleteDialog) {
        AlertDialog(
            onDismissRequest = viewModel::onHideDeleteDialog,
            title = { Text("Excluir produto?") },
            text = { Text("A ficha técnica também será excluída. Esta ação não pode ser desfeita.") },
            confirmButton = {
                TextButton(onClick = viewModel::delete) {
                    Text("Excluir", color = ErrorRed)
                }
            },
            dismissButton = {
                TextButton(onClick = viewModel::onHideDeleteDialog) { Text("Cancelar") }
            }
        )
    }
}

@Composable
private fun ResumoCustoCard(item: ProdutoComCusto) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Custo por porção",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "R$ ${formatarMoeda(item.custoTotal)}",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Preço sugerido",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "R$ ${formatarMoeda(item.precoSugerido)}",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = PurplePrimary
                    )
                    Text(
                        text = "margem ${String.format("%.1f%%", item.produto.margemAlvoPercentual)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            item.produto.precoVendaAtual?.let { preco ->
                Spacer(modifier = Modifier.height(12.dp))
                HorizontalDivider()
                Spacer(modifier = Modifier.height(12.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Preço praticado: R$ ${formatarMoeda(preco)}",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    item.margemRealPercentual?.let { margemReal ->
                        Surface(
                            shape = RoundedCornerShape(50),
                            color = if (item.margemAbaixoDaMeta) WarningContainer else SuccessContainer
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                            ) {
                                if (item.margemAbaixoDaMeta) {
                                    Icon(
                                        imageVector = Icons.Default.Warning,
                                        contentDescription = null,
                                        tint = WarningOrange,
                                        modifier = Modifier.size(14.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                }
                                Text(
                                    text = "Margem ${String.format("%.1f%%", margemReal)}",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = if (item.margemAbaixoDaMeta) WarningOrange else SuccessGreen
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun FichaItemRow(
    item: ItemFichaComInsumo,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.insumo.nome,
                    style = MaterialTheme.typography.titleSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                val perdaTexto = if (item.item.perdaPercentual > 0)
                    " · perda ${String.format("%.0f%%", item.item.perdaPercentual)}" else ""
                Text(
                    text = "${formatarQuantidade(item.item.quantidade)} ${item.insumo.unidadeUso}$perdaTexto",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Text(
                text = "R$ ${formatarMoeda(item.custo)}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Remover item",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun EditFichaItemDialog(
    item: ItemFichaComInsumo,
    onDismiss: () -> Unit,
    onConfirm: (quantidade: Double, perda: Double) -> Unit
) {
    var quantidade by remember {
        mutableStateOf(formatarQuantidade(item.item.quantidade).replace('.', ','))
    }
    var perda by remember {
        mutableStateOf(
            if (item.item.perdaPercentual % 1.0 == 0.0) item.item.perdaPercentual.toInt().toString()
            else item.item.perdaPercentual.toString().replace('.', ',')
        )
    }

    val quantidadeVal = quantidade.replace(",", ".").toDoubleOrNull()
    val perdaVal = perda.replace(",", ".").toDoubleOrNull()
    val isValid = quantidadeVal != null && quantidadeVal > 0 &&
            perdaVal != null && perdaVal in 0.0..99.9

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(item.insumo.nome, maxLines = 1, overflow = TextOverflow.Ellipsis) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(
                    value = quantidade,
                    onValueChange = { quantidade = it },
                    label = { Text("Quantidade (${item.insumo.unidadeUso})") },
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

private fun formatarQuantidade(valor: Double): String =
    if (valor % 1.0 == 0.0) valor.toInt().toString() else String.format("%.2f", valor)
