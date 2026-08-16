package br.com.menuvem.lojista.presentation.componentes

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Widgets
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.ComponenteComCusto
import br.com.menuvem.lojista.domain.model.TipoComponente
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.presentation.components.formatarTipo
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComponentesScreen(
    onNavigateToComponente: (Long) -> Unit,
    onBack: () -> Unit,
    viewModel: ComponentesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("Componentes") },
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
                onClick = { viewModel.onShowForm() },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("Novo Componente") },
                containerColor = YellowSecondary,
                contentColor = MaterialTheme.colorScheme.surface
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = uiState.filtroTipo == null,
                    onClick = { viewModel.onFiltroChange(null) },
                    label = { Text("Todos") }
                )
                TipoComponente.entries.forEach { tipo ->
                    FilterChip(
                        selected = uiState.filtroTipo == tipo,
                        onClick = { viewModel.onFiltroChange(tipo) },
                        label = { Text(formatarTipo(tipo)) }
                    )
                }
            }

            when {
                uiState.isLoading -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) { CircularProgressIndicator(color = PurplePrimary) }

                uiState.componentesFiltrados.isEmpty() -> EmptyState(
                    icon = Icons.Filled.Widgets,
                    title = "Nenhum componente cadastrado",
                    subtitle = "Componentes são blocos reutilizáveis (massa, sabor, embalagem) que você aplica em vários produtos"
                )

                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = 16.dp, top = 4.dp, end = 16.dp, bottom = 88.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.componentesFiltrados, key = { it.componente.id }) { item ->
                        ComponenteRow(
                            item = item,
                            onClick = { onNavigateToComponente(item.componente.id) },
                            onDelete = { viewModel.onShowDeleteConfirm(item) }
                        )
                    }
                }
            }
        }
    }

    if (uiState.showFormDialog) {
        ComponenteFormDialog(
            componente = uiState.componenteEmEdicao,
            onDismiss = viewModel::onHideForm,
            onConfirm = viewModel::save
        )
    }

    uiState.componenteParaExcluir?.let { item ->
        AlertDialog(
            onDismissRequest = viewModel::onHideDeleteConfirm,
            title = { Text("Excluir componente?") },
            text = {
                Text("\"${item.componente.nome}\" e seus itens serão excluídos. Ele também será removido dos produtos que o utilizam.")
            },
            confirmButton = {
                TextButton(onClick = viewModel::delete) {
                    Text("Excluir", color = ErrorRed)
                }
            },
            dismissButton = {
                TextButton(onClick = viewModel::onHideDeleteConfirm) { Text("Cancelar") }
            }
        )
    }
}

@Composable
private fun ComponenteRow(
    item: ComponenteComCusto,
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
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = item.componente.nome,
                        style = MaterialTheme.typography.titleSmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Surface(shape = RoundedCornerShape(50), color = PurpleContainer) {
                        Text(
                            text = formatarTipo(item.componente.tipo),
                            style = MaterialTheme.typography.labelSmall,
                            color = PurpleOnContainer,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                        )
                    }
                }
                Text(
                    text = if (item.quantidadeItens == 0) "Sem insumos"
                    else "${item.quantidadeItens} insumo(s) por inteiro",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "R$ ${formatarMoeda(item.custo)}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "custo inteiro",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Excluir componente",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}