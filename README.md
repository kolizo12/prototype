#committing
There is a tendency that `git init` will create a large file and wont be able to commit this into the git repo so run the command below

`git filter-branch -f --index-filter 'git rm --cached -r --ignore-unmatch dev/vpc/.terraform/'`

