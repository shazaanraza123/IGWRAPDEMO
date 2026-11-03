insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('shares', 'shares', true, 10485760, array['image/png'])
on conflict (id) do nothing;

create policy shares_public_read on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'shares');

create policy shares_owner_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'shares'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
