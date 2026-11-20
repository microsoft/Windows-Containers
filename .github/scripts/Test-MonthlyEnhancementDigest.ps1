Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Send-MonthlyEnhancementDigest.ps1')

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (!$Condition) { throw $Message }
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $threw = $false
    try { & $Action } catch { $threw = $true }
    Assert-True -Condition $threw -Message $Message
}

function New-TestIssue {
    param([int]$Number, [string]$Created, [string]$State = 'open', $Closed = $null)
    [pscustomobject]@{
        number = $Number
        title = 'A request'
        created_at = $Created
        closed_at = $Closed
        state = $State
        assignees = @()
        reactions = [pscustomobject]@{ '+1' = 0 }
    }
}

$window = Get-ReportingWindow -Month '2026-12'
Assert-True ($window.End.ToString('yyyy-MM-dd') -eq '2027-01-01') 'December must end in January of the next year.'
Assert-Throws { Get-ReportingWindow -Month '2026-13' } 'Invalid month must fail.'
$window = Get-ReportingWindow -Month '2026-10'
$issues = @(
    (New-TestIssue 1 '2026-10-01T00:00:00Z'),
    (New-TestIssue 2 '2026-11-01T00:00:00Z'),
    (New-TestIssue 3 '2026-09-01T00:00:00Z' 'closed' '2026-10-31T23:59:59Z')
)
$pr = New-TestIssue 4 '2026-10-15T00:00:00Z'
$pr | Add-Member -NotePropertyName pull_request -NotePropertyValue @{}
$issues += $pr
$comments = @(
    @{ issue_url = 'https://api.github.com/repos/test/repo/issues/1'; created_at = '2026-10-05T00:00:00Z'; user = @{ type = 'User'; login = 'reporter' }; author_association = 'NONE' },
    @{ issue_url = 'https://api.github.com/repos/test/repo/issues/1'; created_at = '2026-10-06T00:00:00Z'; user = @{ type = 'User'; login = 'reporter' }; author_association = 'NONE' },
    @{ issue_url = 'https://api.github.com/repos/test/repo/issues/2'; created_at = '2026-10-06T00:00:00Z'; user = @{ type = 'Bot'; login = 'automation' }; author_association = 'NONE' },
    @{ issue_url = 'https://api.github.com/repos/test/repo/issues/2'; created_at = '2026-10-06T00:00:00Z'; user = @{ type = 'User'; login = 'maintainer' }; author_association = 'MEMBER' },
    @{ issue_url = 'https://api.github.com/repos/test/repo/issues/2'; created_at = '2026-11-01T00:00:00Z'; user = @{ type = 'User'; login = 'reporter' }; author_association = 'NONE' }
)
$digest = New-EnhancementDigest -Repository 'test/repo' -Issues $issues -Comments $comments -Window $window
Assert-True ($digest.OpenCount -eq 2) 'Pull requests must not be counted.'
Assert-True ($digest.Markdown.Contains('New requests (1)')) 'Reporting period must include its start and exclude its end.'
Assert-True ($digest.Markdown.Contains('Closed during the reporting month (1)')) 'Closed requests must be reported separately from shipped features.'
Assert-True ($digest.Markdown.Contains('Community replies to review (1 open requests)')) 'Community replies must exclude bots, maintainers, and out-of-period comments and deduplicate issues.'
$empty = New-EnhancementDigest -Repository 'test/repo' -Issues @() -Comments @() -Window $window
Assert-True ($empty.OpenCount -eq 0 -and $empty.Markdown.Contains('None.')) 'An empty month must render a useful report.'
$issues[0].title = '[click](https://example.invalid) @everyone <script>'
$safe = Format-IssueLink -Issue $issues[0] -Repository 'test/repo'
Assert-True (!$safe.Contains('@everyone') -and !$safe.Contains('[click](') -and !$safe.Contains('<script>')) 'Issue titles must not inject mentions, markup, or links.'
Assert-TeamsWebhook 'https://example.westus.logic.azure.com/workflows/test?sig=example'
Assert-TeamsWebhook 'https://example.environment.api.powerplatform.com/powerautomate/automations/direct/workflows/test'
foreach ($url in @(
    'http://example.logic.azure.com/test',
    'https://example.logic.azure.com.attacker.invalid/test',
    'https://example@westus.logic.azure.com/test',
    'https://example.logic.azure.com:8443/test',
    ''
)) {
    Assert-Throws { Assert-TeamsWebhook $url } 'Invalid or lookalike webhook addresses must fail.'
}
$many = @(1..40 | ForEach-Object {
    $issue = New-TestIssue $_ '2026-10-01T00:00:00Z'
    $issue.title = 'Long title ' * 100
    $issue
})
$large = New-EnhancementDigest -Repository 'test/repo' -Issues $many -Comments @() -Window $window
Assert-True ($large.Markdown.Contains('Showing 8 of 40')) 'Long lists must state truncation.'
Assert-True ([Text.Encoding]::UTF8.GetByteCount($large.Payload) -le 24000) 'Payload must remain within its byte safety limit.'
$payload = $large.Payload | ConvertFrom-Json
Assert-True ($payload.attachments.Count -eq 1 -and $payload.attachments[0].content.type -eq 'AdaptiveCard') 'Teams payload must contain an Adaptive Card attachment.'
$withBoard = New-EnhancementDigest -Repository 'test/repo' -Issues @() -Comments @() -Window $window -ProjectUrl 'https://github.com/orgs/test/projects/1'
Assert-True ($withBoard.Markdown.Contains('[View feature-request board](https://github.com/orgs/test/projects/1)')) 'Configured Project must be linked from the digest.'
Assert-Throws { New-EnhancementDigest -Repository 'test/repo' -Issues @() -Comments @() -Window $window -ProjectUrl 'https://github.com.attacker.invalid/orgs/test/projects/1' } 'Invalid Project links must fail.'
Write-Output 'Monthly enhancement digest checks passed.'
