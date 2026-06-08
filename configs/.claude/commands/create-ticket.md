---
description: Create a Jira ticket.
argument-hint: <description of the ticket>
---
Create a Jira ticket in the DATENG Jira space based on `$ARGUMENTS`. Follow this exact workflow:

## 1. Parse Arguments

- The argument is the ticket description.

## 2. Look Up Atlassian Context

- Call `atlassianUserInfo` to get the current user's account ID. This will be used for the **Requestor** field.
- Call `getAccessibleAtlassianResources` to discover the cloud ID for the Atlassian site. Use the first available resource.

## 3. Draft the Ticket

Based on the user's description, draft the following fields:

- **Summary**: A concise title (under 80 characters) that clearly describes the work.
- **Issue Type**: Infer from context — use `Task` for general work and `Bug` for defects.
- **Description**: Write in markdown format with these sections:
  - `## Summary` — 1-3 sentences explaining what needs to be done and why.
  - `## Details` — Bullet points with specific requirements, technical context, or steps. Reference file paths, modules, or patterns where relevant.
- **Acceptance Criteria**: A checkbox list (`- [ ]`) of concrete, verifiable conditions that define "done". This is a separate Jira field (`customfield_10536`), not part of the description.
- **Requestor**: The current user (from step 2), set via `customfield_10535`.

## 4. Present for Review

Present the drafted ticket to the user and ask for confirmation before creating it. Show the summary, issue type, description, and acceptance criteria. If the user wants changes, revise accordingly.

## 5. Create the Ticket

Once approved, create the ticket using the Jira MCP tool with these settings:
- **cloudId**: Use the cloud ID discovered in step 2.
- **projectKey**: Use the project key from step 1.
- **contentFormat**: `markdown`
- **additional_fields**:
  - `customfield_10536` (Acceptance Criteria): Must be in **ADF (Atlassian Document Format)**, not markdown. Use a `taskList` with `taskItem` nodes (state `"TODO"`) for checkbox items.
  - `customfield_10535` (Requestor): `{"accountId": "<user_account_id>"}` from step 2.

## 6. Confirm

After creation, provide the ticket key and a link to the ticket (e.g., `DATENG-123 — https://bbrpartners.atlassian.net/browse/DATENG-123`).
