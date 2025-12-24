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
        if (path === 'today-reminders') {
          // Get today's medication reminders
          const today = new Date().toISOString().split('T')[0]
          
          const { data: reminders, error } = await supabaseClient
            .from('medication_reminders')
            .select(`
              *,
              medications (
                medication_name,
                dosage,
                frequency,
                instructions,
                patients (
                  id,
                  first_name,
                  last_name,
                  patient_id,
                  phone,
                  email
                )
              )
            `)
            .eq('scheduled_date', today)
            .eq('taken', false)
            .order('scheduled_time', { ascending: true })

          if (error) throw error

          return new Response(
            JSON.stringify({ reminders }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        } else if (path === 'upcoming-reminders') {
          // Get upcoming medication reminders for the next 7 days
          const today = new Date()
          const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000)
          
          const { data: reminders, error } = await supabaseClient
            .from('medication_schedule')
            .select(`
              *,
              medications (
                medication_name,
                dosage,
                frequency,
                instructions,
                patients (
                  id,
                  first_name,
                  last_name,
                  patient_id,
                  phone,
                  email
                )
              )
            `)
            .gte('scheduled_date', today.toISOString().split('T')[0])
            .lte('scheduled_date', nextWeek.toISOString().split('T')[0])
            .eq('taken', false)
            .order('scheduled_date', { ascending: true })
            .order('scheduled_time', { ascending: true })

          if (error) throw error

          return new Response(
            JSON.stringify({ reminders }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        }
        break

      case 'POST':
        if (path === 'mark-taken') {
          // Mark medication as taken
          const body = await req.json()
          const { schedule_id, notes } = body

          const { data: schedule, error } = await supabaseClient
            .from('medication_schedule')
            .update({
              taken: true,
              taken_at: new Date().toISOString(),
              notes: notes || null
            })
            .eq('id', schedule_id)
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ schedule }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 200,
            }
          )
        } else if (path === 'create-reminder') {
          // Create medication reminder notification
          const body = await req.json()
          const { patient_id, medication_name, scheduled_time, scheduled_date } = body

          const { data: notification, error } = await supabaseClient
            .from('notifications')
            .insert([{
              patient_id,
              title: 'Medication Reminder',
              message: `Time to take your ${medication_name}`,
              type: 'medication_reminder',
              priority: 'Medium',
              scheduled_at: `${scheduled_date}T${scheduled_time}:00`
            }])
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ notification }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 201,
            }
          )
        } else if (path === 'generate-schedule') {
          // Generate medication schedule for a medication
          const body = await req.json()
          const { medication_id, start_date, end_date, frequency, scheduled_times } = body

          const schedules = []
          const start = new Date(start_date)
          const end = new Date(end_date)

          for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
            for (const time of scheduled_times) {
              schedules.push({
                medication_id,
                scheduled_date: d.toISOString().split('T')[0],
                scheduled_time: time,
                taken: false
              })
            }
          }

          const { data: createdSchedules, error } = await supabaseClient
            .from('medication_schedule')
            .insert(schedules)
            .select()

          if (error) throw error

          return new Response(
            JSON.stringify({ schedules: createdSchedules }),
            {
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
              status: 201,
            }
          )
        }
        break

      case 'PUT':
        if (path?.startsWith('schedule/')) {
          // Update medication schedule
          const scheduleId = path.split('/')[1]
          const body = await req.json()

          const { data: schedule, error } = await supabaseClient
            .from('medication_schedule')
            .update(body)
            .eq('id', scheduleId)
            .select()
            .single()

          if (error) throw error

          return new Response(
            JSON.stringify({ schedule }),
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