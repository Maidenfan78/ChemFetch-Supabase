# 📦 ChemFetch Supabase Schema

This repository contains the SQL schema, migrations, and database types for the ChemFetch platform — a cross-platform chemical management system.

## 📁 Repository Purpose

This repo manages:

- Database schema (tables, indexes, constraints)
- SQL migrations using the Supabase CLI
- Row-Level Security (RLS) policies
- Optional TypeScript types for Supabase client usage

It supports both the **mobile app** (`chemfetch-mobile`) and the **web client dashboard** (`chemfetch-client-hub`).

---

## 📊 Tables

### `product`

The master catalog of recognized chemical products across all users.

```sql
CREATE TABLE product (
  id SERIAL PRIMARY KEY,
  barcode TEXT NOT NULL,
  name TEXT,
  manufacturer TEXT,
  contents_size_weight TEXT,
  sds_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  CONSTRAINT unique_barcode UNIQUE (barcode)
);
user_chemical_watch_list
Tracks product usage per user (inventory, SDS status, risk info, etc.).

sql
Copy
Edit
CREATE TABLE user_chemical_watch_list (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES product(id) ON DELETE CASCADE,
  quantity_on_hand INTEGER,
  location TEXT,
  sds_available BOOLEAN,
  sds_issue_date DATE,
  hazardous_substance BOOLEAN,
  dangerous_good BOOLEAN,
  dangerous_goods_class TEXT,
  description TEXT,
  packing_group TEXT,
  subsidiary_risks TEXT,
  consequence TEXT,
  likelihood TEXT,
  risk_rating TEXT,
  swp_required BOOLEAN,
  comments_swp TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);
🔐 Row-Level Security (RLS)
RLS is enabled for user_chemical_watch_list to ensure users can only access their own chemical records.

sql
Copy
Edit
-- Enable RLS
ALTER TABLE user_chemical_watch_list ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own rows
CREATE POLICY "select_own_rows"
  ON user_chemical_watch_list
  FOR SELECT
  USING (auth.uid() = user_id);

-- Allow users to insert/update/delete their own rows
CREATE POLICY "modify_own_rows"
  ON user_chemical_watch_list
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Optional: allow service_role to bypass RLS
CREATE POLICY "admin_access"
  ON user_chemical_watch_list
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
🧪 Setup Instructions
bash
Copy
Edit
# 1. Initialize Supabase project
supabase init

# 2. Push schema to remote DB
supabase db push

# 3. Generate TypeScript types (optional)
supabase gen types typescript --local > database.types.ts
📂 Folder Structure
pgsql
Copy
Edit
chemfetch-supabase/
├── supabase/
│   ├── config.toml
│   └── migrations/
│       ├── initial_schema.sql
│       └── rls_policies.sql
├── database.types.ts            # Optional TS type mapping
└── README.md
📎 Related Repos
Repo Name	Description
chemfetch-mobile	Expo app for barcode scanning and SDS sync
chemfetch-client-hub	Next.js dashboard for chemical management
chemfetch-backend	Node.js + Express backend for OCR, scraping

🪪 License
Internal use only. If this becomes public, add an appropriate license (e.g. MIT or BSL).

yaml
Copy
Edit

---
