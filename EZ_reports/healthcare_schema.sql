-- =====================================================
-- Healthcare Management System Database Schema
-- Project: EZ Result - Patient Health Management App
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. PATIENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id TEXT UNIQUE NOT NULL, -- Custom patient ID like P-2024-001
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_type TEXT CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone TEXT,
    email TEXT,
    address TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    emergency_contact_relation TEXT,
    medical_history TEXT,
    allergies TEXT,
    medications TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- =====================================================
-- 2. VITALS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vitals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    recorded_by TEXT, -- Staff member or system
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    heart_rate INTEGER,
    temperature DECIMAL(4,1), -- Fahrenheit
    temperature_celsius DECIMAL(4,1), -- Celsius
    respiratory_rate INTEGER,
    oxygen_saturation DECIMAL(5,2), -- Percentage
    glucose_level DECIMAL(5,2), -- mg/dL
    weight DECIMAL(5,2), -- kg
    height DECIMAL(5,2), -- cm
    bmi DECIMAL(4,1),
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. MEDICAL REPORTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS medical_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL, -- 'Lab Report', 'Imaging', 'Cardiology', etc.
    report_name TEXT NOT NULL,
    report_date DATE NOT NULL,
    file_url TEXT, -- URL to the report file
    file_type TEXT, -- 'PDF', 'JPG', 'PNG', etc.
    file_size BIGINT, -- File size in bytes
    description TEXT,
    findings TEXT,
    recommendations TEXT,
    doctor_name TEXT,
    lab_name TEXT,
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Archived', 'Deleted')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. APPOINTMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_type TEXT NOT NULL, -- 'Consultation', 'Follow-up', 'Emergency', etc.
    doctor_name TEXT NOT NULL,
    department TEXT,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status TEXT DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show')),
    notes TEXT,
    diagnosis TEXT,
    prescription TEXT,
    follow_up_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 5. MEDICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    medication_name TEXT NOT NULL,
    dosage TEXT NOT NULL, -- e.g., "500mg", "2 tablets"
    frequency TEXT NOT NULL, -- e.g., "Twice daily", "Every 8 hours"
    start_date DATE NOT NULL,
    end_date DATE,
    prescribed_by TEXT,
    instructions TEXT,
    side_effects TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 6. MEDICATION_SCHEDULE TABLE (For tracking daily doses)
