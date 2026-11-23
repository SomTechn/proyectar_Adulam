-- PROYECCIÓN · temas (ya aplicado en Supabase el 22 nov 2026)
alter table public.proy_config add column if not exists ajustes jsonb not null default '{}'::jsonb;

create table if not exists public.proy_temas (
  id         uuid primary key default gen_random_uuid(),
  iglesia_id uuid not null default '00000000-0000-0000-0000-000000000001',
  nombre     text not null,
  config     jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists proy_temas_iglesia_idx on public.proy_temas (iglesia_id, nombre);
alter table public.proy_temas enable row level security;
drop policy if exists proy_temas_all on public.proy_temas;
create policy proy_temas_all on public.proy_temas
  for all to authenticated using (public.proy_puede()) with check (public.proy_puede());

alter table public.proy_culto_items add column if not exists tema_id uuid references public.proy_temas(id) on delete set null;
create index if not exists proy_culto_items_tema_idx on public.proy_culto_items (tema_id);

notify pgrst, 'reload schema';
