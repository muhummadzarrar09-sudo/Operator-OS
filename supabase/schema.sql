-- Enable UUID extension if needed (Supabase has it by default)
-- create extension if not exists "uuid-ossp";

-- -------------------------------------------------
-- 1. stats
-- -------------------------------------------------
create table stats (
  id            text primary key,
  user_id       text not null,
  stat_key      text not null,
  level         int  not null default 1,
  current_xp    int  not null default 0,
  sub_stats_json text not null default '{}',
  created_at    bigint not null,
  updated_at    bigint not null
);

alter table stats enable row level security;

create policy stats_select on stats for select using (user_id = (select auth.uid()));
create policy stats_insert on stats for insert with check (user_id = (select auth.uid()));
create policy stats_update on stats for update using (user_id = (select auth.uid()));
create policy stats_delete on stats for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 2. quests
-- -------------------------------------------------
create table quests (
  id              text primary key,
  user_id         text not null,
  domain          text not null,
  title           text not null,
  tier            text not null,
  xp_value        int  not null,
  status          text not null,
  due_date        bigint,
  completed_at    bigint,
  roadmap_day_id  text,
  created_at      bigint not null,
  updated_at      bigint not null
);

alter table quests enable row level security;

create policy quests_select on quests for select using (user_id = (select auth.uid()));
create policy quests_insert on quests for insert with check (user_id = (select auth.uid()));
create policy quests_update on quests for update using (user_id = (select auth.uid()));
create policy quests_delete on quests for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 3. habits
-- -------------------------------------------------
create table habits (
  id                    text primary key,
  user_id               text not null,
  domain                text not null,
  name                  text not null,
  cadence               text not null,
  skip_tokens_remaining int  not null default 1,
  current_streak        int  not null default 0,
  created_at            bigint not null,
  updated_at            bigint not null
);

alter table habits enable row level security;

create policy habits_select on habits for select using (user_id = (select auth.uid()));
create policy habits_insert on habits for insert with check (user_id = (select auth.uid()));
create policy habits_update on habits for update using (user_id = (select auth.uid()));
create policy habits_delete on habits for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 4. journal_entries
-- -------------------------------------------------
create table journal_entries (
  id                text primary key,
  user_id           text not null,
  date              bigint not null,
  mood              text not null,
  sleep_hours       real,
  sleep_quality     text,
  wins              text not null default '',
  lesson_learned    text not null default '',
  tomorrow_plan     text not null default '',
  big_picture_note  text not null default '',
  created_at        bigint not null,
  updated_at        bigint not null
);

alter table journal_entries enable row level security;

create policy journal_select on journal_entries for select using (user_id = (select auth.uid()));
create policy journal_insert on journal_entries for insert with check (user_id = (select auth.uid()));
create policy journal_update on journal_entries for update using (user_id = (select auth.uid()));
create policy journal_delete on journal_entries for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 5. roadmap_days
-- -------------------------------------------------
create table roadmap_days (
  id              text primary key,
  user_id         text not null,
  day_number      int  not null,
  date            bigint not null,
  day_type        text not null,
  slot_a          text not null,
  slot_b          text not null,
  bedtime_target  text not null,
  notes           text not null default '',
  done            boolean not null default false,
  created_at      bigint not null,
  updated_at      bigint not null
);

alter table roadmap_days enable row level security;

create policy roadmap_select on roadmap_days for select using (user_id = (select auth.uid()));
create policy roadmap_insert on roadmap_days for insert with check (user_id = (select auth.uid()));
create policy roadmap_update on roadmap_days for update using (user_id = (select auth.uid()));
create policy roadmap_delete on roadmap_days for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 6. sleep_logs
-- -------------------------------------------------
create table sleep_logs (
  id              text primary key,
  user_id         text not null,
  date            bigint not null,
  bedtime         bigint not null,
  wake_time       bigint not null,
  duration_hours  real not null,
  on_target       boolean not null default false,
  created_at      bigint not null,
  updated_at      bigint not null
);

alter table sleep_logs enable row level security;

create policy sleep_select on sleep_logs for select using (user_id = (select auth.uid()));
create policy sleep_insert on sleep_logs for insert with check (user_id = (select auth.uid()));
create policy sleep_update on sleep_logs for update using (user_id = (select auth.uid()));
create policy sleep_delete on sleep_logs for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 7. boss_days
-- -------------------------------------------------
create table boss_days (
  id                text primary key,
  user_id           text not null,
  date              bigint not null,
  review_notes      text not null default '',
  future_self_note  text not null default '',
  perk_unlocked     text,
  created_at        bigint not null,
  updated_at        bigint not null
);

alter table boss_days enable row level security;

create policy boss_select on boss_days for select using (user_id = (select auth.uid()));
create policy boss_insert on boss_days for insert with check (user_id = (select auth.uid()));
create policy boss_update on boss_days for update using (user_id = (select auth.uid()));
create policy boss_delete on boss_days for delete using (user_id = (select auth.uid()));

-- -------------------------------------------------
-- 8. entries (RAG-ready; embeddings nullable)
-- -------------------------------------------------
create table entries (
  id                text primary key,
  user_id           text not null,
  domain            text not null,
  entry_type        text not null,
  title             text not null,
  body              text not null,
  content_hash      text not null,
  created_at        bigint not null,
  updated_at        bigint not null,
  embedding         bytea,
  embedding_model   text,
  embedding_dim     int,
  embedded_at       bigint
);

alter table entries enable row level security;

create policy entries_select on entries for select using (user_id = (select auth.uid()));
create policy entries_insert on entries for insert with check (user_id = (select auth.uid()));
create policy entries_update on entries for update using (user_id = (select auth.uid()));
create policy entries_delete on entries for delete using (user_id = (select auth.uid()));
