[CmdletBinding()]
param (
    [Parameter()]
    [string] $JiraUrl = $Env:JIRA_URL,

    [Parameter()]
    [string] $JiraPat = $Env:JIRA_PAT,

    [Parameter()]
    [string] $JiraUser = $Env:JIRA_USER,

    [Parameter()]
    [string] $ProjectKey = $Env:JIRA_PROJECT_KEY,

    [Parameter()]
    [string] $ProjectBoardName = $Env:JIRA_PROJECT_BOARD_NAME,

    [Parameter()]
    [string] $IssueType = $Env:JIRA_ISSUE_TYPE,

    [Parameter()]
    [bool] $assigntoCurrentSprint = ($Env:JIRA_ASSIGN_TO_CURRENT_SPRINT -eq 'True'),

    [Parameter()]
    [bool] $assignToCurrentRelease = ($Env:JIRA_ASSIGN_TO_CURRENT_RELEASE -eq 'True')
)

function Get-JiraAuthHeader {
    param (
        [string] $JiraUser,
        [string] $JiraPat
    )

    $pair = "${JiraUser}:${JiraPat}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $headers = @{
        Authorization = "Basic $base64"
        "Content-Type" = "application/json"
    }

    return $headers
}

function Get-JiraCurrentRelease {
    param (
        [string] $JiraUrl,
        [string] $JiraUser,
        [string] $JiraPat,
        [string] $ProjectKey
    )

    if (-not $assignToCurrentRelease) {
        return $null
    }

    $headers = Get-JiraAuthHeader -JiraUser $JiraUser -JiraPat $JiraPat
    # Get project by key
    $projects = Invoke-RestMethod -Uri "$JiraUrl/rest/api/3/project" -Headers $headers -Method Get
    $project = $projects | Where-Object { $_.key -eq $ProjectKey }

    # Get current project release
    $releases = Invoke-RestMethod -Uri "$JiraUrl/rest/api/3/project/$($project.id)/versions" -Headers $headers -Method Get
    $currentRelease = $releases | Where-Object { $_.released -eq $false } | Sort-Object -Property releaseDate | Select-Object -First 1

    return $currentRelease
}

function Get-JiraActiveSprint {
    param (
        [string] $JiraUrl,
        [string] $JiraUser,
        [string] $JiraPat,
        [string] $ProjectKey
    )

    if (-not $assigntoCurrentSprint) {
        return $null
    }

    $headers = Get-JiraAuthHeader -JiraUser $JiraUser -JiraPat $JiraPat
    # Get the board for the project
    $boards = Invoke-RestMethod -Uri "$JiraUrl/rest/agile/1.0/board?projectKeyOrId=$ProjectKey" -Headers $headers -Method Get
    $board = $boards.values | Where-Object { $_.name -eq $ProjectBoardName } | Select-Object -First 1

    if ($board) {
        # Get active sprint for the board
        $sprints = Invoke-RestMethod -Uri "$JiraUrl/rest/agile/1.0/board/$($board.id)/sprint?state=active" -Headers $headers -Method Get
        $activeSprint = $sprints.values | Select-Object -First 1

        return $activeSprint
    }

    return $null
}

function New-JiraIssue {
    param (
        [string] $JiraUrl,
        [string] $ProjectKey,
        [string] $Summary,
        [string] $Description,
        [string] $IssueType,
        [string] $JiraUser,
        [string] $JiraPat
    )

    $headers = Get-JiraAuthHeader -JiraUser $JiraUser -JiraPat $JiraPat
    $headers += @{
        Accept = "application/json"
    }

    $body = @{
        fields = @{
            project           = @{ key = $ProjectKey }
            summary           = $Summary
            description       = @{
                version = 1
                type = "doc"
                content = @(
                    @{
                        type = "paragraph"
                        content = @(
                            @{
                                type = "text"
                                text = $Description
                            }
                        )
                    }
                )
            }
            issuetype         = @{ name = "$IssueType" }
            fixVersions       = @(@{ name = (Get-JiraCurrentRelease -JiraUrl $JiraUrl -JiraUser $JiraUser -JiraPat $JiraPat -ProjectKey $ProjectKey).name } )
            customfield_10020 = (Get-JiraActiveSprint -JiraUrl $JiraUrl -JiraUser $JiraUser -JiraPat $JiraPat -ProjectKey $ProjectKey).id
        }
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "$JiraUrl/rest/api/3/issue" -Headers $headers -Method Post -Body $body
    return $response.key
}

$newIssue = New-JiraIssue -JiraUrl $JiraUrl -ProjectKey $ProjectKey -Summary "Test issue from Actions with current Sprint and Release" -Description "Created using Actions via REST API and assigned to current Sprint and latest Release" -IssueType "External Request" -JiraUser $JiraUser -JiraPat $JiraPat
echo "jira_issue_id=$($newIssue)" >> $env:GITHUB_OUTPUT
