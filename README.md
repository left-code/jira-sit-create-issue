# Create Jira Issue

This GitHub Action creates a Jira issue and optionally assigns it to the current sprint and release. It uses the Jira REST API to interact with your Jira instance and supports various configuration options for issue creation.

## Inputs

### `url`

**Required** The URL of your Jira instance (e.g., `https://your-company.atlassian.net`).

### `pat`

**Required** Personal Access Token for Jira authentication. Store this as a secret in your repository.

### `user`

**Required** Jira username for authentication.

### `project_key`

**Required** The project key in Jira where the issue will be created (e.g., `PROJ`).

### `project_board_name`

**Required** The name of the Jira board associated with your project.

### `issue_type`

**Required** The type of issue to create (e.g., `Task`, `Bug`, `Story`, `External Request`).

### `assign_to_current_sprint`

**Optional** Whether to assign the issue to the current active sprint. Default: `false`.

### `assign_to_current_release`

**Optional** Whether to assign the issue to the current unreleased version. Default: `false`.

## Outputs

### `jira_issue_id`

The ID/key of the created Jira issue (e.g., `PROJ-123`).

## Features

- Creates Jira issues using REST API v3
- Supports Basic authentication with username and PAT
- Automatically assigns issues to current active sprint (optional)
- Automatically assigns issues to current unreleased version (optional)
- Uses Atlassian Document Format (ADF) for issue descriptions
- Provides the created issue ID as output for further workflow steps

## Example usage

```yaml
- name: Create Jira Issue
  uses: left-code/jira-sit-create-issue@v1
  with:
    jira_url: ${{ secrets.JIRA_URL }}
    jira_pat: ${{ secrets.JIRA_PAT }}
    jira_user: ${{ secrets.JIRA_USER }}
    jira_project_key: 'PROJ'
    jira_project_board_name: 'Project Board'
    jira_issue_type: 'Task'
    jira_assign_to_current_sprint: 'true'
    jira_assign_to_current_release: 'true'
  id: create-issue

- name: Use created issue ID
  run: echo "Created issue ${{ steps.create-issue.outputs.jira_issue_id }}"
```

## Environment Variables

Alternatively, you can use environment variables instead of inputs:

```yaml
- name: Create Jira Issue
  uses: left-code/jira-sit-create-issue@v1
  env:
    JIRA_URL: ${{ secrets.JIRA_URL }}
    JIRA_PAT: ${{ secrets.JIRA_PAT }}
    JIRA_USER: ${{ secrets.JIRA_USER }}
    JIRA_PROJECT_KEY: 'PROJ'
    JIRA_PROJECT_BOARD_NAME: 'Project Board'
    JIRA_ISSUE_TYPE: 'Task'
    JIRA_ASSIGN_TO_CURRENT_SPRINT: 'true'
    JIRA_ASSIGN_TO_CURRENT_RELEASE: 'true'
```

## Setup

1. Create a Jira Personal Access Token in your Jira account
2. Add the following secrets to your GitHub repository:
   - `JIRA_URL`: Your Jira instance URL
   - `JIRA_PAT`: Your Jira Personal Access Token
   - `JIRA_USER`: Your Jira username
3. Configure the action inputs or environment variables as needed
