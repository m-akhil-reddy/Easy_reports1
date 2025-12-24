-- Supabase Database Schema for Patient Vitals
-- Run this SQL in your Supabase SQL Editor

-- Create the patient_vitals table
CREATE TABLE IF NOT EXISTS patient_vitals (
  id BIGSERIAL PRIMARY KEY,
  patient_id TEXT NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  vitals JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create an index on patient_id for faster queries
CREATE INDEX IF NOT EXISTS idx_patient_vitals_patient_id ON patient_vitals(patient_id);

-- Create an index on recorded_at for faster sorting
CREATE INDEX IF NOT EXISTS idx_patient_vitals_recorded_at ON patient_vitals(recorded_at);

-- Enable Row Level Security (RLS)
ALTER TABLE patient_vitals ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows all operations (adjust as needed for your security requirements)
CREATE POLICY "Allow all operations on patient_vitals" ON patient_vitals
  FOR ALL USING (true);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update updated_at
CREATE TRIGGER update_patient_vitals_updated_at 
    BEFORE UPDATE ON patient_vitals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing
INSERT INTO patient_vitals (patient_id, recorded_at, vitals) VALUES
('P-2024-001', NOW() - INTERVAL '1 hour', '{"Blood Pressure": "120/80", "Heart Rate": "72", "Temperature": "98.6", "Glucose": "95"}'),
('P-2024-001', NOW() - INTERVAL '2 hours', '{"Blood Pressure": "118/78", "Heart Rate": "75", "Temperature": "98.4", "Oxygen Saturation": "98"}'),
('P-2024-002', NOW() - INTERVAL '30 minutes', '{"Blood Pressure": "130/85", "Heart Rate": "80", "Temperature": "99.1", "Respiratory Rate": "16"}');

-- Create a view for easy querying of latest vitals per patient
CREATE OR REPLACE VIEW latest_patient_vitals AS
SELECT DISTINCT ON (patient_id) 
    patient_id,
    recorded_at,
    vitals,
    created_at
FROM patient_vitals
ORDER BY patient_id, recorded_at DESC;

-- Grant necessary permissions
GRANT ALL ON patient_vitals TO anon;
GRANT ALL ON latest_patient_vitals TO anon;
GRANT USAGE ON SEQUENCE patient_vitals_id_seq TO anon;
