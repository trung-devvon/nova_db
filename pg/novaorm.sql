-- UUID generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'deal_status') THEN
    CREATE TYPE deal_status AS ENUM ('open','won','lost');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_type') THEN
    CREATE TYPE activity_type AS ENUM ('task','call','email','meeting');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_type') THEN
    CREATE TYPE entity_type AS ENUM ('deal','contact','company');
  END IF;
END$$;

-- Organizations
CREATE TABLE IF NOT EXISTS organizations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  domain      text UNIQUE,
  plan        text NOT NULL DEFAULT 'free',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email         text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  name          text NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Org members (RBAC đơn giản bằng role_name)
CREATE TABLE IF NOT EXISTS org_members (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id     uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
  role_name  text NOT NULL DEFAULT 'SALES', -- OWNER/ADMIN/MANAGER/SALES/READONLY
  status     text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (org_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_org_members_org_role ON org_members(org_id, role_name);

-- Companies
CREATE TABLE IF NOT EXISTS companies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  name        text NOT NULL,
  domain      text,
  phone       text,
  address     text,
  owner_id    uuid REFERENCES users(id),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz,
  version     int  NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_companies_org_name  ON companies(org_id, name);
CREATE INDEX IF NOT EXISTS idx_companies_org_owner ON companies(org_id, owner_id);

-- Contacts (đã thống nhất dùng name thay vì first/last)
CREATE TABLE IF NOT EXISTS contacts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  company_id  uuid REFERENCES companies(id),
  name        text NOT NULL,
  email       text,
  phone       text,
  owner_id    uuid REFERENCES users(id),
  tags        text[] NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz,
  version     int NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_contacts_org_company ON contacts(org_id, company_id);
CREATE INDEX IF NOT EXISTS idx_contacts_org_owner   ON contacts(org_id, owner_id);

-- Pipelines & Stages
CREATE TABLE IF NOT EXISTS pipelines (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  name        text NOT NULL,
  is_default  boolean NOT NULL DEFAULT false,
  UNIQUE(org_id, name)
);

CREATE TABLE IF NOT EXISTS stages (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       uuid NOT NULL REFERENCES organizations(id),
  pipeline_id  uuid NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
  name         text NOT NULL,
  order_no     int  NOT NULL,
  UNIQUE (pipeline_id, order_no)
);

-- Deals
CREATE TABLE IF NOT EXISTS deals (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id              uuid NOT NULL REFERENCES organizations(id),
  title               text NOT NULL,
  company_id          uuid REFERENCES companies(id),
  contact_id          uuid REFERENCES contacts(id),
  owner_id            uuid REFERENCES users(id),
  amount              numeric(14,2) NOT NULL DEFAULT 0,
  currency            text NOT NULL DEFAULT 'VND',
  pipeline_id         uuid NOT NULL REFERENCES pipelines(id),
  stage_id            uuid NOT NULL REFERENCES stages(id),
  probability         int NOT NULL DEFAULT 0,
  expected_close_date date,
  status              deal_status NOT NULL DEFAULT 'open',
  reason_lost         text,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  deleted_at          timestamptz,
  version             int NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_deals_stage     ON deals(org_id, pipeline_id, stage_id);
CREATE INDEX IF NOT EXISTS idx_deals_owner_sts ON deals(org_id, owner_id, status);
CREATE INDEX IF NOT EXISTS idx_deals_expected  ON deals(org_id, expected_close_date);

-- Activities
CREATE TABLE IF NOT EXISTS activities (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  deal_id     uuid REFERENCES deals(id),
  contact_id  uuid REFERENCES contacts(id),
  company_id  uuid REFERENCES companies(id),
  type        activity_type NOT NULL,
  subject     text,
  description text,
  due_at      timestamptz,
  assignee_id uuid REFERENCES users(id),
  done        boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz
);
CREATE INDEX IF NOT EXISTS idx_acts_assign ON activities(org_id, assignee_id, done, due_at);
CREATE INDEX IF NOT EXISTS idx_acts_deal   ON activities(org_id, deal_id);
CREATE INDEX IF NOT EXISTS idx_acts_contact ON activities(org_id, contact_id);

-- Notes (polymorphic)
CREATE TABLE IF NOT EXISTS notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  entity_type entity_type NOT NULL,
  entity_id   uuid NOT NULL,
  author_id   uuid NOT NULL REFERENCES users(id),
  body        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notes_entity ON notes(org_id, entity_type, entity_id, created_at);

-- Attachments (polymorphic)
CREATE TABLE IF NOT EXISTS attachments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organizations(id),
  entity_type entity_type NOT NULL,
  entity_id   uuid NOT NULL,
  storage_key text NOT NULL,
  file_name   text NOT NULL,
  mime        text NOT NULL,
  size        int  NOT NULL,
  uploader_id uuid NOT NULL REFERENCES users(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_att_entity ON attachments(org_id, entity_type, entity_id);

-- Audit logs (gọn, phục vụ trace)
CREATE TABLE IF NOT EXISTS audit_logs (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id    uuid NOT NULL REFERENCES organizations(id),
  actor_id  uuid REFERENCES users(id),
  entity    text NOT NULL,
  entity_id uuid NOT NULL,
  action    text NOT NULL,
  before    jsonb,
  after     jsonb,
  at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(org_id, entity, entity_id, at DESC);






-- Appendix B
-- Extensions cho search/index nâng cao
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- COMPANIES: FTS trên name + domain
CREATE INDEX IF NOT EXISTS companies_search_tsv_idx
  ON companies USING GIN (
    to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(domain,''))
  );

-- CONTACTS: FTS & TRGM
-- Nếu trước đây có index cũ dùng first_name/last_name thì không có ở schema mới, bỏ qua.
CREATE INDEX IF NOT EXISTS contacts_owner_idx
  ON contacts(org_id, owner_id);

CREATE INDEX IF NOT EXISTS contacts_company_idx
  ON contacts(org_id, company_id);

CREATE INDEX IF NOT EXISTS contacts_tags_gin
  ON contacts USING GIN (tags);

CREATE INDEX IF NOT EXISTS contacts_email_trgm
  ON contacts USING GIN (email gin_trgm_ops);

CREATE INDEX IF NOT EXISTS contacts_phone_trgm
  ON contacts USING GIN (phone gin_trgm_ops);

CREATE INDEX IF NOT EXISTS contacts_tsv_idx
  ON contacts USING GIN (
    to_tsvector('simple', coalesce(name,'') || ' ' || coalesce(email,'') || ' ' || coalesce(phone,''))
  );

-- Unique email theo org, chỉ áp cho bản ghi chưa xoá
CREATE UNIQUE INDEX IF NOT EXISTS contacts_unique_email_per_org_active
  ON contacts (org_id, lower(email))
  WHERE email IS NOT NULL AND deleted_at IS NULL;

-- ACTIVITIES: BRIN cho time-series lớn
CREATE INDEX IF NOT EXISTS activities_created_brin
  ON activities USING BRIN (created_at);

-- DEALS: (đã có btree cơ bản ở bước 1; đủ)
-- AUDIT LOGS: (đã có btree ở bước 1; đủ)

-- MATERIALIZED VIEW: deal metrics theo ngày/pipeline/stage
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_deal_metrics_daily AS
SELECT
  org_id,
  date_trunc('day', created_at)::date AS day,
  pipeline_id,
  stage_id,
  COUNT(*)                                                AS created_cnt,
  SUM(CASE WHEN status = 'won'  THEN amount ELSE 0 END)  AS won_amount,
  SUM(CASE WHEN status = 'lost' THEN amount ELSE 0 END)  AS lost_amount,
  COUNT(*) FILTER (WHERE status = 'open')                 AS open_cnt
FROM deals
GROUP BY 1,2,3,4;

-- Unique index để REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS mv_deal_metrics_daily_uq
  ON mv_deal_metrics_daily (org_id, day, pipeline_id, stage_id);

CREATE INDEX IF NOT EXISTS mv_deal_metrics_daily_day_desc
  ON mv_deal_metrics_daily (org_id, day DESC);

CREATE INDEX IF NOT EXISTS mv_deal_metrics_daily_pipeline_day
  ON mv_deal_metrics_daily (org_id, pipeline_id, day);

-- Hàm helper để cron refresh
CREATE OR REPLACE FUNCTION refresh_mv_deal_metrics_daily()
RETURNS void LANGUAGE sql AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_deal_metrics_daily;
$$;
