// // supabase/functions/generate-tasks/index.ts
// import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
// import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// // Initialize Supabase client using service role (safe only on server)
// const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
// serve(async (req)=>{
//   try {
//     // Authenticate user (optional, safer)
//     const authHeader = req.headers.get("Authorization") ?? "";
//     const token = authHeader.replace("Bearer ", "");
//     const { data: { user } } = await supabase.auth.getUser(token);
//     // Read request JSON body
//     const { goal, timeframe, timeStamp } = await req.json();
//     if (!goal || !timeframe || !timeStamp) {
//       return new Response(JSON.stringify({
//         error: "Missing 'goal' or 'timeframe' or 'timeStamp' fields."
//       }), {
//         status: 400
//       });
//     } // Build prompt for the AI
//     const prompt = `
// Generate only one complete to-do-list task for this user.add the steps as subtasks dont create many tasks.just return only a json not other explanations and details.
// Respond **only with JSON**. Do not include explanations, quotes, or extra text.

// Goal: ${goal}
// Timeframe: ${timeframe} (details to decide due date,use below Current timestamp to avoid due date and time from being before current date and time )
// Current timestamp: ${timeStamp} (timestamp is in YYYY-MM-DD HH:MM:SS format.this is current date time )
// all the due_date and due_time should be after current date  and time.
// due_date and due_time of subtasks cant be after those of main task.
// reminder time is decided using current time,reminder_amount and reminder_type(days,minutes...etc)

// when deriving dates and times consider the given current timestamp.

// make task_name short,friendly and easy to understand.

// Return only one task as a JSON array like this:
// [
//   {
//     "task_name": "string",
//     "task_note": "string",
//     "due_date": "YYYY-MM-DD",
//     "due_time": "HH:MM",
//     "category": "None | Work | Personal | Study | Others",
//     "priority": "Low | Medium | High",
//     "repeat_type": "none | daily | weekly | monthly | yearly",
//     "reminder_amount": integer,
//     "reminder_type": "minutes | hours | days | weeks | none",
//     "is_starred": boolean,
//     "subtasks": [
//       { "name": "string", "done": boolean,"due_date": "YYYY-MM-DD","due_time": "HH:MM" }
//     ]
//   }
// ]
//     `;
//     // Call OpenRouter DeepSeek API
//     const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
//       method: "POST",
//       headers: {
//         "Authorization": `Bearer ${Deno.env.get("OPEN_ROUTER_API_KEY")}`,
//         "Content-Type": "application/json"
//       },
//       body: JSON.stringify({
//         "model": "deepseek/deepseek-r1-0528-qwen3-8b:free",
//         "messages": [
//           {
//             "role": "user",
//             "content": prompt
//           }
//         ]
//       })
//     });
//     // Parse response
//     const aiData = await response.json();
//     // ✅ Step 1: Get the message content safely
//     const content = aiData?.choices?.[0]?.message?.content;
//     if (!content) {
//       return new Response(JSON.stringify({
//         error: "No AI content returned."
//       }), {
//         status: 500
//       });
//     }
//     // ✅ Step 2: Clean out Markdown formatting (```json ... ```)
//     const cleaned = content.replace(/```json/i, "") // remove starting ```json
//     .replace(/```/g, "") // remove closing ```
//     .trim();
//     let tasks;
//     try {
//       // ✅ Step 3: Parse JSON content
//       tasks = JSON.parse(cleaned);
//     } catch (err) {
//       console.error("JSON Parse Error:", err, cleaned);
//       return new Response(JSON.stringify({
//         error: "Invalid AI output format."
//       }), {
//         status: 500
//       });
//     }
//     // ✅ Step 4: Return parsed tasks
//     return new Response(JSON.stringify({
//       success: true,
//       tasks
//     }), {
//       status: 200
//     });
//   /*
//     // Insert into Supabase
//     const { data, error } = await supabase.from("tasks").insert(tasks.map((t)=>({
//         task_name: t.task_name,
//         is_completed: false,
//         task_note: t.task_note ?? null,
//         due_date: t.due_date ?? null,
//         due_time: t.due_time ?? null,
//         category: t.category ?? "General",
//         priority: t.priority ?? "medium",
//         repeat_type: t.repeat_type ?? "none",
//         reminder_amount: t.reminder_amount ?? 0,
//         reminder_type: t.reminder_type ?? "minutes",
//         is_starred: t.is_starred ?? false,
//         subtasks: t.subtasks ?? [],
//         user_id: user?.id ?? null
//       }))).select();
//     if (error) throw error;
//     return new Response(JSON.stringify({
//       success: true,
//       tasks: data
//     }), {
//       headers: {
//         "Content-Type": "application/json"
//       }
//     });*/ } catch (err) {
//     console.error("Function Error:", err);
//     return new Response(JSON.stringify({
//       error: err.message
//     }), {
//       status: 500
//     });
//   }
// });
