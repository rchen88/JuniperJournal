insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'learning-module-videos',
  'learning-module-videos',
  false,
  524288000,
  array['video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v']
)
on conflict (id) do nothing;

create policy "Creators upload module videos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'learning-module-videos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Creators read module videos"
on storage.objects for select
to authenticated
using (
  bucket_id = 'learning-module-videos'
  and owner_id = auth.uid()::text
);

create policy "Creators update module videos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'learning-module-videos'
  and owner_id = auth.uid()::text
);

create policy "Creators delete module videos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'learning-module-videos'
  and owner_id = auth.uid()::text
);
