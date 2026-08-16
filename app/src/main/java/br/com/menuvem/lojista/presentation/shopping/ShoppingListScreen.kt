package br.com.menuvem.lojista.presentation.shopping

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.StatusLista
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.ItemListaCard
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.PurplePrimary
import br.com.menuvem.lojista.ui.theme.SuccessGreen
import br.com.menuvem.lojista.ui.theme.YellowSecondary
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShoppingListScreen(
    listaId: Long,
    onBack: () -> Unit,
    viewModel: ShoppingListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(uiState.finishedSuccess) {
        if (uiState.finishedSuccess) {
            snackbarHostState.showSnackbar("Compra finalizada! Custos atualizados.")
            viewModel.clearSuccess()
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
        }
    }

    val lista = uiState.lista
    val isFinalized = lista?.status == StatusLista.FINALIZADA

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            Column {
                // Cabeçalho com gradiente
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(PurplePrimary, PurplePrimary.copy(alpha = 0.85f))
                            )
                        )
                        .statusBarsPadding()
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            IconButton(onClick = onBack) {
                                Icon(
                                    Icons.Default.ArrowBack,
                                    contentDescription = "Voltar",
                                    tint = Color.White
                                )
                            }
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = lista?.nome ?: "Lista de Compras",
                                    style = MaterialTheme.typography.titleLarge,
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                lista?.dataCriacao?.let { data ->
                                    Text(
                                        text = data.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = Color.White.copy(alpha = 0.75f)
                                    )
                                }
                            }
                            if (isFinalized) {
                                Surface(
                                    shape = MaterialTheme.shapes.small,
                                    color = SuccessGreen.copy(alpha = 0.25f)
                                ) {
                                    Row(
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                                    ) {
                                        Icon(
                                            Icons.Default.CheckCircle,
                                            contentDescription = null,
                                            tint = Color.White,
                                            modifier = Modifier.size(14.dp)
                                        )
                                        Text(
                                            text = "Finalizada",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = Color.White
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        // Barra de progresso e totais
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.Bottom
                        ) {
                            Column {
                                Text(
                                    text = "${uiState.itensComprados} de ${uiState.totalItens} itens",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.White.copy(alpha = 0.8f)
                                )
                                Text(
                                    text = "R$ ${formatarMoeda(uiState.totalGasto)}",
                                    style = MaterialTheme.typography.headlineSmall,
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            if (uiState.totalItens > 0) {
                                val progress = uiState.itensComprados.toFloat() / uiState.totalItens
                                CircularProgressIndicator(
                                    progress = { progress },
                                    color = Color.White,
                                    trackColor = Color.White.copy(alpha = 0.3f),
                                    modifier = Modifier.size(48.dp),
                                    strokeWidth = 4.dp
                                )
                            }
                        }

                        if (uiState.totalItens > 0) {
                            Spacer(modifier = Modifier.height(8.dp))
                            LinearProgressIndicator(
                                progress = {
                                    if (uiState.totalItens > 0)
                                        uiState.itensComprados.toFloat() / uiState.totalItens
                                    else 0f
                                },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(4.dp),
                                color = Color.White,
                                trackColor = Color.White.copy(alpha = 0.3f)
                            )
                        }
                    }
                }
            }
        },
        floatingActionButton = {
            if (!isFinalized) {
                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // FAB Finalizar (apenas se há itens comprados)
                    if (uiState.itensComprados > 0) {
                        FloatingActionButton(
                            onClick = viewModel::onShowFinishDialog,
                            containerColor = SuccessGreen,
                            contentColor = Color.White,
                            modifier = Modifier.size(48.dp)
                        ) {
                            Icon(Icons.Default.Done, contentDescription = "Finalizar compra")
                        }
                    }
                    // FAB Adicionar
                    FloatingActionButton(
                        onClick = viewModel::onShowAddSheet,
                        containerColor = YellowSecondary,
                        contentColor = Color.White
                    ) {
                        Icon(Icons.Default.Add, contentDescription = "Adicionar item")
                    }
                }
            }
        }
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) { CircularProgressIndicator(color = PurplePrimary) }
        } else if (uiState.itens.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                EmptyState(
                    icon = Icons.Outlined.ShoppingCart,
                    title = "Lista vazia",
                    subtitle = "Toque em + para adicionar os primeiros itens"
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(
                    start = 12.dp, end = 12.dp,
                    top = 8.dp, bottom = 100.dp
                ),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                // Itens pendentes
                val pendentes = uiState.itens.filter { !it.comprado }
                val comprados = uiState.itens.filter { it.comprado }

                if (pendentes.isNotEmpty()) {
                    item {
                        Text(
                            text = "A comprar (${pendentes.size})",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 4.dp, horizontal = 4.dp)
                        )
                    }
                    items(pendentes, key = { it.id }) { item ->
                        ItemListaCard(
                            item = item,
                            tendencia = item.insumoId?.let { uiState.tendencias[it] },
                            onToggle = { checked, preco -> viewModel.toggleItem(item.id, checked, preco) },
                            onDelete = { viewModel.deleteItem(item) }
                        )
                    }
                }

                if (comprados.isNotEmpty()) {
                    item {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Comprados (${comprados.size})",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.padding(vertical = 4.dp, horizontal = 4.dp)
                        )
                    }
                    items(comprados, key = { it.id }) { item ->
                        ItemListaCard(
                            item = item,
                            tendencia = item.insumoId?.let { uiState.tendencias[it] },
                            onToggle = { checked, preco -> viewModel.toggleItem(item.id, checked, preco) },
                            onDelete = { viewModel.deleteItem(item) }
                        )
                    }
                }
            }
        }

        // Bottom Sheet
        if (uiState.showAddSheet) {
            AddItemBottomSheet(
                searchQuery = uiState.searchQuery,
                searchResults = uiState.searchResults,
                isSearching = uiState.isSearching,
                onSearchChanged = viewModel::onSearchQueryChanged,
                onAddFreeItem = { nome, qtd, unidade, preco ->
                    viewModel.addItem(nome, qtd, unidade, preco)
                },
                onAddInsumo = { insumo, qtd ->
                    viewModel.addItem(
                        nomeItem = insumo.nome,
                        quantidade = qtd,
                        unidade = insumo.unidadeCompra,
                        precoUnitario = insumo.custoAtual,
                        insumo = insumo
                    )
                },
                onDismiss = viewModel::onHideAddSheet
            )
        }

        // Dialog de confirmação
        if (uiState.showFinishDialog) {
            AlertDialog(
                onDismissRequest = viewModel::onDismissFinishDialog,
                icon = { Icon(Icons.Default.ShoppingBag, contentDescription = null) },
                title = { Text("Finalizar compra?") },
                text = {
                    Text(
                        "Os preços dos ${uiState.itensComprados} itens comprados serão " +
                        "registrados e os insumos vinculados terão seus custos atualizados automaticamente."
                    )
                },
                confirmButton = {
                    Button(
                        onClick = viewModel::finalizarCompra,
                        colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen)
                    ) {
                        if (uiState.isFinishing) {
                            CircularProgressIndicator(
                                color = Color.White,
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp
                            )
                        } else {
                            Text("Finalizar")
                        }
                    }
                },
                dismissButton = {
                    TextButton(onClick = viewModel::onDismissFinishDialog) {
                        Text("Cancelar")
                    }
                }
            )
        }
    }
}
