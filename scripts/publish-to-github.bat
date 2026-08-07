@echo off
REM Publish apnic62-workshop to GitHub (run from repo root)
REM Prerequisites: git, gh CLI, authenticated gh session

set REPO=thcorre/apnic62-workshop

if not exist .git (
  git init
  git branch -M main
)

git add -A
git status

echo.
echo Review staged files, then run:
echo   git commit -m "Initial APNIC62 WAN workshop repository"
echo   gh repo create %REPO% --public --source=. --remote=origin --push
echo.
echo If the repo already exists:
echo   git remote add origin https://github.com/%REPO%.git
echo   git push -u origin main
