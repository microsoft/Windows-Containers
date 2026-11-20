param(
    [string]$Repository = $env:GITHUB_REPOSITORY,
    [string]$Month,
    [string]$ReportPath,
    [string]$ProjectUrl,
    [switch]$Post
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ReportingWindow {
    param([string]$Month)

    if ([string]::IsNullOrWhiteSpace($Month)) {
        $now = [DateTime]::UtcNow
        $start = [DateTime]::new($now.Year, $now.Month, 1, 0, 0, 0, [DateTimeKind]::Utc).AddMonths(-1)
    }
    else {
        if ($Month -notmatch '^\d{4}-(0[1-9]|1[0-2])$') {
            throw 'Reporting month must use YYYY-MM.'
        }
        $start = [DateTime]::ParseExact(
            "$Month-01", 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal -bor [Globalization.DateTimeStyles]::AdjustToUniversal
        )
    }

    [pscustomobject]@{ Start = $start; End = $start.AddMonths(1) }
}

function Get-GitHubPages {
    param([string]$Endpoint)

    $json = gh api --paginate --slurp -H 'Accept: application/vnd.github+json' $Endpoint
    if ($LASTEXITCODE -ne 0) {
        throw 'GitHub retrieval failed. No Teams message was sent.'
    }
    $pages = ($json | Out-String) | ConvertFrom-Json
    foreach ($page in $pages) {
        foreach ($item in $page) {
            $item
        }
    }
}

function Format-IssueLink {
    param($Issue, [string]$Repository)

    $title = [regex]::Replace($Issue.title, '[\x00-\x1f\x7f\[\]()\\*_`<>@]', ' ')
    $title = [regex]::Replace($title, '\s+', ' ').Trim()
    if ($title.Length -gt 140) {
        $title = $title.Substring(0, 137) + '...'
    }
    "- [#$($Issue.number): $title](https://github.com/$Repository/issues/$($Issue.number))"
}

function New-EnhancementDigest {
    param(
        [string]$Repository,
        [object[]]$Issues,
        [object[]]$Comments,
        $Window,
        [string]$ProjectUrl
    )

    if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'Repository must use owner/name.'
    }
    if ($ProjectUrl -and $ProjectUrl -notmatch '^https://github\.com/(orgs/)?[A-Za-z0-9-]+/projects/[0-9]+$') {
        throw 'ProjectUrl must be a public GitHub Project URL.'
    }
    $issuesOnly = @($Issues | Where-Object { !$_.PSObject.Properties['pull_request'] })
    $open = @($issuesOnly | Where-Object { $_.state -eq 'open' })
    $new = @($issuesOnly | Where-Object {
        [DateTimeOffset]$_.created_at -ge $Window.Start -and [DateTimeOffset]$_.created_at -lt $Window.End
    } | Sort-Object created_at -Descending)
    $closed = @($issuesOnly | Where-Object {
        $_.closed_at -and [DateTimeOffset]$_.closed_at -ge $Window.Start -and
        [DateTimeOffset]$_.closed_at -lt $Window.End
    } | Sort-Object closed_at -Descending)
    $unassigned = @($open | Where-Object { @($_.assignees).Count -eq 0 } | Sort-Object created_at)
    $openByNumber = @{}
    foreach ($issue in $open) {
        $openByNumber[[string]$issue.number] = $issue
    }
    $communityReplies = @($Comments | Where-Object {
        $number = ($_.issue_url -split '/')[-1]
        $openByNumber.ContainsKey($number) -and
        [DateTimeOffset]$_.created_at -ge $Window.Start -and [DateTimeOffset]$_.created_at -lt $Window.End -and
        $_.user.type -ne 'Bot' -and $_.user.login -notmatch '\[bot\]$' -and
        $_.user.login -notin @('github-actions', 'microsoft-github-policy-service') -and
        $_.author_association -notin @('OWNER', 'MEMBER', 'COLLABORATOR')
    } | Sort-Object created_at -Descending)
    $replyIssues = @()
    $seen = @{}
    foreach ($comment in $communityReplies) {
        $number = ($comment.issue_url -split '/')[-1]
        if (!$seen.ContainsKey($number)) {
            $replyIssues += $openByNumber[$number]
            $seen[$number] = $true
        }
    }
    $popular = @($open | Sort-Object @{ Expression = { $_.reactions.'+1' }; Descending = $true }, number |
        Where-Object { $_.reactions.'+1' -gt 0 } | Select-Object -First 5)
    $monthLabel = $Window.Start.ToString('yyyy-MM')
    $title = "Windows Containers enhancement review - $monthLabel"
    $overview = "$($open.Count) currently open requests; $($new.Count) created and $($closed.Count) closed during $monthLabel."
    $note = 'Inventory, assignments, labels, and reactions reflect the current snapshot. Activity covers the previous reporting month in UTC. Closed does not mean shipped.'
    $sections = @(
        @{ Heading = "New requests ($($new.Count))"; Items = $new },
        @{ Heading = "Community replies to review ($($replyIssues.Count) open requests)"; Items = $replyIssues },
        @{ Heading = "Currently without an assignee ($($unassigned.Count))"; Items = $unassigned },
        @{ Heading = "Closed during the reporting month ($($closed.Count))"; Items = $closed },
        @{ Heading = 'Top interest signals (thumbs-up reactions, not customer counts)'; Items = $popular }
    )
    $markdown = @("# $title", '', $overview, '', $note)
    $cardBody = @(
        @{ type = 'TextBlock'; text = $title; weight = 'Bolder'; size = 'Large'; wrap = $true },
        @{ type = 'TextBlock'; text = $overview; wrap = $true },
        @{ type = 'TextBlock'; text = $note; wrap = $true }
    )
    foreach ($section in $sections) {
        $lines = @($section.Items | Select-Object -First 8 | ForEach-Object {
            $line = Format-IssueLink -Issue $_ -Repository $Repository
            if ($section.Heading -like 'Top interest*') {
                $line += " - $($_.reactions.'+1') reactions"
            }
            $line
        })
        if ($lines.Count -eq 0) {
            $lines = @('None.')
        }
        elseif ($section.Items.Count -gt 8) {
            $lines += "Showing 8 of $($section.Items.Count); see the issue tracker for the rest."
        }
        $text = $lines -join "`n"
        $markdown += @('', "## $($section.Heading)", '', $text)
        $cardBody += @(
            @{ type = 'TextBlock'; text = $section.Heading; weight = 'Bolder'; wrap = $true },
            @{ type = 'TextBlock'; text = $text; wrap = $true }
        )
    }
    $guidance = 'Community replies are candidates for human review, not confirmed unanswered questions; author association is only a heuristic. Review existing maintainer responses before replying. No delivery dates or internal tracking are inferred.'
    $searchUrl = "https://github.com/$Repository/issues?q=" +
        [Uri]::EscapeDataString('is:issue is:open label:enhancement')
    $markdown += @('', $guidance, '', "[View all open enhancement requests]($searchUrl)")
    $actions = @(@{ type = 'Action.OpenUrl'; title = 'View open requests'; url = $searchUrl })
    if ($ProjectUrl) {
        $markdown += @('', "[View feature-request board]($ProjectUrl)")
        $actions += @{ type = 'Action.OpenUrl'; title = 'Feature-request board'; url = $ProjectUrl }
    }
    $cardBody += @{ type = 'TextBlock'; text = $guidance; wrap = $true }
    $payload = @{
        type = 'message'
        attachments = @(@{
            contentType = 'application/vnd.microsoft.card.adaptive'
            contentUrl = $null
            content = @{
                '$schema' = 'http://adaptivecards.io/schemas/adaptive-card.json'
                type = 'AdaptiveCard'
                version = '1.4'
                body = $cardBody
                actions = $actions
            }
        })
    } | ConvertTo-Json -Depth 20 -Compress
    if ([Text.Encoding]::UTF8.GetByteCount($payload) -gt 24000) {
        throw 'Teams payload exceeds the 24,000-byte safety limit. No message was sent.'
    }
    [pscustomobject]@{ Markdown = $markdown -join "`n"; Payload = $payload; OpenCount = $open.Count }
}

