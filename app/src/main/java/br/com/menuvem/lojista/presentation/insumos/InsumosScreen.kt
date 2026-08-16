package br.com.menuvem.lojista.presentation.insumos

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import br.com.menuvem.lojista.domain.model.CategoriaInsumo
import br.com.menuvem.lojista.domain.model.Insumo
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun InsumosScreen(
    onBack: () -> Unit,
    viewModel: InsumosViewModel = hiltViewModel()
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
                title = { Text("Biblioteca de Insumos") },
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
                text = { Text("Novo Insumo") },
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
                    selected = uiState.filtroCategoria == null,
                    onClick = { viewModel.onFiltroChange(null) },
                    label = { Text("Todos") }
                )
                FilterChip(
                    selected = uiState.filtroCategoria == CategoriaInsumo.INSUMO,
                    onClick = { viewModel.onFiltroChange(CategoriaInsumo.INSUMO) },
                    label = { Text("Insumos") }
                )
                FilterChip(
                    selected = uiState.filtroCategoria == CategoriaInsumo.EMBALAGEM,
                    onClick = { viewModel.onFiltroChange(CategoriaInsumo.EMBALAGEM) },
                    label = { Text("Embalagens") }
                )
            }

            when {
                uiState.isLoading -> Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) { CircularProgressIndicator(color = PurplePrimary) }

                uiState.insumosFiltrados.isEmpty() -> EmptyState(
                    icon = Icons.Outlined.Inventory2,
                    title = "Nenhum insumo cadastrado",
                    subtitle = "Cadastre insumos e embalagens com o custo por unidade para montar as fichas técnicas"
                )

                else -> LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(
                        start = 16.dp, top = 4.dp, end = 16.dp, bottom = 88.dp
                    ),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(uiState.insumosFiltrados, key = { it.id }) { insumo ->
                        InsumoRow(
                            insumo = insumo,
                            onClick = { viewModel.onShowForm(insumo) },
                            onDelete = { viewModel.onShowDeleteConfirm(insumo) }
                        )
                    }
                }
            }
        }
    }

    if (uiState.showFormDialog) {
        InsumoFormDialog(
            insumo = uiState.insumoEmEdicao,
            onDismiss = viewModel::onHideForm,
            onConfirm = viewModel::save
        )
    }

    uiState.insumoParaExcluir?.let { insumo ->
        AlertDialog(
            onDismissRequest = viewModel::onHideDeleteConfirm,
            title = { Text("Excluir insumo?") },
            text = { Text("\"${insumo.nome}\" e seu histórico de preços serão excluídos.") },
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
private fun InsumoRow(
    insumo: Insumo,
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
                        text = insumo.nome,
                        style = MaterialTheme.typography.titleSmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    if (insumo.categoria == CategoriaInsumo.EMBALAGEM) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Surface(shape = RoundedCornerShape(50), color = YellowContainer) {
                            Text(
                                text = "embalagem",
                                style = MaterialTheme.typography.labelSmall,
                                color = YellowOnContainer,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Text(
                    text = "1 ${insumo.unidadeCompra} = ${formatarFator(insumo.fatorConversao)} ${insumo.unidadeUso}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "R$ ${formatarMoeda(insumo.custoAtual)}/${insumo.unidadeCompra}",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold
                )
                Text(
                    text = "R$ ${formatarMoeda(insumo.custoPorUnidadeUso)}/${insumo.unidadeUso}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Default.Delete,
                    contentDescription = "Excluir insumo",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

private fun formatarFator(valor: Double): String =
    if (valor % 1.0 == 0.0) valor.toInt().toString() else String.format("%.2f", valor)
