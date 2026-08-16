package br.com.menuvem.lojista

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.rememberNavController
import br.com.menuvem.lojista.presentation.auth.LoginScreen
import br.com.menuvem.lojista.presentation.auth.SessionViewModel
import br.com.menuvem.lojista.presentation.navigation.MenuvemNavGraph
import br.com.menuvem.lojista.ui.theme.MenuvemLojistaTema
import br.com.menuvem.lojista.ui.theme.PurplePrimary
import dagger.hilt.android.AndroidEntryPoint
import io.github.jan.supabase.auth.status.SessionStatus

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MenuvemLojistaTema {
                Surface(modifier = Modifier.fillMaxSize()) {
                    val sessionViewModel: SessionViewModel = hiltViewModel()
                    val sessionStatus by sessionViewModel.sessionStatus
                        .collectAsStateWithLifecycle()

                    when (sessionStatus) {
                        is SessionStatus.Authenticated -> {
                            val navController = rememberNavController()
                            MenuvemNavGraph(navController = navController)
                        }

                        is SessionStatus.Initializing -> {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) { CircularProgressIndicator(color = PurplePrimary) }
                        }

                        else -> LoginScreen()
                    }
                }
            }
        }
    }
}
