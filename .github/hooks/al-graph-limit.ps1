$Limit = 3
$StateDir = Join-Path $env:TEMP "mb-al-graph-demo"
New-Item -ItemType Directory -Force -Path $StateDir | Out-Null

$InputJson = [Console]::In.ReadToEnd() | ConvertFrom-Json
$ToolName = $InputJson.tool_name
$SessionId = if ($InputJson.session_id) { $InputJson.session_id } else { "default" }
$WorkspaceRoot = if ($InputJson.cwd) { $InputJson.cwd } else { "." }

if ($ToolName -ne "al_build") {
    Write-Output '{"hookSpecificOutput":{"permissionDecision":"allow"}}'
    exit 0
}

$CountFile = Join-Path $StateDir "$SessionId.count"
$Count = 0
if (Test-Path $CountFile) {
    $Count = [int](Get-Content $CountFile)
}
$Count++
Set-Content -Path $CountFile -Value $Count

$StateFile = Join-Path $WorkspaceRoot "state.json"
$Timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if ($Count -gt $Limit) {
    $State = @{node="verify"; result="blocked"; attempt=$Count; limit=$Limit; commit=$null; updated=$Timestamp}
    $State | ConvertTo-Json -Compress | Set-Content -Path $StateFile
    $Reason = "Attempt limit ($Limit) reached. The graph stopped at Verify. Review the last error and fix it by hand."
    Write-Output (@{hookSpecificOutput=@{permissionDecision="deny"; permissionDecisionReason=$Reason}} | ConvertTo-Json -Compress)
    exit 0
}

$State = @{node="verify"; result="pending"; attempt=$Count; limit=$Limit; commit=$null; updated=$Timestamp}
$State | ConvertTo-Json -Compress | Set-Content -Path $StateFile
$Context = "Attempt $Count of $Limit."
Write-Output (@{hookSpecificOutput=@{permissionDecision="allow"; additionalContext=$Context}} | ConvertTo-Json -Compress)
exit 0
