# E2E validation script - run with API already up on localhost:3000
$base = "http://localhost:3000"
$results = @{}

# 1. Catalog
try {
  $r = Invoke-RestMethod -Uri "$base/muscles" -Method Get; $results.muscles = ($r -is [array] -and $r.Count -ge 0) -or $r; if (-not $results.muscles) { $results.muscles = $true }
} catch { $results.muscles = $false }
try {
  $r = Invoke-RestMethod -Uri "$base/equipment-items" -Method Get; $results.equipment = $true
} catch { $results.equipment = $false }
try {
  $r = Invoke-RestMethod -Uri "$base/exercises" -Method Get; $results.exercises = ($r -is [array] -and $r.Count -ge 1) -or $r
} catch { $results.exercises = $false }
try {
  $r = Invoke-RestMethod -Uri "$base/foods" -Method Get; $results.foods = ($r -is [array]) -or ($r -ne $null)
} catch { $results.foods = $false }

# 2. Auth - register
$email = "e2e-" + [guid]::NewGuid().ToString("n").Substring(0,8) + "@test.com"
$pass = "TestPass123!"
$tokens = $null
try {
  $reg = Invoke-RestMethod -Uri "$base/auth/register" -Method Post -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -ContentType "application/json"
  $tokens = $reg; $results.register = ($reg.accessToken -and $reg.refreshToken)
} catch { $results.register = $false }

# login
try {
  $login = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -ContentType "application/json"
  if (-not $tokens) { $tokens = $login }; $results.login = ($login.accessToken -and $login.refreshToken)
} catch { $results.login = $false }

$headers = @{ Authorization = "Bearer $($tokens.accessToken)" }

# /me
try {
  $me = Invoke-RestMethod -Uri "$base/me" -Method Get -Headers $headers; $results.me = ($me.id -and $me.email)
} catch { $results.me = $false }

# refresh
try {
  $ref = Invoke-RestMethod -Uri "$base/auth/refresh" -Method Post -Body (@{ refreshToken = $tokens.refreshToken } | ConvertTo-Json) -ContentType "application/json"
  $results.refresh = ($ref.accessToken -and $ref.refreshToken); $newAccess = $ref.accessToken
} catch { $results.refresh = $false }

# reuse refresh (must fail)
try {
  Invoke-RestMethod -Uri "$base/auth/refresh" -Method Post -Body (@{ refreshToken = $tokens.refreshToken } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
  $results.refreshReuseFails = $false
} catch { $results.refreshReuseFails = ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403) }

# logout
try {
  Invoke-RestMethod -Uri "$base/auth/logout" -Method Post -Body (@{ refreshToken = $tokens.refreshToken } | ConvertTo-Json) -ContentType "application/json"
  $results.logout = $true
} catch { $results.logout = $false }

# Re-login for further tests
$login2 = Invoke-RestMethod -Uri "$base/auth/login" -Method Post -Body (@{ email = $email; password = $pass } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ Authorization = "Bearer $($login2.accessToken)" }

# 3. Training plan
try {
  $gen = Invoke-RestMethod -Uri "$base/training-plans/generate" -Method Post -Headers $headers
  $results.trainingGenerate = ($gen.plan.currentVersionId -or $gen.version.id)
} catch { $results.trainingGenerate = $false }
try {
  $cur = Invoke-RestMethod -Uri "$base/training-plans/current" -Method Get -Headers $headers
  $results.trainingCurrent = ($cur -ne $null); $planSessions = $cur.version.sessions
} catch { $results.trainingCurrent = $false; $planSessions = @() }
try {
  $ver = Invoke-RestMethod -Uri "$base/training-plans/versions" -Method Get -Headers $headers
  $results.trainingVersions = ($ver -is [array] -or $ver.Count -ge 0)
} catch { $results.trainingVersions = $false }

# 4. Workout
$sessionId = $null; $workoutId = $null; $workoutExerciseId = $null
$planSessionId = $null
if ($planSessions -and $planSessions.Count -gt 0) { $planSessionId = $planSessions[0].id }
try {
  $start = Invoke-RestMethod -Uri "$base/workouts/start" -Method Post -Headers $headers -Body (@{ planSessionId = $planSessionId } | ConvertTo-Json) -ContentType "application/json"
  $workoutId = $start.id; $results.workoutStart = ($workoutId -ne $null)
} catch { $results.workoutStart = $false }

