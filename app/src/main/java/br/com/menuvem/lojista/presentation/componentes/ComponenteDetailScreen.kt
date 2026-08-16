package br.com.menuvem.lojista.presentation.componentes

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material.icons.outlined.Receipt
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.presentation.components.EditarQuantidadeDialog
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.InsumoQuantidadeRow
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.presentation.products.AddFichaItemBottomSheet
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComponenteDetailScreen(
    onBack: () -> Unit,
    viewModel: ComponenteDetailViewModel = hiltViewModel()
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
                        text = uiState.componente?.componente?.nome ?: "Componente",
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
                    IconButton(onClick = viewModel::onShowRenameDialog) {
                        Icon(Icons.Default.Edit, contentDescription = "Editar componente")
                    }
                    IconButton(onClick = viewModel::onShowDeleteDialog) {
                        Icon(
                            Icons.Default.Delete,
                            contentDescription = "Excluir componente",
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
                    uiState.componente?.let { ResumoComponenteCard(it) }
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
                            text = "Insumos",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold
                        )
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

                val itens = uiState.componente?.itens.orEmpty()
                if (itens.isEmpty()) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.Receipt,
                            title = "Componente sem insumos",
                            subtitle = "Adicione os insumos deste bloco. Ele será aplicado inteiro (ou fracionado) nos produtos"
                        )
                    }
                } else {
                    items(itens, key = { it.item.id }) { itemComInsumo ->
                        InsumoQuantidadeRow(
                            nome = itemComInsumo.insumo.nome,
                            quantidade = itemComInsumo.item.quantidade,
                            unidade = itemComInsumo.insumo.unidadeUso,
                            perdaPercentual = itemComInsumo.item.perdaPercentual,
                            custo = itemComInsumo.custo,
                            onClick = { viewModel.onEditItem(itemComInsumo) },
                            onDelete = { viewModel.removeItem(itemComInsumo.item) }
                        )
                    }
                }
            }
        }
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
        EditarQuantidadeDialog(
            titulo = itemComInsumo.insumo.nome,
            unidadeUso = itemComInsumo.insumo.unidadeUso,
            quantidadeInicial = itemComInsumo.item.quantidade,
            perdaInicial = itemComInsumo.item.perdaPercentual,
            onDismiss = viewModel::onHideEditItem,
            onConfirm = { quantidade, perda ->
                viewModel.updateItem(itemComInsumo.item, quantidade, perda)
            }
        )
    }

    if (uiState.showRenameDialog) {
        ComponenteFormDialog(
            componente = uiState.componenteModel,
            onDismiss = viewModel::onHideRenameDialog,
            onConfirm = viewModel::updateComponente
        )
    }

    if (uiState.showDeleteDialog) {
        AlertDialog(
            onDismissRequest = viewModel::onHideDeleteDialog,
            title = { Text("Excluir componente?") },
            text = {
                Text("O componente será removido dos produtos que o utilizam. Esta ação não pode ser desfeita.")
            },
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
private fun ResumoComponenteCard(item: br.com.menuvem.lojista.domain.model.ComponenteComCusto) {
    ElevatedCard(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    Icons.Filled.Widgets,
                    contentDescription = null,
                    tint = PurplePrimary,
                    modifier = Modifier.size(28.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = item.componente.nome,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Text(
                        text = "${item.quantidadeItens} insumo(s) por inteiro",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "R$ ${formatarMoeda(item.custo)}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = PurplePrimary
                    )
                    Text(
                        text = "custo inteiro",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}