package br.com.menuvem.lojista.presentation.shopping

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.List
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
import br.com.menuvem.lojista.domain.model.ListaCompras
import br.com.menuvem.lojista.domain.model.StatusLista
import br.com.menuvem.lojista.presentation.components.EmptyState
import br.com.menuvem.lojista.presentation.components.formatarMoeda
import br.com.menuvem.lojista.ui.theme.PurplePrimary
import br.com.menuvem.lojista.ui.theme.SuccessGreen
import br.com.menuvem.lojista.ui.theme.YellowSecondary
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShoppingListsScreen(
    onNavigateToLista: (Long) -> Unit,
    onBack: () -> Unit,
    viewModel: ShoppingListsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var newListName by remember { mutableStateOf("") }

    if (showCreateDialog) {
        AlertDialog(
            onDismissRequest = { showCreateDialog = false; newListName = "" },
            icon = { Icon(Icons.Default.Add, contentDescription = null) },
            title = { Text("Nova lista de compras") },
            text = {
                OutlinedTextField(
                    value = newListName,
                    onValueChange = { newListName = it },
                    label = { Text("Nome da lista") },
                    placeholder = { Text("Ex: Mercado - Semana 33") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newListName.isNotBlank()) {
                            viewModel.createLista(newListName) { id ->
                                showCreateDialog = false
                                newListName = ""
                                onNavigateToLista(id)
                            }
                        }
                    },
                    enabled = newListName.isNotBlank()
                ) { Text("Criar") }
            },
            dismissButton = {
                TextButton(onClick = { showCreateDialog = false; newListName = "" }) {
                    Text("Cancelar")
                }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Minhas Listas", fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Voltar")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showCreateDialog = true },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("Nova Lista") },
                containerColor = YellowSecondary,
                contentColor = Color.White
            )
        }
    ) { paddingValues ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) { CircularProgressIndicator(color = PurplePrimary) }
        } else if (uiState.listas.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(paddingValues),
                contentAlignment = Alignment.Center
            ) {
                EmptyState(
                    icon = Icons.Outlined.List,
                    title = "Nenhuma lista criada",
                    subtitle = "Crie sua primeira lista para começar a registrar compras"
                )
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(
                    start = 12.dp, top = 8.dp, end = 12.dp, bottom = 80.dp
                ),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(uiState.listas) { lista ->
                    ListaComprasItem(
                        lista = lista,
                        onClick = { onNavigateToLista(lista.id) }
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ListaComprasItem(
    lista: ListaCompras,
    onClick: () -> Unit
) {
    val isFinalized = lista.status == StatusLista.FINALIZADA
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy")

    ElevatedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = if (isFinalized)
                    SuccessGreen.copy(alpha = 0.12f)
                else
                    PurplePrimary.copy(alpha = 0.10f),
                modifier = Modifier.size(44.dp)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = if (isFinalized) Icons.Default.CheckCircle else Icons.Default.ShoppingCart,
                        contentDescription = null,
                        tint = if (isFinalized) SuccessGreen else PurplePrimary,
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = lista.nome,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = lista.dataCriacao.format(formatter),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                if (lista.totalGasto > 0) {
                    Text(
                        text = "R$ ${formatarMoeda(lista.totalGasto)}",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = if (isFinalized) SuccessGreen else PurplePrimary
                    )
                }
                Spacer(modifier = Modifier.height(2.dp))
                Surface(
                    shape = MaterialTheme.shapes.extraSmall,
                    color = if (isFinalized)
                        SuccessGreen.copy(alpha = 0.12f)
                    else
                        PurplePrimary.copy(alpha = 0.10f)
                ) {
                    Text(
                        text = if (isFinalized) "Finalizada" else "Aberta",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isFinalized) SuccessGreen else PurplePrimary,
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(8.dp))
            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
            )
        }
    }
}
