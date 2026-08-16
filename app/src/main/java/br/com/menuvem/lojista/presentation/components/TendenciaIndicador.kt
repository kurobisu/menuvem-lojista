package br.com.menuvem.lojista.presentation.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.TrendingDown
import androidx.compose.material.icons.filled.TrendingFlat
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.R
import br.com.menuvem.lojista.domain.model.TendenciaPreco
import br.com.menuvem.lojista.ui.theme.TrendDown
import br.com.menuvem.lojista.ui.theme.TrendStable
import br.com.menuvem.lojista.ui.theme.TrendUp

/**
 * Componente visual de tendência de preço (↑ Alta / → Estável / ↓ Queda).
 */
@Composable
fun TendenciaIndicador(
    tendencia: TendenciaPreco,
    modifier: Modifier = Modifier,
    showLabel: Boolean = false
) {
    val cor = when (tendencia) {
        TendenciaPreco.ALTA   -> TrendUp
        TendenciaPreco.ESTAVEL -> TrendStable
        TendenciaPreco.QUEDA  -> TrendDown
    }

    val icone = when (tendencia) {
        TendenciaPreco.ALTA   -> Icons.Default.TrendingUp
        TendenciaPreco.ESTAVEL -> Icons.Default.TrendingFlat
        TendenciaPreco.QUEDA  -> Icons.Default.TrendingDown
    }

    val label = when (tendencia) {
        TendenciaPreco.ALTA   -> stringResource(R.string.history_trend_up)
        TendenciaPreco.ESTAVEL -> stringResource(R.string.history_trend_stable)
        TendenciaPreco.QUEDA  -> stringResource(R.string.history_trend_down)
    }

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Surface(
            shape = MaterialTheme.shapes.small,
            color = cor.copy(alpha = 0.12f),
            modifier = Modifier.wrapContentSize()
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Icon(
                    imageVector = icone,
                    contentDescription = label,
                    tint = cor,
                    modifier = Modifier.size(14.dp)
                )
                if (showLabel) {
                    Text(
                        text = label,
                        style = MaterialTheme.typography.labelSmall,
                        color = cor
                    )
                }
            }
        }
    }
}
