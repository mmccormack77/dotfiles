---
description: Creates a PR that squashes the commits into one, uses the PR template, and updates Jira.
---
Follow this exact workflow to create a PR:
1. Check if the current branch is up-to-date with the origin (and obviously exists in the origin). If it is, skip to step 5, otherwise continue.
2. Rebase the branch with main.
3. Squash all commits on the branch into one, keeping only the commit message from the first (oldest) commit.
4. Force-push the squashed branch. Push is blocked by the administrator so provide a push command to run in another terminal.
5. Analyze the feature branch and review the full diff against the main branch.
6. If there are tests, documentation missing, or are `TODO` statements, request that they are created/updated before continuing.
7. Fill in the PR template at `.github/pull_request_template.md` as the PR body, completing all sections based on the analysis. If no template exists, use a structured format with summary, changes made, testing, and checklist.
8. Create the PR using `gh pr create` with the filled-in template.
9. Move the associated Jira ticket, if it exists, to "In Review" status. Infer the ticket ID from the branch name (e.g., `DATENG-431-description` → `DATENG-431`).
