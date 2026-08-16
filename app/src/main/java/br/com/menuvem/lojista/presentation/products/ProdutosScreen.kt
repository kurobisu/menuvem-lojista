package br.com.menuvem.lojista.presentation.products

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.outlined.Restaurant
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.ProdutoComCusto
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProdutosScreen(
    onNavigateToProduto: (Long) -> Unit,
    onBack: () -> Unit,
    viewModel: ProdutosViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Produtos") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Voltar"
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = viewModel::onShowForm,
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("Novo Produto") },
                containerColor = YellowSecondary,
                contentColor = MaterialTheme.colorScheme.surface
            )
        }
    ) { paddingValues ->
        when {
            uiState.isLoading -> Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) { CircularProgressIndicator(color = PurplePrimary) }

            uiState.produtos.isEmpty() -> Box(modifier = Modifier.padding(paddingValues)) {
                EmptyState(
                    icon = Icons.Outlined.Restaurant,
                    title = "Nenhum produto cadastrado",
                    subtitle = "Cadastre um produto e monte a ficha técnica para calcular o custo e o preço ideal"
                )
            }

            else -> LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(
                    start = 16.dp, top = 8.dp, end = 16.dp, bottom = 88.dp
                ),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.produtos, key = { it.produto.id }) { item ->
                    ProdutoCard(
                        item = item,
                        onClick = { onNavigateToProduto(item.produto.id) }
                    )
                }
            }
        }
    }

    if (uiState.showFormDialog) {
        ProdutoFormDialog(
            onDismiss = viewModel::onHideForm,
            onConfirm = { nome, margem, preco ->
                viewModel.createProduto(nome, margem, preco, onCreated = onNavigateToProduto)
            }
        )
    }
}

@Composable
private fun ProdutoCard(item: ProdutoComCusto, onClick: () -> Unit) {
    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = item.produto.nome,
                        style = MaterialTheme.typography.titleSmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = if (item.quantidadeItens == 0) "Ficha técnica vazia"
                        else "${item.quantidadeItens} insumo(s) na ficha",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (item.margemAbaixoDaMeta) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = "Margem abaixo da meta",
                        tint = WarningOrange,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "Custo R$ ${formatarMoeda(item.custoTotal)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "R$ ${formatarMoeda(item.precoSugerido)}",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = PurplePrimary
                    )
                    Text(
                        text = "preço sugerido",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                MargemChip(
                    label = "Meta ${formatarPercentual(item.produto.margemAlvoPercentual)}",
                    container = PurpleContainer,
                    content = PurpleOnContainer
                )
                val margemReal = item.margemRealPercentual
                if (margemReal != null) {
                    MargemChip(
                        label = "Atual ${formatarPercentual(margemReal)}",
                        container = if (item.margemAbaixoDaMeta) WarningContainer else SuccessContainer,
                        content = if (item.margemAbaixoDaMeta) WarningOrange else SuccessGreen
                    )
                } else {
                    MargemChip(
                        label = "Sem preço de venda",
                        container = MaterialTheme.colorScheme.surfaceVariant,
                        content = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun MargemChip(label: String, container: androidx.compose.ui.graphics.Color, content: androidx.compose.ui.graphics.Color) {
    Surface(shape = RoundedCornerShape(50), color = container) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = content,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
        )
    }
}

private fun formatarPercentual(valor: Double): String =
    String.format("%.1f%%", valor)
