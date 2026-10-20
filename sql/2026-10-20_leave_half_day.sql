-- Half-day leave (1st Half = AM / morning, 2nd Half = PM / afternoon)
-- Applied to Supabase project bom-system on 2026-10-20 (migration hrf_leave_half_day).
alter table public.hrf_leave_types add column if not exists allow_half boolean not null default false;
update public.hrf_leave_types set allow_half = true where code in ('VL','SL');
alter table public.hrf_request_lines add column if not exists day_part text check (day_part in ('AM','PM'));
-- hrf_submit now stores day_part for LEAVE rows and checks that:
--   * the leave type has allow_half = true
--   * a half-day row covers a single date (date_to = date_from)
-- (full function body is in the applied migration)
