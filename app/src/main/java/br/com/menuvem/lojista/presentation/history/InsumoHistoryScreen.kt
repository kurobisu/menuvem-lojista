package br.com.menuvem.lojista.presentation.history

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Insights
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.GraficoPreco
import br.com.menuvem.lojista.presentation.components.TendenciaIndicador
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.PurplePrimary
import br.com.menuvem.lojista.ui.theme.YellowSecondary
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsumoHistoryScreen(
    insumoId: Long,
    onBack: () -> Unit,
    viewModel: InsumoHistoryViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = uiState.insumo?.nome ?: "Histórico",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        uiState.insumo?.let {
                            Text(
                                text = "por ${it.unidadeCompra}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Voltar")
                    }
                },
                actions = {
                    TendenciaIndicador(
                        tendencia = uiState.tendencia,
                        showLabel = true,
                        modifier = Modifier.padding(end = 16.dp)
                    )
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
                contentPadding = PaddingValues(bottom = 24.dp)
            ) {
                // Card de resumo
                item {
                    uiState.insumo?.let { insumo ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Row(
                                modifier = Modifier.padding(16.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(
                                        text = "Custo atual",
                                        style = MaterialTheme.typography.labelMedium,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                    )
                                    Text(
                                        text = "R$ ${formatarMoeda(insumo.custoAtual)}",
                                        style = MaterialTheme.typography.headlineMedium,
                                        fontWeight = FontWeight.Bold,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    Text(
                                        text = "por ${insumo.unidadeCompra}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                    )
                                }
                                Column(horizontalAlignment = Alignment.End) {
                                    Text(
                                        text = "${uiState.historico.size} compras",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                    )
                                    Text(
                                        text = "R$ ${formatarMoeda(insumo.custoPorUnidadeUso)}/${insumo.unidadeUso}",
                                        style = MaterialTheme.typography.labelMedium,
                                        fontWeight = FontWeight.SemiBold,
                                        color = YellowSecondary
                                    )
                                }
                            }
                        }
                    }
                }

                // Gráfico
                if (uiState.historico.size >= 2) {
                    item {
                        Text(
                            text = "Evolução do preço",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                        ElevatedCard(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp),
                            elevation = CardDefaults.elevatedCardElevation(2.dp)
                        ) {
                            GraficoPreco(
                                historico = uiState.historico,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 16.dp, bottom = 8.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }

                // Histório textual
                item {
                    Text(
                        text = "Histórico de compras",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )
                }

                if (uiState.historico.isEmpty()) {
                    item {
                        EmptyState(
                            icon = Icons.Outlined.Insights,
                            title = "Sem registros",
                            subtitle = "Este insumo não tem histórico de preços. Finalize uma lista de compras com ele para começar a registrar."
                        )
                    }
                } else {
                    items(uiState.historico.reversed()) { historico ->
                        HistoricoItem(historico = historico)
                    }
                }
            }
        }
    }
}

@Composable
private fun HistoricoItem(historico: HistoricoPreco) {
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm")

    ListItem(
        headlineContent = {
            Text(
                text = "R$ ${formatarMoeda(historico.preco)}",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
        },
        supportingContent = {
            Column {
                Text(
                    text = historico.data.format(formatter),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                if (historico.listaComprasNome.isNotBlank()) {
                    Text(
                        text = historico.listaComprasNome,
                        style = MaterialTheme.typography.bodySmall,
                        color = PurplePrimary.copy(alpha = 0.8f)
                    )
                }
            }
        },
        leadingContent = {
            Icon(
                imageVector = Icons.Default.Receipt,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(20.dp)
            )
        }
    )
    HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
}
