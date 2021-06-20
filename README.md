# eva_arch

![](arch_neofetch.png)

Custom Arch Linux configurations and dotfiles

## Usage
To clone the repo to the existing user home directory and preserve other files, I use the following commands
```bash
cd ~ || exit
rm -fr .git
git init
git remote add origin https://github.com:garywei944/eva_arch.git
git config core.excludesFile .eva.gitignore
git fetch
git reset --hard origin/main
git branch -m master main
git branch --set-upstream-to=origin/main main
```

## `.gitignore` and `.eva.gitignore`
Some useful file search tools like `rg` or `fd` checks `.gitignore` before they open a subdirectory or read a file to improve performance. But maintaining a regular `.gitignore` file at the user's home directory makes these improvement trivial and useless. So my workaround is to use `.eva.gitignore` instead of `.gitignore` by adding a project level configuration `core.excludesFile`. Note that `git` still response for a `.gitignore` file in every directory.
