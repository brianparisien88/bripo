-- Moodboard — image upload + grid, stored in the existing private "documents"
-- Storage bucket (path-prefixed "moodboard/…"), same member-read/owner-write
-- RLS as every other table. No new bucket/policy needed.

create table moodboard_images (
  id           uuid primary key default gen_random_uuid(),
  storage_path text not null,
  label        text,
  description  text,
  uploaded_at  timestamptz not null default now()
);

alter table moodboard_images enable row level security;
create policy moodboard_images_member_read on moodboard_images for select using (public.is_member());
create policy moodboard_images_owner_write on moodboard_images for all using (public.is_owner()) with check (public.is_owner());
