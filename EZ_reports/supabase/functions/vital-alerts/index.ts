import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Vital sign normal ranges
const VITAL_RANGES = {
  blood_pressure_systolic: { min: 90, max: 140 },
  blood_pressure_diastolic: { min: 60, max: 90 },
  heart_rate: { min: 60, max: 100 },
  temperature: { min: 97.0, max: 99.5 },
  respiratory_rate: { min: 12, max: 20 },
  oxygen_saturation: { min: 95, max: 100 },
  glucose_level: { min: 70, max: 140 },
  bmi: { min: 18.5, max: 24.9 }
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
        if (path === 'check-vitals') {
          // Check vitals for abnormal values and create alerts
          const { data: vitals, error } = await supabaseClient
            .from('vitals')
            .select(`
              *,
              patients (
                id,
                first_name,
                last_name,
                patient_id,
                phone,
                email
              )
            `)
            .gte('recorded_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()) // Last 24 hours
            .order('recorded_at', { ascending: false })

          if (error) throw error

          const alerts = []
          
          for (const vital of vitals) {
            const patient = vital.patients
            const alertsForVital = []

            // Check each vital sign
            if (vital.blood_pressure_systolic) {
              if (vital.blood_pressure_systolic < VITAL_RANGES.blood_pressure_systolic.min || 
                  vital.blood_pressure_systolic > VITAL_RANGES.blood_pressure_systolic.max) {
                alertsForVital.push({
                  type: 'blood_pressure',
                  value: `${vital.blood_pressure_systolic}/${vital.blood_pressure_diastolic}`,
                  status: vital.blood_pressure_systolic > VITAL_RANGES.blood_pressure_systolic.max ? 'high' : 'low',
                  message: `Blood pressure ${vital.blood_pressure_systolic > VITAL_RANGES.blood_pressure_systolic.max ? 'elevated' : 'low'} (${vital.blood_pressure_systolic}/${vital.blood_pressure_diastolic})`
                })
              }
            }

            if (vital.heart_rate) {
              if (vital.heart_rate < VITAL_RANGES.heart_rate.min || 
                  vital.heart_rate > VITAL_RANGES.heart_rate.max) {
                alertsForVital.push({
                  type: 'heart_rate',
                  value: vital.heart_rate,
                  status: vital.heart_rate > VITAL_RANGES.heart_rate.max ? 'high' : 'low',
                  message: `Heart rate ${vital.heart_rate > VITAL_RANGES.heart_rate.max ? 'elevated' : 'low'} (${vital.heart_rate} bpm)`
                })
              }
            }

            if (vital.temperature) {
              if (vital.temperature < VITAL_RANGES.temperature.min || 
                  vital.temperature > VITAL_RANGES.temperature.max) {
                alertsForVital.push({
                  type: 'temperature',
                  value: vital.temperature,
                  status: vital.temperature > VITAL_RANGES.temperature.max ? 'high' : 'low',
                  message: `Temperature ${vital.temperature > VITAL_RANGES.temperature.max ? 'elevated' : 'low'} (${vital.temperature}°F)`
                })
              }
            }

            if (vital.oxygen_saturation) {
              if (vital.oxygen_saturation < VITAL_RANGES.oxygen_saturation.min) {
                alertsForVital.push({
                  type: 'oxygen_saturation',
                  value: vital.oxygen_saturation,
                  status: 'low',
                  message: `Low oxygen saturation (${vital.oxygen_saturation}%)`
                })
              }
            }

            if (vital.glucose_level) {
              if (vital.glucose_level < VITAL_RANGES.glucose_level.min || 
                  vital.glucose_level > VITAL_RANGES.glucose_level.max) {
                alertsForVital.push({
                  type: 'glucose',
                  value: vital.glucose_level,
                  status: vital.glucose_level > VITAL_RANGES.glucose_level.max ? 'high' : 'low',
                  message: `Blood glucose ${vital.glucose_level > VITAL_RANGES.glucose_level.max ? 'elevated' : 'low'} (${vital.glucose_level} mg/dL)`
                })
              }
            }

            if (alertsForVital.length > 0) {
              alerts.push({
                patient_id: patient.id,
                patient_name: `${patient.first_name} ${patient.last_name}`,
                patient_number: patient.patient_id,
                vital_id: vital.id,
                recorded_at: vital.recorded_at,
                alerts: alertsForVital,
                priority: alertsForVital.some(a => a.status === 'high') ? 'High' : 'Medium'
              })
            }
          }

          return new Response(
            JSON.stringify({ alerts }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }
        break

      case 'POST':
        if (path === 'create-alert') {
          // Create notification for vital alert
          const body = await req.json()
          const { patient_id, vital_id, alerts, priority } = body

          const notifications = alerts.map((alert: any) => ({
            patient_id,
            title: `Vital Alert: ${alert.type.replace('_', ' ').toUpperCase()}`,
            message: alert.message,
            type: 'vital_alert',
            priority: priority || 'Medium',
            scheduled_at: new Date().toISOString()
          }))

          const { data: notification, error } = await supabaseClient
            .from('notifications')
            .insert(notifications)
            .select()

          if (error) throw error

          return new Response(
            JSON.stringify({ notification }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 201,
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