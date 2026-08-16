-- ═══════════════════════════════════════════════════════════════════════════
-- Menuvem Lojista — schema inicial do banco (rodar no SQL Editor do Supabase)
-- Cria as 6 tabelas, ativa RLS (cada usuário só vê os próprios dados)
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

create table if not exists public.produtos (
    id                     bigint generated always as identity primary key,
    user_id                uuid not null default auth.uid() references auth.users (id) on delete cascade,
    nome                   text not null,
    margem_alvo_percentual double precision not null default 30,
    preco_venda_atual      double precision,
    data_criacao           timestamptz not null default now()
);

create table if not exists public.itens_ficha_tecnica (
    id               bigint generated always as identity primary key,
    user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
    produto_id       bigint not null references public.produtos (id) on delete cascade,
    insumo_id        bigint not null references public.insumos (id) on delete restrict,
    quantidade       double precision not null,
    perda_percentual double precision not null default 0
);

create index if not exists idx_itens_lista_lista on public.itens_lista (lista_compras_id);
create index if not exists idx_itens_lista_insumo on public.itens_lista (insumo_id);
create index if not exists idx_historico_insumo on public.historico_precos (insumo_id);
create index if not exists idx_ficha_produto on public.itens_ficha_tecnica (produto_id);
create index if not exists idx_ficha_insumo on public.itens_ficha_tecnica (insumo_id);

-- ── Row Level Security: cada usuário acessa apenas as próprias linhas ──────

alter table public.insumos enable row level security;
alter table public.listas_compras enable row level security;
alter table public.itens_lista enable row level security;
alter table public.historico_precos enable row level security;
alter table public.produtos enable row level security;
alter table public.itens_ficha_tecnica enable row level security;

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
create policy "dados do proprio usuario" on public.itens_ficha_tecnica
    for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── Realtime: app reage a mudanças feitas em outros dispositivos ────────────

alter publication supabase_realtime add table public.insumos;
alter publication supabase_realtime add table public.listas_compras;
alter publication supabase_realtime add table public.itens_lista;
alter publication supabase_realtime add table public.historico_precos;
alter publication supabase_realtime add table public.produtos;
alter publication supabase_realtime add table public.itens_ficha_tecnica;
