# EZ Result - Healthcare Management App

A Flutter application for managing patient health records, vitals, appointments, and medications with Supabase backend integration.

## Supabase Setup

This project is configured to use Supabase as the backend service with Edge Functions for advanced functionality.

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Supabase CLI (installed via npx)
- Node.js (for Supabase CLI)

### Database Schema

The application uses a comprehensive healthcare database schema with the following main tables:

- **patients**: Patient information and demographics
- **vitals**: Vital signs recordings (blood pressure, heart rate, temperature, etc.)
- **appointments**: Medical appointments and scheduling
- **medications**: Patient medications and prescriptions
- **medication_schedule**: Medication reminder schedules
- **notifications**: System notifications and alerts
- **health_tips**: Health education content
- **staff**: Healthcare staff information

### Edge Functions

The project includes three Edge Functions for enhanced functionality:

1. **patient-management**: CRUD operations for patient data
2. **vital-alerts**: Monitors vital signs and creates alerts for abnormal values
3. **medication-reminders**: Manages medication schedules and reminders

### Setup Instructions

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Initialize Supabase project** (already done):
   ```bash
   npx supabase init
   ```

3. **Start local Supabase development environment**:
   ```bash
   npx supabase start
   ```

4. **Apply database migrations**:
   ```bash
   npx supabase db reset
   ```

5. **Deploy Edge Functions** (when ready for production):
   ```bash
   npx supabase functions deploy patient-management
   npx supabase functions deploy vital-alerts
   npx supabase functions deploy medication-reminders
   ```

### Configuration

Update the Supabase credentials in `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  // ... other configurations
}
```

### Local Development

1. **Start Supabase locally**:
   ```bash
   npx supabase start
   ```

2. **Serve Edge Functions locally**:
   ```bash
   npx supabase functions serve
   ```

3. **Run Flutter app**:
   ```bash
   flutter run
   ```

### Database Features

- **Row Level Security (RLS)**: Enabled on all tables
- **Real-time subscriptions**: For live updates
- **Database functions**: BMI calculation, latest vitals retrieval
- **Views**: Patient summary, upcoming appointments, medication reminders
- **Triggers**: Automatic timestamp updates

### API Endpoints

#### Patient Management Function
- `GET /patients` - Get all patients
- `GET /patient/{id}` - Get specific patient
- `POST /patients` - Create new patient
- `PUT /patient/{id}` - Update patient
- `DELETE /patient/{id}` - Deactivate patient

#### Vital Alerts Function
- `GET /check-vitals` - Check for abnormal vital signs
- `POST /create-alert` - Create vital alert notification

#### Medication Reminders Function
- `GET /today-reminders` - Get today's medication reminders
- `GET /upcoming-reminders` - Get upcoming reminders
- `POST /mark-taken` - Mark medication as taken
- `POST /create-reminder` - Create medication reminder
- `POST /generate-schedule` - Generate medication schedule

### Real-time Features

The app supports real-time updates for:
- Patient data changes
- Vital signs updates
- New notifications
- Medication schedule updates

### Security

- All tables have Row Level Security enabled
- Anonymous access policies configured for development
- Edge Functions include CORS headers
- Input validation and error handling

### Production Deployment

1. **Deploy to Supabase Cloud**:
   ```bash
   npx supabase link --project-ref YOUR_PROJECT_REF
   npx supabase db push
   npx supabase functions deploy
   ```

2. **Update Flutter app configuration** with production URLs

3. **Configure authentication** (if needed)

### Troubleshooting

- Check Supabase logs: `npx supabase logs`
- Verify database connection in Supabase dashboard
- Check Edge Function logs in Supabase dashboard
- Ensure proper CORS configuration for web deployment

### Sample Data

The database includes sample data for testing:
- 3 sample patients
- Vital signs records
- Appointments
- Medications
- Health tips
- Staff members

This provides a complete testing environment for development and demonstration purposes.
