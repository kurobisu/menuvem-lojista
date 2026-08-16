package br.com.menuvem.lojista.di

import br.com.menuvem.lojista.data.repository.HistoricoPrecoRepositoryImpl
import br.com.menuvem.lojista.data.repository.InsumoRepositoryImpl
import br.com.menuvem.lojista.data.repository.ListaComprasRepositoryImpl
import br.com.menuvem.lojista.data.repository.ProdutoRepositoryImpl
import br.com.menuvem.lojista.domain.repository.HistoricoPrecoRepository
import br.com.menuvem.lojista.domain.repository.InsumoRepository
import br.com.menuvem.lojista.domain.repository.ListaComprasRepository
import br.com.menuvem.lojista.domain.repository.ProdutoRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/**
 * Hilt module que vincula as interfaces de repositório às implementações concretas.
 * Para trocar para a implementação de API, basta alterar este módulo.
 */
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindInsumoRepository(impl: InsumoRepositoryImpl): InsumoRepository

    @Binds
    @Singleton
    abstract fun bindListaComprasRepository(impl: ListaComprasRepositoryImpl): ListaComprasRepository

    @Binds
    @Singleton
    abstract fun bindHistoricoPrecoRepository(impl: HistoricoPrecoRepositoryImpl): HistoricoPrecoRepository

    @Binds
    @Singleton
    abstract fun bindProdutoRepository(impl: ProdutoRepositoryImpl): ProdutoRepository
}
