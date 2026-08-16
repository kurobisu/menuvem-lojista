package br.com.menuvem.lojista.presentation.products

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Warning
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
import br.com.menuvem.lojista.domain.model.ItemFichaComInsumo
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.domain.model.ProdutoComponenteCompleto
import br.com.menuvem.lojista.presentation.components.EditarQuantidadeDialog
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.InsumoQuantidadeRow
import br.com.menuvem.lojista.presentation.components.descreverMultiplicador
import br.com.menuvem.lojista.presentation.components.divisorDeMultiplicador
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.presentation.components.formatarTipo
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProdutoDetailScreen(
    onBack: () -> Unit,
    onNavigateToComponentes: () -> Unit,
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
                            TextButton(onClick = viewModel::onShowAddComponenteSheet) {
                                Icon(
                                    Icons.Filled.Widgets,
                                    contentDescription = null,
                                    modifier = Modifier.size(16.dp)
                                )
                                Spacer(modifier = Modifier.width(4.dp))
                                Text("Componente", style = MaterialTheme.typography.labelMedium)
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

                if (uiState.componentes.isNotEmpty()) {
                    item {
                        Text(
                            text = "Componentes",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    items(uiState.componentes, key = { "comp_${it.vinculo.id}" }) { item ->
                        ComponenteNoProdutoCard(
                            item = item,
                            onClick = { viewModel.onEditComponente(item) },
                            onDelete = { viewModel.removeComponente(item.vinculo) }
                        )
                    }
                }

                if (uiState.itensFicha.isNotEmpty() || uiState.componentes.isNotEmpty()) {
                    item {
                        Text(
                            text = "Insumos",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                if (uiState.itensFicha.isEmpty() && uiState.componentes.isEmpty()) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.Receipt,
                            title = "Ficha técnica vazia",
                            subtitle = "Adicione componentes reutilizáveis ou insumos avulsos para calcular o custo por porção"
                        )
                    }
                } else {
                    items(uiState.itensFicha, key = { "item_${it.item.id}" }) { itemComInsumo ->
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

    if (uiState.showAddComponenteSheet) {
        AddComponenteSheet(
            componentes = uiState.todosComponentes,
            onAddComponente = viewModel::addComponente,
            onGerenciarComponentes = {
                viewModel.onHideAddComponenteSheet()
                onNavigateToComponentes()
            },
            onDismiss = viewModel::onHideAddComponenteSheet
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

    uiState.componenteEmEdicao?.let { completo ->
        SeletorDivisaoDialog(
            titulo = completo.componente.nome,
            divisorInicial = divisorDeMultiplicador(completo.vinculo.multiplicador),
            onDismiss = viewModel::onHideEditComponente,
            onConfirm = { multiplicador ->
                viewModel.updateMultiplicador(completo.vinculo, multiplicador)
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
                        "Substitui a ficha atual (componentes e insumos) pela ficha de:",
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
private fun ComponenteNoProdutoCard(
    item: ProdutoComponenteCompleto,
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
            Icon(
                imageVector = Icons.Filled.Widgets,
                contentDescription = null,
                tint = PurplePrimary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.componente.nome,
                    style = MaterialTheme.typography.titleSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(2.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(shape = RoundedCornerShape(50), color = PurpleContainer) {
                        Text(
                            text = formatarTipo(item.componente.tipo),
                            style = MaterialTheme.typography.labelSmall,
                            color = PurpleOnContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "${item.quantidadeItens} insumo(s) · ${descreverMultiplicador(item.vinculo.multiplicador)}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "R$ ${formatarMoeda(item.custo)}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "custo no produto",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Remover componente",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}