function Assert-TeamsWebhook {
    param([string]$Url)

    $uri = $null
    if (![Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne 'https' -or $uri.UserInfo -or !$uri.IsDefaultPort -or
        $uri.Host -notmatch '^[a-z0-9-]+(\.[a-z0-9-]+)*\.(logic\.azure\.com|environment\.api\.powerplatform\.com)$') {
        throw 'Configure an HTTPS Teams Workflows endpoint in TEAMS_ENHANCEMENT_WEBHOOK_URL.'
    }
}

function Send-TeamsDigest {
    param([string]$Payload)

    Assert-TeamsWebhook -Url $env:TEAMS_ENHANCEMENT_WEBHOOK_URL
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $env:TEAMS_ENHANCEMENT_WEBHOOK_URL `
            -Method Post -ContentType 'application/json; charset=utf-8' `
            -Body ([Text.Encoding]::UTF8.GetBytes($Payload)) -TimeoutSec 60 -MaximumRedirection 0
    }
    catch {
        throw 'Teams webhook submission failed. Inspect Teams Workflow run history before retrying; delivery may be uncertain.'
    }
    if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
        throw "Teams webhook returned HTTP $($response.StatusCode). Inspect its run history before retrying."
    }
    Write-Output 'Teams Workflow accepted the request. Confirm final message delivery in its run history.'
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'Repository must use owner/name.'
    }
    $window = Get-ReportingWindow -Month $Month
    if ($Post) {
        Assert-TeamsWebhook -Url $env:TEAMS_ENHANCEMENT_WEBHOOK_URL
    }
    $issues = @(Get-GitHubPages -Endpoint "repos/$Repository/issues?state=all&labels=enhancement&per_page=100")
    $since = $window.Start.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
    $comments = @(Get-GitHubPages -Endpoint "repos/$Repository/issues/comments?since=$since&per_page=100")
    $digest = New-EnhancementDigest -Repository $Repository -Issues $issues -Comments $comments -Window $window -ProjectUrl $ProjectUrl
    if ($ReportPath) {
        $digest.Markdown | Set-Content -LiteralPath $ReportPath -Encoding UTF8
    }
    if ($env:GITHUB_STEP_SUMMARY) {
        $digest.Markdown | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY -Encoding UTF8
    }
    Write-Output "Generated reporting-month $($window.Start.ToString('yyyy-MM')) digest with $($digest.OpenCount) currently open requests."
    if ($Post) {
        Send-TeamsDigest -Payload $digest.Payload
    }
    else {
        Write-Output 'Dry run: no Teams request was made.'
    }
}
