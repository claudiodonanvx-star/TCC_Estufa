@echo off
echo == GIT STATUS ==
git status --porcelain
echo == GIT ADD ==
git add -A
echo == GIT COMMIT ==
git commit -m "Fix: admin-only crop removal + DELETE endpoint" || echo No changes to commit
echo == GIT PUSH ==
git push
echo == DONE ==
