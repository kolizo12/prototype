#committing
There is a tendency that `git init` will create a large file and wont be able to commit this into the git repo so run the command below

`git filter-branch -f --index-filter 'git rm --cached -r --ignore-unmatch dev/vpc/.terraform/'`

#Install tailman to check for secret and password and prevent a push to the git repo

# Download the talisman installer script
curl https://thoughtworks.github.io/talisman/install.sh > ~/install-talisman.sh
chmod +x ~/install-talisman.sh

# Install to a single project
#cd my-git-project
cd /Users/kolizo/EKSTERRAFORM/environments/dev/vpc
# as a pre-push hook
~/install-talisman.sh
# or as a pre-commit hook
~/install-talisman.sh pre-commit

