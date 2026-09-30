-- Cardo Notizen: einmal im Supabase-Projekt ausführen (SQL Editor → einfügen → Run).
-- Gleiches Projekt und gleiches Konto wie Cardo. Kann gefahrlos mehrmals ausgeführt werden.

-- 1) Tabelle für Ordner, Notizen, Vorschaubilder, Einstellungen und Striche (ein Dokument pro Zeile, wie "docs" bei Cardo)
create table if not exists public.notes_docs (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  path text not null check (char_length(path) between 1 and 300),
  data jsonb not null check (octet_length(data::text) < 8000000),
  updated_at timestamptz not null default now(),
  primary key (user_id, path)
);
create index if not exists notes_docs_updated on public.notes_docs (user_id, updated_at);
alter table public.notes_docs enable row level security;
drop policy if exists "notes_docs own" on public.notes_docs;
create policy "notes_docs own" on public.notes_docs for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Live-Abgleich zwischen Geräten (Realtime)
do $$ begin
  alter publication supabase_realtime add table public.notes_docs;
exception when duplicate_object then null; end $$;

-- 2) Privater Speicher für PDFs und Bilder (Vorlesungsfolien, Übungsblätter) – nur der Besitzer kommt heran
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('note-files', 'note-files', false, 52428800,
        array['application/pdf','image/png','image/jpeg','image/webp','image/gif','image/heic','image/heif','application/octet-stream'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "note-files read own" on storage.objects;
drop policy if exists "note-files insert own" on storage.objects;
drop policy if exists "note-files update own" on storage.objects;
drop policy if exists "note-files delete own" on storage.objects;
create policy "note-files read own" on storage.objects for select to authenticated
  using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "note-files insert own" on storage.objects for insert to authenticated
  with check (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "note-files update own" on storage.objects for update to authenticated
  using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "note-files delete own" on storage.objects for delete to authenticated
  using (bucket_id = 'note-files' and (storage.foldername(name))[1] = auth.uid()::text);

select 'ok' as status;
