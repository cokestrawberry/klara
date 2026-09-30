# Measures the tokens klara adds, per eval case and condition (none, lookup, nolookup).
#   powershell -File scripts/token-usage/measure.ps1 -Agent claude|codex -WorkRoot <dir> [-Runs 2]
# Writes <WorkRoot>/<agent>-runs.csv and prints the mean tokens per run for each condition.
param(
    [Parameter(Mandatory = $true)][ValidateSet('claude', 'codex')][string]$Agent,
    [Parameter(Mandatory = $true)][string]$WorkRoot,
    [int]$Runs = 2,
    [string]$Model = 'claude-sonnet-5-5'
)

$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$control = Join-Path $PSScriptRoot 'control'
$traces = Join-Path $WorkRoot 'traces'
New-Item -ItemType Directory -Force $traces | Out-Null

function Get-Sum($values) { [int](($values | Measure-Object -Sum).Sum) }

function Get-MeanTokens($runs) {
    [Math]::Round(($runs | ForEach-Object { $_.input_total + $_.output } | Measure-Object -Average).Average, 0)
}

function Measure-Claude {
    # The control case is not part of the plugin's eval suite, so it runs from a copy.
    $plugin = Join-Path $WorkRoot 'plugin'
    if (Test-Path $plugin) { Remove-Item -Recurse -Force $plugin }
    Copy-Item (Join-Path $repo 'plugins/klara') $plugin -Recurse
    Copy-Item $control (Join-Path $plugin 'evals/control') -Recurse
    $eval = @('plugin', 'eval', $plugin, '--runs', $Runs, '--model', $Model, '--threshold', '0',
        '--no-publish', '--trust-plugin', '--keep-temp')
    $fetch = 'terms.tta.or.kr', 'pascal.computer.org', 'stdict.korean.go.kr', 'opendict.korean.go.kr',
    'oxfordlearnersdictionaries.com', 'www.oxfordlearnersdictionaries.com' | ForEach-Object { "WebFetch(domain:$_)" }
    $lookup = Join-Path $WorkRoot 'claude-lookup.json'
    $nolookup = Join-Path $WorkRoot 'claude-nolookup.json'
    & claude @eval --json $lookup --allow-tools Write @fetch | Out-Host
    & claude @eval --ablation none --json $nolookup --allow-tools Write | Out-Host

    foreach ($arm in @(@($lookup, 'without', 'none'), @($lookup, 'with', 'lookup'), @($nolookup, 'with', 'nolookup'))) {
        foreach ($case in (Get-Content $arm[0] -Raw -Encoding UTF8 | ConvertFrom-Json).cases) {
            $number = 0
            foreach ($run in $case.arms.($arm[1])) {
                $number++
                $row = [ordered]@{ agent = 'claude'; case = $case.name; condition = $arm[2]; run = $number; model = $Model
                    score = $run.score; error = $run.error }
                if (Test-Path $run.tracePath) {
                    $events = Get-Content $run.tracePath -Encoding UTF8 | ConvertFrom-Json
                    $final = $events | Where-Object { $_.type -eq 'result' }
                    $blocks = @($events | Where-Object { $_.type -in 'assistant', 'user' } |
                        ForEach-Object { $_.message.content } | Where-Object { $_ -isnot [string] })
                    $uses = @($blocks | Where-Object { $_.type -eq 'tool_use' })
                    $ids = @($uses | Where-Object { $_.name -eq 'WebFetch' } | ForEach-Object { $_.id })
                    $results = @($blocks | Where-Object { $_.type -eq 'tool_result' -and $ids -contains $_.tool_use_id })
                    $aux = @($final.modelUsage.PSObject.Properties | Where-Object { $_.Name -ne $Model } | ForEach-Object { $_.Value })
                    $usage = $final.usage
                    $row.turns = $final.num_turns
                    $row.tools = ($uses | ForEach-Object { $_.name }) -join ' '
                    $row.input_total = $usage.input_tokens + $usage.cache_creation_input_tokens + $usage.cache_read_input_tokens
                    $row.cache_read = $usage.cache_read_input_tokens
                    $row.cache_write = $usage.cache_creation_input_tokens
                    $row.output = $usage.output_tokens
                    $row.reasoning = $usage.output_tokens_details.thinking_tokens
                    $row.aux_tokens = Get-Sum ($aux | ForEach-Object { $_.inputTokens + $_.cacheCreationInputTokens + $_.cacheReadInputTokens + $_.outputTokens })
                    $row.lookups = $ids.Count
                    $row.lookup_chars = Get-Sum ($results | ForEach-Object {
                            if ($_.content -is [string]) { $_.content.Length } else { Get-Sum ($_.content | ForEach-Object { $_.text.Length }) } })
                    # --keep-temp leaves each run's directory behind; only the trace is kept from it.
                    Copy-Item $run.tracePath (Join-Path $traces "claude-$($case.name)-$($arm[2])-$number.jsonl")
                    Remove-Item -Recurse -Force (Split-Path -Parent (Split-Path -Parent $run.tracePath))
                }
                [pscustomobject]$row
            }
        }
    }
}

