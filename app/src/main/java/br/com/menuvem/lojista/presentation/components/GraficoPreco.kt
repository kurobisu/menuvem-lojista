package br.com.menuvem.lojista.presentation.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import br.com.menuvem.lojista.domain.model.HistoricoPreco
import br.com.menuvem.lojista.ui.theme.PurplePrimary
import java.time.format.DateTimeFormatter

/**
 * Gráfico de linha simples para o histórico de preços de um insumo.
 * Desenhado com Canvas para evitar dependências externas.
 */
@Composable
fun GraficoPreco(
    historico: List<HistoricoPreco>,
    modifier: Modifier = Modifier,
    lineColor: Color = PurplePrimary,
    dotColor: Color = PurplePrimary,
    height: Dp = 160.dp
) {
    if (historico.size < 2) return

    val precos = historico.map { it.preco }
    val minPreco = precos.min()
    val maxPreco = precos.max()
    val range = if (maxPreco == minPreco) 1.0 else maxPreco - minPreco

    val dateFormatter = DateTimeFormatter.ofPattern("dd/MM")

    Column(modifier = modifier) {
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(height)
                .padding(horizontal = 8.dp, vertical = 8.dp)
        ) {
            val width = size.width
            val canvasHeight = size.height
            val padding = 16.dp.toPx()

            val effectiveWidth = width - padding * 2
            val effectiveHeight = canvasHeight - padding * 2

            // Calcula pontos
            val points = historico.mapIndexed { index, h ->
                val x = padding + (index.toFloat() / (historico.size - 1)) * effectiveWidth
                val normalizado = ((h.preco - minPreco) / range).toFloat()
                val y = padding + effectiveHeight * (1f - normalizado)
                Offset(x, y)
            }

            // Área preenchida (gradiente simulado com alpha)
            val fillPath = Path().apply {
                moveTo(points.first().x, canvasHeight - padding)
                points.forEach { lineTo(it.x, it.y) }
                lineTo(points.last().x, canvasHeight - padding)
                close()
            }
            drawPath(
                path = fillPath,
                color = lineColor.copy(alpha = 0.1f)
            )

            // Linha
            val linePath = Path().apply {
                moveTo(points.first().x, points.first().y)
                points.drop(1).forEach { lineTo(it.x, it.y) }
            }
            drawPath(
                path = linePath,
                color = lineColor,
                style = Stroke(
                    width = 2.5.dp.toPx(),
                    cap = StrokeCap.Round,
                    join = StrokeJoin.Round
                )
            )

            // Pontos
            points.forEach { point ->
                drawCircle(
                    color = Color.White,
                    radius = 5.dp.toPx(),
                    center = point
                )
                drawCircle(
                    color = dotColor,
                    radius = 4.dp.toPx(),
                    center = point,
                    style = Stroke(width = 2.dp.toPx())
                )
            }
        }

        // Labels de datas no eixo X
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            val step = maxOf(1, historico.size / 4)
            val indices = (historico.indices step step).toList().let {
                if (historico.lastIndex !in it) it + historico.lastIndex else it
            }
            indices.forEach { i ->
                Text(
                    text = historico[i].data.format(dateFormatter),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }
        }
    }
}
