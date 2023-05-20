#committing
There is a tendency that `git init` will create a large file and wont be able to commit this into the git repo so run the command below

`git filter-branch -f --index-filter 'git rm --cached -r --ignore-unmatch dev/vpc/.terraform/'`

#Install tailman to check for secret and password and prevent a push to the git repo

 Download the talisman installer script
Talisman is a tool that installs a hook to your repository to ensure that potential secrets or sensitive information do not leave the developer's workstation.

It validates the outgoing changeset for things that look suspicious - such as potential SSH keys, authorization tokens, private keys etc.


`curl https://thoughtworks.github.io/talisman/install.sh > ~/install-talisman.sh`
`chmod +x ~/install-talisman.sh`

## Install to a single project
cd my-git-project
cd /Users/kolizo/EKSTERRAFORM/environments/dev/vpc
## as a pre-push hook
~/install-talisman.sh
## or as a pre-commit hook
`~/install-talisman.sh pre-commit`

##lets test this
echo "username=kola" > usefile.txt
echo "jhbdcbjdc" > password.txt
echo "apikey=Asuncviibkjbskd_njhbdjc_djbcjhd" > apikey.txt
echo "Base64encoderedsecret=U1RSSU5H" > base.txt