-- =====================================================
CREATE TABLE IF NOT EXISTS medication_schedule (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
    scheduled_time TIME NOT NULL,
    taken_at TIMESTAMPTZ,
    taken BOOLEAN DEFAULT false,
    notes TEXT,
    scheduled_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 7. HEALTH_TIPS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS health_tips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL, -- 'General', 'Diet', 'Exercise', 'Medication', etc.
    priority TEXT DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 8. PATIENT_HEALTH_TIPS TABLE (Many-to-many relationship)
-- =====================================================
CREATE TABLE IF NOT EXISTS patient_health_tips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    health_tip_id UUID NOT NULL REFERENCES health_tips(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    is_read BOOLEAN DEFAULT false,
    UNIQUE(patient_id, health_tip_id)
);

-- =====================================================
-- 9. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'Appointment', 'Medication', 'Vital', 'General'
    priority TEXT DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High', 'Urgent')),
    is_read BOOLEAN DEFAULT false,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 10. STAFF/USERS TABLE (For healthcare providers)
-- =====================================================
CREATE TABLE IF NOT EXISTS staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    department TEXT,
    role TEXT NOT NULL, -- 'Doctor', 'Nurse', 'Admin', 'Lab Technician'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Patient indexes
CREATE INDEX IF NOT EXISTS idx_patients_patient_id ON patients(patient_id);
CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(first_name, last_name);
CREATE INDEX IF NOT EXISTS idx_patients_email ON patients(email);
CREATE INDEX IF NOT EXISTS idx_patients_active ON patients(is_active);

-- Vitals indexes
CREATE INDEX IF NOT EXISTS idx_vitals_patient_id ON vitals(patient_id);
CREATE INDEX IF NOT EXISTS idx_vitals_recorded_at ON vitals(recorded_at);
CREATE INDEX IF NOT EXISTS idx_vitals_patient_recorded ON vitals(patient_id, recorded_at);

-- Reports indexes
CREATE INDEX IF NOT EXISTS idx_reports_patient_id ON medical_reports(patient_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON medical_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_date ON medical_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_reports_status ON medical_reports(status);

-- Appointments indexes
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor ON appointments(doctor_name);

-- Medications indexes
CREATE INDEX IF NOT EXISTS idx_medications_patient_id ON medications(patient_id);
CREATE INDEX IF NOT EXISTS idx_medications_active ON medications(is_active);
CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(medication_name);

-- Medication schedule indexes
CREATE INDEX IF NOT EXISTS idx_med_schedule_medication_id ON medication_schedule(medication_id);
CREATE INDEX IF NOT EXISTS idx_med_schedule_date ON medication_schedule(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_med_schedule_taken ON medication_schedule(taken);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_tips ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_health_tips ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- Create policies for anonymous access (adjust based on your security requirements)
CREATE POLICY "Allow all operations on patients" ON patients FOR ALL USING (true);
CREATE POLICY "Allow all operations on vitals" ON vitals FOR ALL USING (true);
CREATE POLICY "Allow all operations on medical_reports" ON medical_reports FOR ALL USING (true);
CREATE POLICY "Allow all operations on appointments" ON appointments FOR ALL USING (true);
CREATE POLICY "Allow all operations on medications" ON medications FOR ALL USING (true);
CREATE POLICY "Allow all operations on medication_schedule" ON medication_schedule FOR ALL USING (true);
CREATE POLICY "Allow all operations on health_tips" ON health_tips FOR ALL USING (true);
CREATE POLICY "Allow all operations on patient_health_tips" ON patient_health_tips FOR ALL USING (true);
CREATE POLICY "Allow all operations on notifications" ON notifications FOR ALL USING (true);
CREATE POLICY "Allow all operations on staff" ON staff FOR ALL USING (true);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vitals_updated_at BEFORE UPDATE ON vitals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medical_reports_updated_at BEFORE UPDATE ON medical_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_medications_updated_at BEFORE UPDATE ON medications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_health_tips_updated_at BEFORE UPDATE ON health_tips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON staff FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate BMI
CREATE OR REPLACE FUNCTION calculate_bmi(weight_kg DECIMAL, height_cm DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    IF weight_kg IS NULL OR height_cm IS NULL OR height_cm = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND((weight_kg / POWER(height_cm / 100, 2))::DECIMAL, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to get latest vitals for a patient
CREATE OR REPLACE FUNCTION get_latest_vitals(patient_uuid UUID)
RETURNS TABLE (
    id UUID,
    patient_id UUID,
    recorded_at TIMESTAMPTZ,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    heart_rate INTEGER,
    temperature DECIMAL,
    respiratory_rate INTEGER,
    oxygen_saturation DECIMAL,
    glucose_level DECIMAL,
    weight DECIMAL,
    height DECIMAL,
    bmi DECIMAL,
    pain_level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.patient_id,
        v.recorded_at,
        v.blood_pressure_systolic,
        v.blood_pressure_diastolic,
        v.heart_rate,
        v.temperature,
        v.respiratory_rate,
        v.oxygen_saturation,
        v.glucose_level,
        v.weight,
        v.height,
        v.bmi,
        v.pain_level
    FROM vitals v
    WHERE v.patient_id = patient_uuid
    ORDER BY v.recorded_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for patient summary
CREATE OR REPLACE VIEW patient_summary AS
SELECT 
    p.id,
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    p.blood_type,
    p.phone,
    p.email,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    COUNT(DISTINCT v.id) as total_vitals_recorded,
    COUNT(DISTINCT a.id) as total_appointments,
    COUNT(DISTINCT m.id) as total_medications,
    MAX(v.recorded_at) as last_vital_recorded,
    MAX(a.appointment_date) as last_appointment
FROM patients p
LEFT JOIN vitals v ON p.id = v.patient_id
LEFT JOIN appointments a ON p.id = a.patient_id
LEFT JOIN medications m ON p.id = m.patient_id
WHERE p.is_active = true
GROUP BY p.id, p.patient_id, p.first_name, p.last_name, p.date_of_birth, p.gender, p.blood_type, p.phone, p.email;

-- View for upcoming appointments
CREATE OR REPLACE VIEW upcoming_appointments AS
SELECT 
    a.id,
    a.patient_id,
    p.first_name,
    p.last_name,
    p.patient_id as patient_number,
    a.appointment_type,
    a.doctor_name,
    a.department,
    a.appointment_date,
    a.appointment_time,
    a.status,
    a.notes
FROM appointments a
JOIN patients p ON a.patient_id = p.id
WHERE a.appointment_date >= CURRENT_DATE
    AND a.status IN ('Scheduled', 'Confirmed')
ORDER BY a.appointment_date, a.appointment_time;

-- View for medication reminders
CREATE OR REPLACE VIEW medication_reminders AS
SELECT 
    ms.id,
    ms.medication_id,
    m.patient_id,
    p.first_name,
    p.last_name,
    p.patient_id as patient_number,
    m.medication_name,
    m.dosage,
    m.frequency,
    ms.scheduled_time,
    ms.scheduled_date,
    ms.taken,
    ms.taken_at
FROM medication_schedule ms
JOIN medications m ON ms.medication_id = m.id
JOIN patients p ON m.patient_id = p.id
WHERE ms.scheduled_date = CURRENT_DATE
    AND ms.taken = false
    AND m.is_active = true
ORDER BY ms.scheduled_time;

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Insert sample patients
INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, gender, blood_type, phone, email, address, emergency_contact_name, emergency_contact_phone, emergency_contact_relation) VALUES
('P-2024-001', 'John', 'Smith', '1979-05-15', 'Male', 'O+', '+1-555-123-4567', 'john.smith@email.com', '123 Main St, City, State', 'Jane Smith', '+1-555-987-6543', 'Wife'),
('P-2024-002', 'Sarah', 'Johnson', '1985-08-22', 'Female', 'A+', '+1-555-234-5678', 'sarah.johnson@email.com', '456 Oak Ave, City, State', 'Mike Johnson', '+1-555-876-5432', 'Husband'),
('P-2024-003', 'Robert', 'Brown', '1972-12-03', 'Male', 'B-', '+1-555-345-6789', 'robert.brown@email.com', '789 Pine St, City, State', 'Lisa Brown', '+1-555-765-4321', 'Daughter');

-- Insert sample vitals
INSERT INTO vitals (patient_id, blood_pressure_systolic, blood_pressure_diastolic, heart_rate, temperature, respiratory_rate, oxygen_saturation, glucose_level, weight, height, bmi, pain_level, notes) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 120, 80, 72, 98.6, 16, 98.5, 95, 75.5, 175, 24.7, 2, 'Patient feeling well'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 118, 78, 75, 98.4, 15, 99.0, 92, 75.2, 175, 24.6, 1, 'Follow-up visit'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 130, 85, 80, 99.1, 18, 97.5, 110, 68.0, 165, 25.0, 3, 'Slight fever noted');

-- Insert sample appointments
INSERT INTO appointments (patient_id, appointment_type, doctor_name, department, appointment_date, appointment_time, status, notes) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Follow-up', 'Dr. Johnson', 'Cardiology', CURRENT_DATE + INTERVAL '3 days', '10:00:00', 'Scheduled', 'Regular checkup'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 'Consultation', 'Dr. Smith', 'General Medicine', CURRENT_DATE + INTERVAL '1 week', '14:30:00', 'Confirmed', 'New patient consultation'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-003'), 'Emergency', 'Dr. Williams', 'Emergency', CURRENT_DATE, '09:15:00', 'In Progress', 'Chest pain evaluation');

-- Insert sample medications
INSERT INTO medications (patient_id, medication_name, dosage, frequency, start_date, prescribed_by, instructions) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Lisinopril', '10mg', 'Once daily', CURRENT_DATE - INTERVAL '30 days', 'Dr. Johnson', 'Take with food'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Metformin', '500mg', 'Twice daily', CURRENT_DATE - INTERVAL '15 days', 'Dr. Johnson', 'Take with meals'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 'Ibuprofen', '400mg', 'Every 8 hours', CURRENT_DATE - INTERVAL '5 days', 'Dr. Smith', 'Take with food to avoid stomach upset');

-- Insert sample health tips
INSERT INTO health_tips (title, content, category, priority) VALUES
('Stay Hydrated', 'Drink at least 8 glasses of water daily to maintain proper hydration and support overall health.', 'General', 'High'),
('Regular Exercise', 'Aim for at least 30 minutes of moderate exercise most days of the week to improve cardiovascular health.', 'Exercise', 'High'),
('Medication Compliance', 'Take your medications exactly as prescribed by your healthcare provider for optimal treatment outcomes.', 'Medication', 'High'),
('Healthy Diet', 'Include plenty of fruits, vegetables, and whole grains in your diet while limiting processed foods.', 'Diet', 'Medium'),
('Regular Checkups', 'Schedule regular appointments with your healthcare provider to monitor your health status.', 'General', 'Medium');

-- Insert sample staff
INSERT INTO staff (staff_id, first_name, last_name, email, phone, department, role) VALUES
('S-2024-001', 'Dr. Michael', 'Johnson', 'dr.johnson@hospital.com', '+1-555-111-2222', 'Cardiology', 'Doctor'),
('S-2024-002', 'Dr. Emily', 'Smith', 'dr.smith@hospital.com', '+1-555-333-4444', 'General Medicine', 'Doctor'),
('S-2024-003', 'Nurse Sarah', 'Williams', 'nurse.williams@hospital.com', '+1-555-555-6666', 'Emergency', 'Nurse');

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to anonymous users
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Grant permissions on specific views
GRANT ALL ON patient_summary TO anon;
GRANT ALL ON upcoming_appointments TO anon;
GRANT ALL ON medication_reminders TO anon;

-- =====================================================
-- SCHEMA COMPLETE
-- =====================================================

-- This schema provides a comprehensive foundation for your healthcare management app
-- with proper relationships, indexes, security policies, and sample data.
