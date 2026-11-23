begin;

create table public.assignment_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  schedule_id uuid not null references public.schedules(id) on delete cascade,
  service_date date not null,
  service_id text not null references public.services(id),
  position text not null check (position ~ '^cam_([1-9]|1[0-6])$'),
  created_at timestamptz not null default now(),
  read_at timestamptz,
  unique (user_id, schedule_id, position)
);

create index assignment_notifications_user_recent
  on public.assignment_notifications (user_id, created_at desc);

alter table public.assignment_notifications enable row level security;

create policy assignment_notifications_read_own
  on public.assignment_notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy assignment_notifications_mark_own_read
  on public.assignment_notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.assignment_notifications from anon, authenticated;
grant select on public.assignment_notifications to authenticated;
grant update (read_at) on public.assignment_notifications to authenticated;

create or replace function public.notify_camera_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  published_schedule record;
begin
  select s.id, s.service_date, s.service_id
    into published_schedule
    from public.schedules s
   where s.id = new.schedule_id
     and s.status = 'published';

  if not found or new.position !~ '^cam_([1-9]|1[0-6])$' then
    return new;
  end if;

  insert into public.assignment_notifications
    (user_id, schedule_id, service_date, service_id, position)
  values
    (new.user_id, published_schedule.id, published_schedule.service_date,
     published_schedule.service_id, new.position)
  on conflict (user_id, schedule_id, position) do nothing;

  return new;
end;
$$;

revoke all on function public.notify_camera_assignment() from public, anon, authenticated;

create trigger notify_camera_assignment_after_publish
  after insert on public.assignments
  for each row execute function public.notify_camera_assignment();

commit;
