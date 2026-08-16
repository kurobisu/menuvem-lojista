package br.com.menuvem.lojista.data.remote

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicLong

private val channelCounter = AtomicLong(0)

/**
 * Flow reativo de uma tabela do Supabase:
 * 1. Emite o snapshot inicial.
 * 2. Re-busca quando o repositório avisa uma mutação local ([localRefresh]).
 * 3. Re-busca quando o Realtime avisa mudanças feitas em OUTROS dispositivos.
 *
 * Se o Realtime não estiver habilitado na tabela, o item 2 ainda garante
 * consistência local.
 *
 * ATENÇÃO: o id do channel precisa ser único por flow — o Realtime devolve a
 * instância existente para ids repetidos, e chamar postgresChangeFlow num
 * channel já "joined" lança IllegalStateException.
 */
fun <T> SupabaseClient.tableListFlow(
    table: String,
    localRefresh: Flow<Unit>,
    fetch: suspend () -> List<T>
): Flow<List<T>> = channelFlow {
    send(fetch())

    launch { localRefresh.collect { send(fetch()) } }

    val realtimeChannel = channel("menuvem-$table-${channelCounter.incrementAndGet()}")
    val changes = realtimeChannel.postgresChangeFlow<PostgresAction>(schema = "public") {
        this.table = table
    }
    launch { changes.collect { send(fetch()) } }
    realtimeChannel.subscribe()

    awaitClose {
        launch { realtime.removeChannel(realtimeChannel) }
    }
}
