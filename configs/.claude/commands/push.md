---
description: Stage, commit, and push changes to the current branch.
---
Follow this exact workflow:
1. Run `git status` and `git diff` to review all staged and unstaged changes.
2. Stage the relevant changed files. Do not stage files that contain secrets or credentials.
3. Write a concise commit message that summarizes the changes, focusing on the "why" rather than the "what".
4. Present the commit message to the user and ask for confirmation. If the user wants changes, revise the message accordingly before proceeding.
5. Commit to the current branch. Push is blocked by the administrator so provide a push command to run in another terminal.
