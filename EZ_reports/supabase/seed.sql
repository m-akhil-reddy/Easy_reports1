-- Sample data for Healthcare Management System
-- This file contains initial data to populate the database

-- SAMPLE DATA
INSERT INTO patients (patient_id, first_name, last_name, date_of_birth, gender, blood_type, phone, email, address, emergency_contact_name, emergency_contact_phone, emergency_contact_relation) VALUES
('P-2024-001', 'John', 'Smith', '1979-05-15', 'Male', 'O+', '+1-555-123-4567', 'john.smith@email.com', '123 Main St, City, State', 'Jane Smith', '+1-555-987-6543', 'Wife'),
('P-2024-002', 'Sarah', 'Johnson', '1985-08-22', 'Female', 'A+', '+1-555-234-5678', 'sarah.johnson@email.com', '456 Oak Ave, City, State', 'Mike Johnson', '+1-555-876-5432', 'Husband'),
('P-2024-003', 'Robert', 'Brown', '1972-12-03', 'Male', 'B-', '+1-555-345-6789', 'robert.brown@email.com', '789 Pine St, City, State', 'Lisa Brown', '+1-555-765-4321', 'Daughter');

INSERT INTO vitals (patient_id, blood_pressure_systolic, blood_pressure_diastolic, heart_rate, temperature, respiratory_rate, oxygen_saturation, glucose_level, weight, height, bmi, pain_level, notes) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 120, 80, 72, 98.6, 16, 98.5, 95, 75.5, 175, 24.7, 2, 'Patient feeling well'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 118, 78, 75, 98.4, 15, 99.0, 92, 75.2, 175, 24.6, 1, 'Follow-up visit'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 130, 85, 80, 99.1, 18, 97.5, 110, 68.0, 165, 25.0, 3, 'Slight fever noted');

INSERT INTO appointments (patient_id, appointment_type, doctor_name, department, appointment_date, appointment_time, status, notes) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Follow-up', 'Dr. Johnson', 'Cardiology', CURRENT_DATE + INTERVAL '3 days', '10:00:00', 'Scheduled', 'Regular checkup'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 'Consultation', 'Dr. Smith', 'General Medicine', CURRENT_DATE + INTERVAL '1 week', '14:30:00', 'Confirmed', 'New patient consultation'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-003'), 'Emergency', 'Dr. Williams', 'Emergency', CURRENT_DATE, '09:15:00', 'In Progress', 'Chest pain evaluation');

INSERT INTO medications (patient_id, medication_name, dosage, frequency, start_date, prescribed_by, instructions) VALUES
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Lisinopril', '10mg', 'Once daily', CURRENT_DATE - INTERVAL '30 days', 'Dr. Johnson', 'Take with food'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-001'), 'Metformin', '500mg', 'Twice daily', CURRENT_DATE - INTERVAL '15 days', 'Dr. Johnson', 'Take with meals'),
((SELECT id FROM patients WHERE patient_id = 'P-2024-002'), 'Ibuprofen', '400mg', 'Every 8 hours', CURRENT_DATE - INTERVAL '5 days', 'Dr. Smith', 'Take with food to avoid stomach upset');

INSERT INTO health_tips (title, content, category, priority) VALUES
('Stay Hydrated', 'Drink at least 8 glasses of water daily to maintain proper hydration and support overall health.', 'General', 'High'),
('Regular Exercise', 'Aim for at least 30 minutes of moderate exercise most days of the week to improve cardiovascular health.', 'Exercise', 'High'),
('Medication Compliance', 'Take your medications exactly as prescribed by your healthcare provider for optimal treatment outcomes.', 'Medication', 'High'),
('Healthy Diet', 'Include plenty of fruits, vegetables, and whole grains in your diet while limiting processed foods.', 'Diet', 'Medium'),
('Regular Checkups', 'Schedule regular appointments with your healthcare provider to monitor your health status.', 'General', 'Medium');

INSERT INTO staff (staff_id, first_name, last_name, email, phone, department, role) VALUES
('S-2024-001', 'Dr. Michael', 'Johnson', 'dr.johnson@hospital.com', '+1-555-111-2222', 'Cardiology', 'Doctor'),
('S-2024-002', 'Dr. Emily', 'Smith', 'dr.smith@hospital.com', '+1-555-333-4444', 'General Medicine', 'Doctor'),
('S-2024-003', 'Nurse Sarah', 'Williams', 'nurse.williams@hospital.com', '+1-555-555-6666', 'Emergency', 'Nurse');
