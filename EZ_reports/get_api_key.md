# Get your Supabase API Key
# Follow these steps to get your actual API key:

# 1. Go to your Supabase Dashboard
# URL: https://supabase.com/dashboard/project/wfoupmxfjzlirakcorhi

# 2. Navigate to Settings > API
# - Click on "Settings" in the left sidebar
# - Click on "API" in the settings menu

# 3. Copy your anon/public key
# - Look for "Project API keys" section
# - Copy the "anon" key (it starts with "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")

# 4. Replace the placeholder in main.dart
# - Open lib/main.dart
# - Find line 17 with: anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indmb3VwbXhmanpsaXJha2NvcmhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzQ4MDAsImV4cCI6MjA1MDU1MDgwMH0.YourAnonKey'
# - Replace 'YourAnonKey' with your actual anon key

# 5. Test the connection
# - Run: flutter run
# - Try adding vitals to see if it connects to Supabase

# Alternative: Use Supabase CLI to get the key
# If you have Supabase CLI installed:
# supabase status --project-ref wfoupmxfjzlirakcorhi
