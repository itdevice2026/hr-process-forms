-- E-signatures for HR Process Forms (bom-system project)
create table if not exists public.hrf_signatures (
  employee_id uuid primary key references public.hrf_employees(id) on delete cascade,
  image text not null check (image like 'data:image/png;base64,%' and length(image) < 300000),
  updated_at timestamptz not null default now()
);
alter table public.hrf_signatures enable row level security;
drop policy if exists hrf_sig_own_sel on public.hrf_signatures;
drop policy if exists hrf_sig_own_ins on public.hrf_signatures;
drop policy if exists hrf_sig_own_upd on public.hrf_signatures;
drop policy if exists hrf_sig_own_del on public.hrf_signatures;
create policy hrf_sig_own_sel on public.hrf_signatures for select to authenticated using (employee_id = public.hrf_me());
create policy hrf_sig_own_ins on public.hrf_signatures for insert to authenticated with check (employee_id = public.hrf_me());
create policy hrf_sig_own_upd on public.hrf_signatures for update to authenticated using (employee_id = public.hrf_me()) with check (employee_id = public.hrf_me());
create policy hrf_sig_own_del on public.hrf_signatures for delete to authenticated using (employee_id = public.hrf_me());
grant select, insert, update, delete on public.hrf_signatures to authenticated;

alter table public.hrf_requests  add column if not exists emp_signature text;
alter table public.hrf_approvals add column if not exists acted_signature text;

create or replace function public.hrf_stamp_request_sig() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'pending' and (tg_op = 'INSERT' or old.status is distinct from 'pending' or old.rev is distinct from new.rev) then
    new.emp_signature := (select image from public.hrf_signatures where employee_id = new.employee_id);
  end if;
  return new;
end $$;
drop trigger if exists trg_hrf_stamp_request_sig on public.hrf_requests;
create trigger trg_hrf_stamp_request_sig before insert or update on public.hrf_requests
  for each row execute function public.hrf_stamp_request_sig();

create or replace function public.hrf_stamp_approval_sig() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' and new.acted_by_id is not null then
    new.acted_signature := (select image from public.hrf_signatures where employee_id = new.acted_by_id);
  end if;
  return new;
end $$;
drop trigger if exists trg_hrf_stamp_approval_sig on public.hrf_approvals;
create trigger trg_hrf_stamp_approval_sig before update on public.hrf_approvals
  for each row execute function public.hrf_stamp_approval_sig();

revoke execute on function public.hrf_stamp_request_sig() from public, anon, authenticated;
revoke execute on function public.hrf_stamp_approval_sig() from public, anon, authenticated;
