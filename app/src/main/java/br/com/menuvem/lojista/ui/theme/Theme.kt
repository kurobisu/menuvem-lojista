package br.com.menuvem.lojista.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// ── Tema Claro Menuvem ────────────────────────────────────────────────────────
private val MenuvemLightColorScheme = lightColorScheme(
    primary = PurplePrimary,
    onPrimary = Color.White,
    primaryContainer = PurpleContainer,
    onPrimaryContainer = PurpleOnContainer,

    secondary = YellowSecondary,
    onSecondary = Color.White,
    secondaryContainer = YellowContainer,
    onSecondaryContainer = YellowOnContainer,

    tertiary = PurpleLight,
    onTertiary = Color.White,
    tertiaryContainer = PurpleContainer,
    onTertiaryContainer = PurpleOnContainer,

    background = BackgroundLight,
    onBackground = OnBackgroundLight,

    surface = SurfaceLight,
    onSurface = OnSurfaceLight,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = OnSurfaceVariantLight,

    outline = OutlineLight,
    outlineVariant = Color(0xFFE5DDF0),

    error = ErrorRed,
    onError = Color.White,
    errorContainer = ErrorContainer,
    onErrorContainer = Color(0xFF7F1D1D),

    inverseSurface = Color(0xFF1C1C1E),
    inverseOnSurface = Color(0xFFF5F5F5),
    inversePrimary = PurpleLight,

    surfaceTint = PurplePrimary,
    scrim = Color(0xFF000000)
)

@Composable
fun MenuvemLojistaTema(
    content: @Composable () -> Unit
) {
    val colorScheme = MenuvemLightColorScheme
    val view = LocalView.current

    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.setDecorFitsSystemWindows(window, false)
            val insetsController = WindowCompat.getInsetsController(window, view)
            insetsController.isAppearanceLightStatusBars = true
            insetsController.isAppearanceLightNavigationBars = true
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = MenuvemTypography,
        content = content
    )
}
