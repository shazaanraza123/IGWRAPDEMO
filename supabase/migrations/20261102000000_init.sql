-- Schema and row level security from docs/05-BACKEND-SCHEMA.md.
-- Owner rows are visible only to auth.uid(). Public reads go through share_snapshots.

create type public.edition as enum ('personal', 'creator');
create type public.provenance as enum ('measured', 'estimated', 'inferred');

create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  handle text unique not null,
  display_name text,
  avatar_path text,
  account_type text not null check (account_type in ('personal', 'creator', 'business')),
  is_teen boolean not null default false,
  persona_key text,
  source_document jsonb
);

create table public.privacy_settings (
  user_id uuid primary key references public.profiles on delete cascade,
  include_dm_stats boolean not null default true,
  include_watch_history boolean not null default true,
  include_saves boolean not null default true,
  allow_together boolean not null default true,
  ranked_circle boolean not null default false,
  hide_usernames_on_share boolean not null default true,
  autoplay boolean not null default true
);

create table public.content_items (
  owner_id uuid not null references public.profiles on delete cascade,
  id text not null,
  kind text not null check (kind in ('post', 'reel', 'story')),
  posted_at date not null,
  media_path text,
  caption text,
  likes integer,
  comments integer,
  shares integer,
  saves integer,
  replies integer,
  views integer,
  primary key (owner_id, id)
);

create table public.daily_activity (
  user_id uuid not null references public.profiles on delete cascade,
  day date not null,
  minutes numeric,
  late_night_last_ts timestamptz,
  stories_watched integer,
  stories_available integer,
  reels_sent integer,
  saves integer,
  primary key (user_id, day)
);

create table public.interaction_edges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  counterpart_handle text not null,
  likes integer,
  comments integer,
  story_replies integer,
  dm_sends integer,
  score numeric,
  unique (user_id, counterpart_handle)
);

create table public.interest_scores (
  user_id uuid not null references public.profiles on delete cascade,
  month integer not null check (month between 1 and 12),
  category text not null,
  liked integer,
  saved integer,
  reels_seconds numeric,
  explore_score numeric,
  primary key (user_id, month, category)
);

create table public.liked_colors (
  user_id uuid not null references public.profiles on delete cascade,
  post_ref text not null,
  dominant_hex text not null check (dominant_hex ~* '^#[0-9a-f]{6}$'),
  primary key (user_id, post_ref)
);

create table public.wrapped_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  year integer not null,
  edition public.edition not null,
  period_start date not null,
  period_end date not null,
  tier text not null default 'full' check (tier in ('full', 'lite')),
  status text not null default 'pending' check (status in ('pending', 'ready', 'failed')),
  engine_version text not null,
  generated_at timestamptz,
  copy jsonb not null default '{}',
  unique (user_id, year, edition)
);

create table public.metrics (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.wrapped_runs on delete cascade,
  key text not null,
  value_num numeric,
  value_text text,
  unit text,
  provenance public.provenance not null,
  method text not null,
  window_start date not null,
  window_end date not null
);

create table public.archetype_scores (
  run_id uuid not null references public.wrapped_runs on delete cascade,
  archetype text not null,
  score numeric not null,
  rank integer not null,
  rationale jsonb not null default '{}',
  primary key (run_id, archetype)
);

create table public.cards (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.wrapped_runs on delete cascade,
  code text not null,
  type text not null,
  chapter text not null check (chapter in ('memories', 'interests', 'moments', 'people', 'identity')),
  sort_order integer not null,
  payload jsonb not null default '{}',
  metric_ids uuid[] not null default '{}',
  shareable boolean not null default true,
  teen_safe boolean not null default true,
  hidden boolean not null default false
);

create table public.card_feedback (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references public.cards on delete cascade,
  user_id uuid not null references public.profiles on delete cascade,
  kind text not null check (kind in ('more_of_this', 'not_me', 'guilty', 'looks_wrong')),
  target text,
  reason text,
  created_at timestamptz not null default now()
);

