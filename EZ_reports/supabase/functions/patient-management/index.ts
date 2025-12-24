import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create a Supabase client with the Auth context of the function
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    const { method } = req
    const url = new URL(req.url)
    const path = url.pathname.split('/').pop()

    switch (method) {
      case 'GET':
        if (path === 'patients') {
          // Get all patients
          const { data: patients, error } = await supabaseClient
            .from('patients')
            .select('*')
            .eq('is_active', true)
            .order('created_at', { ascending: false })

          if (error) throw error

          return new Response(
            JSON.stringify({ patients }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        } else if (path?.startsWith('patient/')) {
          // Get specific patient by ID
          const patientId = path.split('/')[1]
          const { data: patient, error } = await supabaseClient
            .from('patients')
            .select('*')
            .eq('id', patientId)
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ patient }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        } else if (path === 'patient-summary') {
          // Get patient summary view
          const { data: summary, error } = await supabaseClient
            .from('patient_summary')
            .select('*')

          if (error) throw error

          return new Response(
            JSON.stringify({ summary }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }
        break

      case 'POST':
        if (path === 'patients') {
          // Create new patient
          const body = await req.json()
          const { data: patient, error } = await supabaseClient
            .from('patients')
            .insert([body])
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ patient }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 201,
            }
          )
        }
        break

      case 'PUT':
        if (path?.startsWith('patient/')) {
          // Update patient
          const patientId = path.split('/')[1]
          const body = await req.json()
          const { data: patient, error } = await supabaseClient
            .from('patients')
            .update(body)
            .eq('id', patientId)
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ patient }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }
        break

      case 'DELETE':
        if (path?.startsWith('patient/')) {
          // Soft delete patient (set is_active to false)
          const patientId = path.split('/')[1]
          const { data: patient, error } = await supabaseClient
            .from('patients')
            .update({ is_active: false })
            .eq('id', patientId)
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ message: 'Patient deactivated successfully' }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }
        break

      default:
        return new Response(
          JSON.stringify({ error: 'Method not allowed' }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 405,
          }
        )
    }

    return new Response(
      JSON.stringify({ error: 'Endpoint not found' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})