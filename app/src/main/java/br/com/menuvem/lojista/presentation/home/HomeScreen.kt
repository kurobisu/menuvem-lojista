package br.com.menuvem.lojista.presentation.home

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.model.StatusLista
import br.com.menuvem.lojista.domain.model.TendenciaPreco
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.TendenciaIndicador
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.*
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onNavigateToListas: () -> Unit,
    onNavigateToLista: (Long) -> Unit,
    onNavigateToHistorico: () -> Unit,
    onNavigateToInsumoHistory: (Long) -> Unit,
    onNavigateToProdutos: () -> Unit,
    onNavigateToProduto: (Long) -> Unit,
    onNavigateToInsumos: () -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var visible by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { visible = true }

    Scaffold(
        topBar = {
            // Header com gradiente roxo
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(PurplePrimary, PurpleLight)
                        )
                    )
                    .statusBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 20.dp)
            ) {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Column {
                            Text(
                                text = "Menuvem",
                                style = MaterialTheme.typography.labelMedium,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                            Text(
                                text = "Lojista",
                                style = MaterialTheme.typography.headlineMedium,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Row {
                            IconButton(
                                onClick = onNavigateToHistorico,
                            ) {
                                Icon(
                                    imageVector = Icons.Default.TrendingUp,
                                    contentDescription = "Histórico de preços",
                                    tint = Color.White
                                )
                            }
                            IconButton(
                                onClick = viewModel::signOut,
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ExitToApp,
                                    contentDescription = "Sair",
                                    tint = Color.White
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Card de resumo da última lista
                    uiState.ultimaLista?.let { lista ->
                        UltimaListaCard(
                            lista = lista,
                            onClick = { onNavigateToLista(lista.id) }
                        )
                    }
                }
            }
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = onNavigateToListas,
                icon = {
                    Icon(Icons.Default.Add, contentDescription = null)
                },
                text = { Text("Nova Lista") },
                containerColor = YellowSecondary,
                contentColor = Color.White
            )
        }
    ) { paddingValues ->
        AnimatedVisibility(
            visible = visible,
            enter = fadeIn() + slideInVertically { it / 4 }
        ) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(bottom = 88.dp)
            ) {
                // Seção: Precificação (atalhos)
                item {
                    SectionHeader(title = "Precificação")
                }
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        PrecificacaoCard(
                            titulo = "Produtos",
                            subtitulo = "Fichas técnicas e preços",
                            icon = Icons.Outlined.Restaurant,
                            onClick = onNavigateToProdutos,
                            modifier = Modifier.weight(1f)
                        )
                        PrecificacaoCard(
                            titulo = "Insumos",
                            subtitulo = "Biblioteca e custos",
                            icon = Icons.Outlined.Inventory2,
                            onClick = onNavigateToInsumos,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                // Seção: Alertas de margem (só aparece quando há produtos abaixo da meta)
                if (uiState.produtosAbaixoDaMeta.isNotEmpty()) {
                    item {
                        SectionHeader(title = "Alertas de Margem")
                    }
                    items(uiState.produtosAbaixoDaMeta) { produtoComCusto ->
                        AlertaMargemRow(
                            item = produtoComCusto,
                            onClick = { onNavigateToProduto(produtoComCusto.produto.id) },
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                }

                // Seção: Listas recentes
                item {
                    SectionHeader(
                        title = "Listas Recentes",
                        action = "Ver todas",
                        onAction = onNavigateToListas
                    )
                }

                if (uiState.isLoading) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(32.dp),
                            contentAlignment = Alignment.Center
                        ) { CircularProgressIndicator(color = PurplePrimary) }
                    }
                } else if (uiState.todasListas.isEmpty()) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.ShoppingCart,
                            title = "Nenhuma lista ainda",
                            subtitle = "Crie sua primeira lista de compras tocando no botão +"
                        )
                    }
                } else {
                    item {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = 16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            items(uiState.todasListas.take(5)) { lista ->
                                ListaResumoCard(
                                    lista = lista,
                                    onClick = { onNavigateToLista(lista.id) }
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }

                // Seção: Tendências
                item {
                    SectionHeader(
                        title = "Variação de Preços",
                        action = "Histórico completo",
                        onAction = onNavigateToHistorico
                    )
                }

                if (uiState.insumosComTendencia.isEmpty() && !uiState.isLoading) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.Insights,
                            title = "Sem dados de variação",
                            subtitle = "Finalize listas de compras para ver tendências de preço"
                        )
                    }
                } else {
                    items(uiState.insumosComTendencia.sortedByDescending {
                        it.tendencia == TendenciaPreco.ALTA
                    }) { item ->
                        InsumoTendenciaRow(
                            item = item,
                            onClick = { onNavigateToInsumoHistory(item.insumo.id) },
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun UltimaListaCard(lista: ListaCompras, onClick: () -> Unit) {
    val formatter = DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .clickable(onClick = onClick),
        color = Color.White.copy(alpha = 0.15f),
        shape = RoundedCornerShape(16.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.ShoppingBag,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = lista.nome,
                    style = MaterialTheme.typography.titleSmall,
                    color = Color.White,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = lista.dataCriacao.format(formatter),
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.75f)
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                if (lista.totalGasto > 0) {
                    Text(
                        text = "R$ ${formatarMoeda(lista.totalGasto)}",
                        style = MaterialTheme.typography.titleMedium,
                        color = YellowLight,
                        fontWeight = FontWeight.Bold
                    )
                }
                Surface(
                    shape = RoundedCornerShape(50),
                    color = if (lista.status == StatusLista.ABERTA)
                        YellowContainer.copy(alpha = 0.3f)
                    else
                        SuccessContainer.copy(alpha = 0.3f)
                ) {
                    Text(
                        text = if (lista.status == StatusLista.ABERTA) "Aberta" else "Finalizada",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun ListaResumoCard(lista: ListaCompras, onClick: () -> Unit) {
    val formatter = DateTimeFormatter.ofPattern("dd/MM")
    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.width(160.dp),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Icon(
                imageVector = if (lista.status == StatusLista.FINALIZADA)
                    Icons.Default.CheckCircle else Icons.Default.ShoppingCart,
                contentDescription = null,
                tint = if (lista.status == StatusLista.FINALIZADA)
                    SuccessGreen else PurplePrimary,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = lista.nome,
                style = MaterialTheme.typography.titleSmall,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = lista.dataCriacao.format(formatter),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            if (lista.totalGasto > 0) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "R$ ${formatarMoeda(lista.totalGasto)}",
                    style = MaterialTheme.typography.labelMedium,
                    color = PurplePrimary,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun InsumoTendenciaRow(
    item: InsumoComTendencia,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ElevatedCard(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
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
                Text(
                    text = "por ${item.insumo.unidadeCompra}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "R$ ${formatarMoeda(item.ultimoPreco)}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Spacer(modifier = Modifier.height(2.dp))
                TendenciaIndicador(tendencia = item.tendencia, showLabel = true)
            }
        }
    }
}

@Composable
private fun PrecificacaoCard(
    titulo: String,
    subtitulo: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ElevatedCard(
        onClick = onClick,
        modifier = modifier,
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = PurplePrimary,
                modifier = Modifier.size(28.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = titulo,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitulo,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun AlertaMargemRow(
    item: br.com.menuvem.lojista.domain.model.ProdutoComCusto,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    ElevatedCard(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Filled.Warning,
                contentDescription = null,
                tint = WarningOrange,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.produto.nome,
                    style = MaterialTheme.typography.titleSmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "Margem ${String.format("%.1f%%", item.margemRealPercentual ?: 0.0)} · meta ${String.format("%.1f%%", item.produto.margemAlvoPercentual)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "R$ ${formatarMoeda(item.precoSugerido)}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = PurplePrimary
                )
                Text(
                    text = "preço sugerido",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun SectionHeader(
    title: String,
    action: String? = null,
    onAction: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold
        )
        if (action != null && onAction != null) {
            TextButton(onClick = onAction) {
                Text(
                    text = action,
                    style = MaterialTheme.typography.labelMedium,
                    color = PurplePrimary
                )
            }
        }
    }
}
