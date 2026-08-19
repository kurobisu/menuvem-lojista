-- ═══════════════════════════════════════════════════════════════════════════
-- Menuvem Lojista — schema inicial do banco (rodar no SQL Editor do Supabase)
-- Cria as 11 tabelas, ativa RLS (cada usuário só vê os próprios dados)
-- e habilita Realtime para sync em tempo real entre dispositivos.
-- ═══════════════════════════════════════════════════════════════════════════

create table if not exists public.insumos (
    id              bigint generated always as identity primary key,
    user_id         uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome            text not null,
    unidade_compra  text not null,
    unidade_uso     text not null,
    fator_conversao double precision not null,
    custo_atual     double precision not null default 0,
    categoria       text not null default 'INSUMO',
    emoji           text,
    data_criacao    timestamptz not null default now()
);

create table if not exists public.listas_compras (
    id               bigint generated always as identity primary key,
    user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome             text not null,
    data_criacao     timestamptz not null default now(),
    data_finalizacao timestamptz,
    total_gasto      double precision not null default 0,
    status           text not null default 'ABERTA'
);

create table if not exists public.itens_lista (
    id               bigint generated always as identity primary key,
    user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
    lista_compras_id bigint not null references public.listas_compras (id) on delete cascade,
    insumo_id        bigint references public.insumos (id) on delete set null,
    nome_item        text not null,
    quantidade       double precision not null,
    unidade          text not null,
    preco_unitario   double precision not null default 0,
    comprado         boolean not null default false
);

create table if not exists public.historico_precos (
    id                 bigint generated always as identity primary key,
    user_id            uuid not null default auth.uid() references auth.users (id) on delete cascade,
    insumo_id          bigint not null references public.insumos (id) on delete cascade,
    preco              double precision not null,
    data               timestamptz not null default now(),
    lista_compras_id   bigint not null,
    lista_compras_nome text not null default ''
);

-- O produto é só a "família" (nome + ícone). Custo, margem-alvo e preço vivem
-- em cada porção: um produto tem uma porção "Única" quando é de tamanho único,
-- ou várias (P, M, G, Família...) quando é vendido em tamanhos diferentes com
-- a mesma receita base. A ficha técnica pendura na PORÇÃO, não no produto.
create table if not exists public.produtos (
    id           bigint generated always as identity primary key,
    user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome         text not null,
    emoji        text,
    data_criacao timestamptz not null default now()
);

create table if not exists public.porcoes (
    id                     bigint generated always as identity primary key,
    user_id                uuid not null default auth.uid() references auth.users (id) on delete cascade,
    produto_id             bigint not null references public.produtos (id) on delete cascade,
    nome                   text not null,
    ordem                  integer not null default 0,
    margem_alvo_percentual double precision not null default 30,
    preco_venda_atual      double precision,
    data_criacao           timestamptz not null default now()
);

create table if not exists public.itens_ficha_tecnica (
    id               bigint generated always as identity primary key,
    user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
    porcao_id        bigint not null references public.porcoes (id) on delete cascade,
    insumo_id        bigint not null references public.insumos (id) on delete restrict,
    quantidade       double precision not null,
    perda_percentual double precision not null default 0
);

-- ═══ Componentes (blocos reutilizáveis de ficha técnica) ═════════════════════
-- Um componente é um template de insumos (ex.: "Pizza - Massa Grande 35cm",
-- "Pizza Sabor - Calabresa"). Ao montar um produto, o componente entra com um
-- multiplicador (produto_componentes): sabor único = 1; 2 sabores = 0,5; 3 = 1/3.
--
-- O tipo do componente (Massa, Sabor, Embalagem...) não é mais uma lista fixa:
-- é uma tabela própria (tipos_componente) que o usuário cadastra livremente
-- ao digitar o nome no app (autocompletar reaproveita os já criados).

create table if not exists public.tipos_componente (
    id           bigint generated always as identity primary key,
    user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome         text not null,
    ordem        integer not null default 0,
    data_criacao timestamptz not null default now()
);

create table if not exists public.componentes (
    id                  bigint generated always as identity primary key,
    user_id             uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome                text not null,
    tipo_componente_id  bigint references public.tipos_componente (id) on delete set null,
    ordem               integer not null default 0,
    emoji               text,
    data_criacao        timestamptz not null default now()
);

-- Um componente tem 1..N tamanhos (ex.: "Único", "35cm", "Família") -- mesmo
-- padrão de porcoes para produtos: sempre existe pelo menos um ("Único"), e
-- quando é só esse a UI esconde o conceito. Permite variar as quantidades de
-- insumo por tamanho sem duplicar o componente inteiro.
create table if not exists public.tamanhos_componente (
    id            bigint generated always as identity primary key,
    user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
    componente_id bigint not null references public.componentes (id) on delete cascade,
    nome          text not null,
    ordem         integer not null default 0,
    data_criacao  timestamptz not null default now()
);

