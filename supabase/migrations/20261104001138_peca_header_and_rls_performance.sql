-- Modelo de cabeçalho próprio da peça; nulo usa o padrão da área.
alter table public.pecas add column if not exists header_template text;

-- Índices cobrindo as colunas usadas nas políticas e nas consultas do app.
create index if not exists pecas_user_area_idx on public.pecas (user_id, area_name);
create index if not exists topics_user_area_idx on public.topics (user_id, area_name);

-- Mesma regra de acesso, avaliada uma vez por consulta em vez de uma por linha.
alter policy "Bloquear acesso para o proprio usuario." on public.user_areas
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy "Bloquear acesso para o proprio usuario." on public.pecas
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
alter policy "Bloquear acesso para o proprio usuario." on public.topics
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
