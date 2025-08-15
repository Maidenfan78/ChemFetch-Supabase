-- Add vendor field to sds_metadata table
-- This matches the parse_sds.py script output which includes vendor information

ALTER TABLE public.sds_metadata 
ADD COLUMN vendor TEXT;