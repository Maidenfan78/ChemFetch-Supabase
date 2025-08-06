# 📦 ChemFetch — Supabase Schema

This repository tracks the **database layer** for the ChemFetch platform: a cross‑platform chemical‑register solution used by the mobile scanner app and the web Client Hub.

---

## 📁 What lives in this repo?

| Folder / file                    | Purpose                                                                           |
| -------------------------------- | --------------------------------------------------------------------------------- |
| `supabase/migrations/`           | **DDL migrations** (tables, indexes, RLS policies) applied via `supabase db push` |
| `supabase/config.toml`           | Supabase CLI project settings                                                     |
| `database.types.ts` *(optional)* | Auto‑generated TypeScript types for the Supabase JS client (`supabase gen types`) |
| `README-chemfetch-supabase.md`   | You are here                                                                      |

---

## 📊 Core tables

### 1 ▪ `product`

*Master catalogue; exactly one row per recognisable chemical product.*

```sql
CREATE TABLE product (
  id          SERIAL PRIMARY KEY,
  barcode     TEXT    NOT NULL UNIQUE,          -- natural key for look‑ups
  name        TEXT    NOT NULL,
  manufacturer TEXT,
  contents_size_weight TEXT,                   -- e.g. "500 mL" or "25 kg"
  sds_url     TEXT,                            -- canonical PDF URL (optional)
  created_at  TIMESTAMPTZ DEFAULT timezone('utc', now())
);
```

---

### 2 ▪ `user_chemical_watch_list`

*Per‑user inventory + risk details.  One row **per user × per product**.*

```sql
CREATE TABLE user_chemical_watch_list (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID    REFERENCES auth.users(id)   ON DELETE CASCADE,
  product_id          INTEGER REFERENCES product(id)      ON DELETE CASCADE,

  -- inventory
  quantity_on_hand    INTEGER,
  location            TEXT,

  -- SDS snapshot (denormalised for fast filters/search)
  sds_available       BOOLEAN,
  sds_issue_date      DATE,
  hazardous_substance BOOLEAN,
  dangerous_good      BOOLEAN,
  dangerous_goods_class TEXT,
  description         TEXT,
  packing_group       TEXT,
  subsidiary_risks    TEXT,

  -- risk‑assessment metadata
  consequence         TEXT,
  likelihood          TEXT,
  risk_rating         TEXT,
  swp_required        BOOLEAN,
  comments_swp        TEXT,

  created_at          TIMESTAMPTZ DEFAULT timezone('utc', now())
);
```

#### 🔐 Row‑Level Security

`user_chemical_watch_list` enforces tenant isolation so users only see their own rows.

```sql
ALTER TABLE user_chemical_watch_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_own_rows"   ON user_chemical_watch_list
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "modify_own_rows"   ON user_chemical_watch_list
  FOR ALL    USING (auth.uid() = user_id)
              WITH CHECK (auth.uid() = user_id);
```

---

### 3 ▪ `sds_metadata` (NEW — v2025‑08‑06)

*Single source of truth for parsed SDS facts.  Exactly **one row per product** regardless of how many customers stock it.*

```sql
CREATE TABLE sds_metadata (
  product_id            INTEGER PRIMARY KEY
                         REFERENCES product(id) ON DELETE CASCADE,

  issue_date            DATE,
  hazardous_substance   BOOLEAN,
  dangerous_good        BOOLEAN,
  dangerous_goods_class TEXT,
  description           TEXT,
  packing_group         TEXT,
  subsidiary_risks      TEXT,

  raw_json              JSONB,   -- full parse for future search / AI
  created_at            TIMESTAMPTZ DEFAULT timezone('utc', now())
);
```

> **Design note:** the backend parser UPSERTs here; a trigger or nightly job copies the scalar columns onto `user_chemical_watch_list` so front‑end filters remain a single‑table query.

#### Indexes

```sql
CREATE INDEX idx_sds_metadata_issue_date            ON sds_metadata(issue_date);
CREATE INDEX idx_sds_metadata_hazardous_substance   ON sds_metadata(hazardous_substance);
CREATE INDEX idx_sds_metadata_dangerous_good        ON sds_metadata(dangerous_good);
CREATE INDEX idx_sds_metadata_raw_json              ON sds_metadata USING gin (raw_json);
```

#### RLS (disabled by default)

`ALTER TABLE sds_metadata ENABLE ROW LEVEL SECURITY;` — enable **only** if the client apps will query this table directly.  A safe read‑policy is included in `/migrations/20250806_enable_rls_sds_metadata.sql`, commented out by default.

---

## 🔄 Data‑flow overview

```text
Mobile scan → product.id ─┐
                          │    (parser writes)
                  sds_metadata  ←───────────────  Parser worker (service‑role)
                          │
           (trigger/cron) │   denormalised copy
                          ▼
             user_chemical_watch_list  ←── UI reads
```

---

## 🧪 Local setup

```bash
# 1️⃣ Initialise project (once)
supabase init

# 2️⃣ Apply all migrations to local / remote DB
supabase db push

# 3️⃣ Generate TypeScript types (optional)
supabase gen types typescript --local > database.types.ts
```

---

## 📂 Repo structure

```
chemfetch-supabase/
├── supabase/
│   ├── config.toml
│   └── migrations/
│       ├── 2025xxxx_initial_schema.sql
│       ├── 20250806_create_sds_metadata.sql
│       ├── 20250806_add_indexes_sds_metadata.sql
│       └── ...
├── database.types.ts   # optional generated types
└── README-chemfetch-supabase.md
```

---

## 🔗 Related repositories

| Repo                     | Description                               |
| ------------------------ | ----------------------------------------- |
| **chemfetch-mobile**     | Expo app for barcode scanning & SDS sync  |
| **chemfetch-client-hub** | Next.js dashboard for chemical management |
| **chemfetch-backend**    | Node + Express backend for scraping & OCR |

---

## 🪪 License

Internal use only. If this project becomes public, add an explicit license (MIT, BSL, etc.).