create table if not exists public.itens_componente (
    id                    bigint generated always as identity primary key,
    user_id               uuid not null default auth.uid() references auth.users (id) on delete cascade,
    tamanho_componente_id bigint not null references public.tamanhos_componente (id) on delete cascade,
    insumo_id             bigint not null references public.insumos (id) on delete restrict,
    quantidade            double precision not null,
    perda_percentual      double precision not null default 0
);

create table if not exists public.produto_componentes (
    id                    bigint generated always as identity primary key,
    user_id               uuid not null default auth.uid() references auth.users (id) on delete cascade,
    porcao_id             bigint not null references public.porcoes (id) on delete cascade,
    componente_id         bigint not null references public.componentes (id) on delete cascade,
    tamanho_componente_id bigint not null references public.tamanhos_componente (id) on delete cascade,
    multiplicador         double precision not null default 1
);

create index if not exists idx_itens_lista_lista on public.itens_lista (lista_compras_id);
create index if not exists idx_itens_lista_insumo on public.itens_lista (insumo_id);
create index if not exists idx_historico_insumo on public.historico_precos (insumo_id);
create index if not exists idx_porcoes_produto on public.porcoes (produto_id);
create index if not exists idx_ficha_porcao on public.itens_ficha_tecnica (porcao_id);
create index if not exists idx_ficha_insumo on public.itens_ficha_tecnica (insumo_id);
create index if not exists idx_tamanhos_componente_componente on public.tamanhos_componente (componente_id);
create index if not exists idx_comp_item_tamanho on public.itens_componente (tamanho_componente_id);
create index if not exists idx_comp_item_insumo on public.itens_componente (insumo_id);
create index if not exists idx_prod_comp_porcao on public.produto_componentes (porcao_id);
create index if not exists idx_prod_comp_componente on public.produto_componentes (componente_id);
create index if not exists idx_prod_comp_tamanho on public.produto_componentes (tamanho_componente_id);
create index if not exists idx_componentes_tipo on public.componentes (tipo_componente_id);

-- ── Row Level Security: cada usuário acessa apenas as próprias linhas ──────

alter table public.insumos enable row level security;
alter table public.listas_compras enable row level security;
alter table public.itens_lista enable row level security;
alter table public.historico_precos enable row level security;
alter table public.produtos enable row level security;
alter table public.porcoes enable row level security;
alter table public.itens_ficha_tecnica enable row level security;
alter table public.tipos_componente enable row level security;
alter table public.componentes enable row level security;
alter table public.tamanhos_componente enable row level security;
alter table public.itens_componente enable row level security;
alter table public.produto_componentes enable row level security;

create policy "dados do proprio usuario" on public.insumos
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.listas_compras
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.itens_lista
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.historico_precos
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.produtos
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.porcoes
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.itens_ficha_tecnica
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.tipos_componente
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.componentes
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.tamanhos_componente
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.itens_componente
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "dados do proprio usuario" on public.produto_componentes
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Realtime: app reage a mudanças feitas em outros dispositivos ────────────

alter publication supabase_realtime add table public.insumos;
alter publication supabase_realtime add table public.listas_compras;
alter publication supabase_realtime add table public.itens_lista;
alter publication supabase_realtime add table public.historico_precos;
alter publication supabase_realtime add table public.produtos;
alter publication supabase_realtime add table public.porcoes;
alter publication supabase_realtime add table public.itens_ficha_tecnica;
alter publication supabase_realtime add table public.tipos_componente;
alter publication supabase_realtime add table public.componentes;
alter publication supabase_realtime add table public.tamanhos_componente;
alter publication supabase_realtime add table public.itens_componente;
alter publication supabase_realtime add table public.produto_componentes;

-- `.stream().eq(coluna_que_nao_e_chave_primaria, ...)` no app (ex.: filtrar
-- por porcao_id, componente_id, tamanho_componente_id) precisa que o evento
-- de Realtime carregue essa coluna também -- com REPLICA IDENTITY DEFAULT
-- (o padrão do Postgres), um DELETE só carrega a chave primária da linha
-- apagada, e o cliente não consegue confirmar se ela pertencia ao filtro
-- ativo, então descarta o evento silenciosamente. A linha ficava "fantasma"
-- na tela até a próxima abertura da tela.
alter table public.porcoes replica identity full;
alter table public.itens_ficha_tecnica replica identity full;
alter table public.tipos_componente replica identity full;
alter table public.tamanhos_componente replica identity full;
alter table public.itens_componente replica identity full;
alter table public.itens_lista replica identity full;
alter table public.produto_componentes replica identity full;