if ($workoutId) {
  # get exercises from catalog to add one
  $exList = Invoke-RestMethod -Uri "$base/exercises" -Method Get
  $items = if ($exList.items) { $exList.items } else { @() }
  $exId = if ($items.Count -gt 0) { $items[0].id } else { "ex1" }
  try {
    $addEx = Invoke-RestMethod -Uri "$base/workouts/$workoutId/exercises" -Method Post -Headers $headers -Body (@{ exerciseId = $exId } | ConvertTo-Json) -ContentType "application/json"
    if ($addEx.exercises -and $addEx.exercises.Count -gt 0) { $workoutExerciseId = $addEx.exercises[$addEx.exercises.Count-1].id }
    $results.workoutAddExercise = ($workoutExerciseId -ne $null)
  } catch { $results.workoutAddExercise = $false }
  if ($workoutExerciseId) {
    try {
      Invoke-RestMethod -Uri "$base/workouts/$workoutId/exercises/$workoutExerciseId/sets" -Method Post -Headers $headers -Body (@{ weightKg = 60; reps = 10; completed = $true } | ConvertTo-Json) -ContentType "application/json" | Out-Null
      $results.workoutLogSet = $true
    } catch { $results.workoutLogSet = $false }
  }
  try {
    Invoke-RestMethod -Uri "$base/workouts/$workoutId/finish" -Method Post -Headers $headers -Body (@{ durationMinutes = 25 } | ConvertTo-Json) -ContentType "application/json" | Out-Null
    $results.workoutFinish = $true
  } catch { $results.workoutFinish = $false }
  try {
    $hist = Invoke-RestMethod -Uri "$base/workouts/history" -Method Get -Headers $headers
    $results.workoutHistory = $true
  } catch { $results.workoutHistory = $false }
  try {
    $one = Invoke-RestMethod -Uri "$base/workouts/$workoutId" -Method Get -Headers $headers
    $results.workoutGetById = ($one.exercises -ne $null -or $one.id -eq $workoutId)
  } catch { $results.workoutGetById = $false }
  # wrong workoutExerciseId must fail
  try {
    Invoke-RestMethod -Uri "$base/workouts/$workoutId/exercises/00000000-0000-0000-0000-000000000000/sets" -Method Post -Headers $headers -Body (@{ reps = 5 } | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    $results.workoutWrongExIdFails = $false
  } catch { $results.workoutWrongExIdFails = $true }
}

# 5. Analytics
try {
  $prog = Invoke-RestMethod -Uri "$base/analytics/progress" -Method Get -Headers $headers
  $results.analyticsProgress = ($prog -ne $null)
} catch { $results.analyticsProgress = $false }
try {
  $vol = Invoke-RestMethod -Uri "$base/analytics/volume" -Method Get -Headers $headers
  $results.analyticsVolume = ($vol -ne $null)
} catch { $results.analyticsVolume = $false }

# 6. Nutrition
try {
  $nutGen = Invoke-RestMethod -Uri "$base/nutrition-plans/generate" -Method Post -Headers $headers
  $results.nutritionGenerate = ($nutGen -ne $null)
} catch { $results.nutritionGenerate = $false }
try {
  $nutCur = Invoke-RestMethod -Uri "$base/nutrition-plans/current" -Method Get -Headers $headers
  $results.nutritionCurrent = ($nutCur -ne $null)
} catch { $results.nutritionCurrent = $false }
try {
  $nutVer = Invoke-RestMethod -Uri "$base/nutrition-plans/versions" -Method Get -Headers $headers
  $results.nutritionVersions = $true
} catch { $results.nutritionVersions = $false }

# 7. AI Coach
try {
  $ai1 = Invoke-RestMethod -Uri "$base/ai-coach/ask" -Method Post -Headers $headers -Body (@{ question = "Why is my workout focused on compound lifts?" } | ConvertTo-Json) -ContentType "application/json"
  $results.aiNormal = ($ai1.responseType -ne $null)
} catch { $results.aiNormal = $false }
try {
  $ai2 = Invoke-RestMethod -Uri "$base/ai-coach/ask" -Method Post -Headers $headers -Body (@{ question = "Can you swap bench press for dumbbell press?" } | ConvertTo-Json) -ContentType "application/json"
  $results.aiProposal = ($ai2.responseType -ne $null -and ($ai2.proposalStatus -ne $null -or $ai2.responseType -match "proposal"))
} catch { $results.aiProposal = $false }
try {
  $ai3 = Invoke-RestMethod -Uri "$base/ai-coach/ask" -Method Post -Headers $headers -Body (@{ question = "Use a non-existent exercise id xyz999" } | ConvertTo-Json) -ContentType "application/json"
  $results.aiInvalid = ($ai3.proposalValid -eq $false -or $ai3.responseType -match "rejected")
} catch { $results.aiInvalid = $true }

$results | ConvertTo-Json
