-- Proves user A cannot read user B's wrapped run. Rolls back.
begin;

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change, is_anonymous
) values
  ('00000000-0000-0000-0000-000000000000', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'authenticated', 'authenticated', 'user.a@personas.invalid', '$2a$08$/sREiTgj59sG4GzzMKQA4.XQvuFokBo.iq1rLzoXAhbmhzo7aZjwq', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '', false),
  ('00000000-0000-0000-0000-000000000000', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'authenticated', 'authenticated', 'user.b@personas.invalid', '$2a$08$/sREiTgj59sG4GzzMKQA4.XQvuFokBo.iq1rLzoXAhbmhzo7aZjwq', now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '', false);

insert into public.profiles (id, handle, display_name, account_type, is_teen)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'user.a', 'User A', 'personal', false),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'user.b', 'User B', 'personal', false);

insert into public.wrapped_runs (id, user_id, year, edition, period_start, period_end, engine_version, status)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 2026, 'personal', '2026-01-01', '2026-11-15', 'rls-test', 'ready'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 2026, 'personal', '2026-01-01', '2026-11-15', 'rls-test', 'ready');

insert into public.cards (id, run_id, code, type, chapter, sort_order, payload)
values (
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',
  'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  'P01',
  'opening',
  'memories',
  1,
  '{}'
);

insert into public.share_snapshots (slug, card_id, owner_id, format, image_path, alt_text, revoked)
values
  ('public-b', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'story', 'shares/public-b.png', 'A shared card', false),
  ('revoked-b', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'story', 'shares/revoked-b.png', 'A revoked card', true);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa","role":"authenticated"}', true);
select set_config('request.jwt.claim.sub', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', true);

do $rls$
declare
  seen_runs int;
  seen_b int;
begin
  select count(*) into seen_runs from public.wrapped_runs;
  if seen_runs <> 1 then
    raise exception 'user A saw % runs, expected 1', seen_runs;
  end if;
  select count(*) into seen_b from public.wrapped_runs
    where user_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  if seen_b <> 0 then
    raise exception 'user A can read user B runs';
  end if;
  select count(*) into seen_b from public.profiles
    where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  if seen_b <> 0 then
    raise exception 'user A can read user B profile';
  end if;
end
$rls$;

do $rls$
begin
  update public.cards set payload = '{"tampered":true}'::jsonb
    where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
  raise exception 'payload update should have been rejected';
exception
  when others then
    if sqlerrm not like '%hidden only%' then
      raise;
    end if;
end
$rls$;

update public.cards set hidden = true where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';

do $rls$
declare
  is_hidden boolean;
begin
  select hidden into is_hidden from public.cards where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
  if is_hidden is not true then
    raise exception 'owner could not hide their own card';
  end if;
end
$rls$;

reset role;
set local role anon;
select set_config('request.jwt.claims', '', true);
select set_config('request.jwt.claim.sub', '', true);

do $rls$
declare
  seen_public int;
begin
  begin
    perform 1 from public.wrapped_runs;
    raise exception 'anon was able to query runs';
  exception
    when insufficient_privilege then
      null;
  end;
  select count(*) into seen_public from public.share_snapshots;
  if seen_public <> 1 then
    raise exception 'anon saw % snapshots, expected the one unrevoked share', seen_public;
  end if;
end
$rls$;

rollback;