function Get-Prompt($file) {
    $lines = @(Get-Content $file -Encoding UTF8)
    $start = [Array]::FindIndex($lines, [Predicate[string]] { param($line) $line -match '^\s+prompt: [|>]' })
    $body = @()
    for ($i = $start + 1; $i -lt $lines.Count -and ($lines[$i] -match '^\s{4}' -or $lines[$i] -eq ''); $i++) {
        $body += $lines[$i] -replace '^\s{4}', ''
    }
    $separator = if ($lines[$start] -match '>') { ' ' } else { "`n" }
    ($body -join $separator).TrimEnd()
}

function Measure-Codex {
    $conditions = [ordered]@{
        none     = 'plugins.klara@klara.enabled=false', 'web_search=live', 'sandbox_workspace_write.network_access=true'
        lookup   = 'web_search=live', 'sandbox_workspace_write.network_access=true'
        nolookup = 'web_search=disabled', 'sandbox_workspace_write.network_access=false'
    }
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $cases = @(Get-ChildItem (Join-Path $repo 'plugins/klara/evals/*/case.yaml')) + @(Get-Item (Join-Path $control 'case.yaml'))
    foreach ($file in $cases) {
        $name = Split-Path -Leaf (Split-Path -Parent $file.FullName)
        $prompt = Get-Prompt $file.FullName
        foreach ($condition in $conditions.Keys) {
            for ($number = 1; $number -le $Runs; $number++) {
                $dir = Join-Path $WorkRoot "codex/$name-$condition-$number"
                New-Item -ItemType Directory -Force $dir | Out-Null
                $config = $conditions[$condition] | ForEach-Object { '-c', $_ }
                # The prompt goes through stdin because Windows PowerShell 5.1 does not escape
                # double quotes inside native command arguments.
                $lines = @($prompt | codex exec --json --skip-git-repo-check -s workspace-write -C $dir @config - 2>$null |
                    Where-Object { $_.StartsWith('{') })
                $lines | Set-Content (Join-Path $traces "codex-$name-$condition-$number.jsonl") -Encoding UTF8
                $events = @($lines | ConvertFrom-Json)
                $thread = ($events | Where-Object { $_.type -eq 'thread.started' }).thread_id
                $rollout = Get-ChildItem (Join-Path $codexHome 'sessions') -Recurse -Filter "*$thread.jsonl" | Select-Object -First 1
                $context = Get-Content $rollout.FullName -Encoding UTF8 | Where-Object { $_ -match '"type":"turn_context"' } | Select-Object -First 1
                $usage = @($events | Where-Object { $_.type -eq 'turn.completed' } | ForEach-Object { $_.usage })
                $items = @($events | Where-Object { $_.type -eq 'item.completed' } | ForEach-Object { $_.item })
                $searches = @($items | Where-Object { $_.type -eq 'web_search' })
                $fetches = @($items | Where-Object { $_.type -eq 'command_execution' -and $_.command -match 'curl|wget|Invoke-WebRequest|Invoke-RestMethod' })
                $failure = $events | Where-Object { $_.type -in 'turn.failed', 'error' } | Select-Object -First 1
                [pscustomobject][ordered]@{
                    agent = 'codex'; case = $name; condition = $condition; run = $number
                    model = ($context | ConvertFrom-Json).payload.model; score = $null
                    error = if ($failure) { if ($failure.error) { $failure.error.message } else { $failure.message } } else { $null }
                    turns = $usage.Count
                    tools = ($items | Where-Object { $_.type -ne 'agent_message' } | ForEach-Object { $_.type }) -join ' '
                    input_total = Get-Sum $usage.input_tokens
                    cache_read = Get-Sum $usage.cached_input_tokens
                    cache_write = Get-Sum $usage.cache_write_input_tokens
                    output = Get-Sum $usage.output_tokens
                    reasoning = Get-Sum $usage.reasoning_output_tokens
                    aux_tokens = $null
                    lookups = $searches.Count + $fetches.Count
                    lookup_chars = (Get-Sum ($searches | ForEach-Object { ($_.results | ConvertTo-Json -Compress -Depth 4).Length })) +
                    (Get-Sum ($fetches | ForEach-Object { $_.aggregated_output.Length }))
                }
            }
        }
    }
}

$rows = @(if ($Agent -eq 'claude') { Measure-Claude } else { Measure-Codex })
$rows | Export-Csv (Join-Path $WorkRoot "$Agent-runs.csv") -NoTypeInformation -Encoding UTF8
$rows | Group-Object condition | ForEach-Object {
    $group = $_.Group
    [pscustomobject][ordered]@{
        condition = $_.Name
        eval_cases = Get-MeanTokens @($group | Where-Object { $_.case -ne 'control' })
        control = Get-MeanTokens @($group | Where-Object { $_.case -eq 'control' })
        web_requests = Get-Sum $group.lookups
        errors = @($group | Where-Object { $_.error }).Count
    }
} | Format-Table -AutoSize
