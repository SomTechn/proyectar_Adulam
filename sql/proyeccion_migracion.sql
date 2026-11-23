-- =====================================================================
-- PROYECCIÓN · tablas nuevas en el proyecto Supabase de ADULAM
-- Pegar completo en Supabase > SQL Editor > Run.
-- Solo CREA cosas nuevas (prefijo proy_). No modifica tablas de ADULAM.
-- Se puede correr más de una vez sin problema.
-- =====================================================================

-- 1) Permiso: admin, pastor, lider y servidor pueden usar Proyección
create or replace function public.proy_puede()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and rol in ('admin','pastor','lider','servidor')
  );
$$;
grant execute on function public.proy_puede() to authenticated;

-- 2) Configuración por iglesia (código de sala y tema visual)
create table if not exists public.proy_config (
  iglesia_id uuid primary key default '00000000-0000-0000-0000-000000000001',
  sala       text not null default substr(md5(random()::text || clock_timestamp()::text), 1, 10),
  tema       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 3) Cantos
create table if not exists public.proy_cantos (
  id         uuid primary key default gen_random_uuid(),
  iglesia_id uuid not null default '00000000-0000-0000-0000-000000000001',
  titulo     text not null,
  autor      text,
  tono       text,
  letra      text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists proy_cantos_iglesia_idx on public.proy_cantos (iglesia_id, titulo);

-- 4) Cultos (cada servicio)
create table if not exists public.proy_cultos (
  id         uuid primary key default gen_random_uuid(),
  iglesia_id uuid not null default '00000000-0000-0000-0000-000000000001',
  fecha      date not null default current_date,
  nombre     text not null default 'Culto',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists proy_cultos_fecha_idx on public.proy_cultos (iglesia_id, fecha desc);

-- 5) Orden del culto
create table if not exists public.proy_culto_items (
  id         uuid primary key default gen_random_uuid(),
  culto_id   uuid not null references public.proy_cultos(id) on delete cascade,
  posicion   integer not null default 0,
  tipo       text not null check (tipo in ('canto','biblia','texto')),
  canto_id   uuid references public.proy_cantos(id) on delete set null,
  titulo     text,
  ref        text,
  contenido  text,
  created_at timestamptz not null default now()
);
create index if not exists proy_culto_items_culto_idx on public.proy_culto_items (culto_id, posicion);

-- 6) RLS
alter table public.proy_config      enable row level security;
alter table public.proy_cantos      enable row level security;
alter table public.proy_cultos      enable row level security;
alter table public.proy_culto_items enable row level security;

drop policy if exists proy_config_all on public.proy_config;
create policy proy_config_all on public.proy_config
  for all to authenticated using (public.proy_puede()) with check (public.proy_puede());

drop policy if exists proy_cantos_all on public.proy_cantos;
create policy proy_cantos_all on public.proy_cantos
  for all to authenticated using (public.proy_puede()) with check (public.proy_puede());

drop policy if exists proy_cultos_all on public.proy_cultos;
create policy proy_cultos_all on public.proy_cultos
  for all to authenticated using (public.proy_puede()) with check (public.proy_puede());

drop policy if exists proy_culto_items_all on public.proy_culto_items;
create policy proy_culto_items_all on public.proy_culto_items
  for all to authenticated using (public.proy_puede()) with check (public.proy_puede());

-- 7) Fila de configuración inicial
insert into public.proy_config (iglesia_id) values ('00000000-0000-0000-0000-000000000001')
on conflict (iglesia_id) do nothing;

-- 8) Almacenamiento de fondos y logos (bucket público)
insert into storage.buckets (id, name, public)
values ('proy-medios', 'proy-medios', true)
on conflict (id) do nothing;

drop policy if exists proy_medios_insert on storage.objects;
create policy proy_medios_insert on storage.objects
  for insert to authenticated with check (bucket_id = 'proy-medios' and public.proy_puede());

drop policy if exists proy_medios_update on storage.objects;
create policy proy_medios_update on storage.objects
  for update to authenticated using (bucket_id = 'proy-medios' and public.proy_puede());

drop policy if exists proy_medios_delete on storage.objects;
create policy proy_medios_delete on storage.objects
  for delete to authenticated using (bucket_id = 'proy-medios' and public.proy_puede());

-- 9) Refrescar PostgREST
notify pgrst, 'reload schema';
