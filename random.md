To remove files newly added to .gitignore

git rm --cached `git ls-files -i -c --exclude-from=.gitignore`