create table public.consent_grants (
  id uuid primary key default gen_random_uuid(),
  grantor_id uuid not null references public.profiles on delete cascade,
  grantee_id uuid not null references public.profiles on delete cascade,
  scope text not null check (scope in ('together', 'ranked_circle', 'named_fans')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.together_sessions (
  id uuid primary key default gen_random_uuid(),
  initiator_id uuid not null references public.profiles on delete cascade,
  partner_id uuid not null references public.profiles on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  created_at timestamptz not null default now()
);

create table public.together_items (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.together_sessions on delete cascade,
  content_owner_id uuid,
  content_id text,
  approved_by_initiator boolean not null default false,
  approved_by_partner boolean not null default false,
  check ((content_owner_id is null) = (content_id is null)),
  foreign key (content_owner_id, content_id) references public.content_items (owner_id, id) on delete set null
);

create table public.share_snapshots (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  card_id uuid not null references public.cards on delete cascade,
  owner_id uuid not null references public.profiles on delete cascade,
  format text not null check (format in ('story', 'post', 'square')),
  style text not null default 'bold',
  image_path text not null,
  alt_text text not null,
  revoked boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.share_events (
  id uuid primary key default gen_random_uuid(),
  snapshot_id uuid not null references public.share_snapshots on delete cascade,
  destination text not null check (destination in ('story', 'dm', 'save', 'link')),
  created_at timestamptz not null default now()
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  name text not null,
  props jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index metrics_run_id_idx on public.metrics (run_id);
create index cards_run_id_idx on public.cards (run_id);
create index archetype_scores_run_id_idx on public.archetype_scores (run_id);
create index wrapped_runs_user_id_idx on public.wrapped_runs (user_id);
create index content_items_owner_id_idx on public.content_items (owner_id);
create index share_snapshots_owner_id_idx on public.share_snapshots (owner_id);

create or replace function public.is_run_owner(target uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.wrapped_runs
    where id = target
      and user_id = auth.uid()
  );
$$;

revoke all on function public.is_run_owner(uuid) from public;
grant execute on function public.is_run_owner(uuid) to anon, authenticated, service_role;

create or replace function public.enforce_cards_hidden_only()
returns trigger
language plpgsql
as $$
begin
  if current_user in ('postgres', 'supabase_admin', 'service_role') then
    return new;
  end if;
  if (to_jsonb(new) - 'hidden') is distinct from (to_jsonb(old) - 'hidden') then
    raise exception 'cards updates may change hidden only';
  end if;
  return new;
end;
$$;

create trigger cards_hidden_only
  before update on public.cards
  for each row execute function public.enforce_cards_hidden_only();

create or replace function public.enforce_consent_status_only()
returns trigger
language plpgsql
as $$
begin
  if current_user in ('postgres', 'supabase_admin', 'service_role') then
    return new;
  end if;
  if (to_jsonb(new) - 'status' - 'updated_at') is distinct from (to_jsonb(old) - 'status' - 'updated_at') then
    raise exception 'grantee may update status only';
  end if;
  new.updated_at = now();
  return new;
end;
$$;

create trigger consent_status_only
  before update on public.consent_grants
  for each row execute function public.enforce_consent_status_only();

alter table public.profiles enable row level security;
alter table public.privacy_settings enable row level security;
alter table public.content_items enable row level security;
alter table public.daily_activity enable row level security;
alter table public.interaction_edges enable row level security;
alter table public.interest_scores enable row level security;
alter table public.liked_colors enable row level security;
alter table public.wrapped_runs enable row level security;
alter table public.metrics enable row level security;
alter table public.archetype_scores enable row level security;
alter table public.cards enable row level security;
alter table public.card_feedback enable row level security;
alter table public.consent_grants enable row level security;
alter table public.together_sessions enable row level security;
alter table public.together_items enable row level security;
alter table public.share_snapshots enable row level security;
alter table public.share_events enable row level security;
alter table public.events enable row level security;

create policy profiles_select on public.profiles
  for select using (id = auth.uid());
create policy profiles_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

create policy privacy_owner on public.privacy_settings
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy content_owner on public.content_items
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy activity_owner on public.daily_activity
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy edges_owner on public.interaction_edges
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy interests_owner on public.interest_scores
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy colors_owner on public.liked_colors
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy own_runs on public.wrapped_runs
  for select using (user_id = auth.uid());
create policy own_runs_delete on public.wrapped_runs
  for delete using (user_id = auth.uid());

create policy own_metrics on public.metrics
  for select using (public.is_run_owner(run_id));

create policy own_scores on public.archetype_scores
  for select using (public.is_run_owner(run_id));

create policy own_cards on public.cards
  for select using (public.is_run_owner(run_id));
create policy own_cards_update on public.cards
  for update using (public.is_run_owner(run_id)) with check (public.is_run_owner(run_id));

create policy feedback_select on public.card_feedback
  for select using (user_id = auth.uid());
create policy feedback_insert on public.card_feedback
  for insert with check (
    user_id = auth.uid()
    and public.is_run_owner((select run_id from public.cards where id = card_id))
  );

create policy grants_select on public.consent_grants
  for select using (grantor_id = auth.uid() or grantee_id = auth.uid());
create policy grants_insert on public.consent_grants
  for insert with check (grantor_id = auth.uid());
create policy grants_update on public.consent_grants
  for update using (grantee_id = auth.uid()) with check (grantee_id = auth.uid());

create policy together_select on public.together_sessions
  for select using (initiator_id = auth.uid() or partner_id = auth.uid());
create policy together_insert on public.together_sessions
  for insert with check (initiator_id = auth.uid());
create policy together_update on public.together_sessions
  for update
  using (initiator_id = auth.uid() or partner_id = auth.uid())
  with check (initiator_id = auth.uid() or partner_id = auth.uid());

create policy together_items_all on public.together_items
  for all
  using (
    exists (
      select 1 from public.together_sessions as session
      where session.id = session_id
        and (session.initiator_id = auth.uid() or session.partner_id = auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.together_sessions as session
      where session.id = session_id
        and (session.initiator_id = auth.uid() or session.partner_id = auth.uid())
    )
  );

create policy public_snapshots on public.share_snapshots
  for select using (revoked = false);
create policy own_snapshots on public.share_snapshots
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy share_events_owner on public.share_events
  for select using (
    exists (
      select 1 from public.share_snapshots as snapshot
      where snapshot.id = snapshot_id and snapshot.owner_id = auth.uid()
    )
  );
create policy share_events_insert on public.share_events
  for insert with check (
    exists (
      select 1 from public.share_snapshots as snapshot
      where snapshot.id = snapshot_id and snapshot.owner_id = auth.uid()
    )
  );

create policy events_select on public.events
  for select using (user_id = auth.uid());
create policy events_insert on public.events
  for insert with check (user_id = auth.uid());

revoke all on table
  public.profiles,
  public.privacy_settings,
  public.content_items,
  public.daily_activity,
  public.interaction_edges,
  public.interest_scores,
  public.liked_colors,
  public.wrapped_runs,
  public.metrics,
  public.archetype_scores,
  public.cards,
  public.card_feedback,
  public.consent_grants,
  public.together_sessions,
  public.together_items,
  public.share_snapshots,
  public.share_events,
  public.events
from anon, authenticated;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.privacy_settings to authenticated;
grant select, insert, update, delete on public.content_items to authenticated;
grant select, insert, update, delete on public.daily_activity to authenticated;
grant select, insert, update, delete on public.interaction_edges to authenticated;
grant select, insert, update, delete on public.interest_scores to authenticated;
grant select, insert, update, delete on public.liked_colors to authenticated;
grant select, delete on public.wrapped_runs to authenticated;
grant select on public.metrics to authenticated;
grant select on public.archetype_scores to authenticated;
grant select, update on public.cards to authenticated;
grant select, insert on public.card_feedback to authenticated;
grant select, insert, update on public.consent_grants to authenticated;
grant select, insert, update on public.together_sessions to authenticated;
grant select, insert, update, delete on public.together_items to authenticated;
grant select, insert, update on public.share_snapshots to authenticated;
grant select on public.share_snapshots to anon;
grant select, insert on public.share_events to authenticated;
grant select, insert on public.events to authenticated;

grant all on table
  public.profiles,
  public.privacy_settings,
  public.content_items,
  public.daily_activity,
  public.interaction_edges,
  public.interest_scores,
  public.liked_colors,
  public.wrapped_runs,
  public.metrics,
  public.archetype_scores,
  public.cards,
  public.card_feedback,
  public.consent_grants,
  public.together_sessions,
  public.together_items,
  public.share_snapshots,
  public.share_events,
  public.events
to service_role;

grant usage on type public.edition, public.provenance to anon, authenticated, service_role;
