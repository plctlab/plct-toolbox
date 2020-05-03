#!/bin/bash

# This is a highly personalized tips / shortcuts.
# Feel free to use any shortcuts you like.
# The alias below are just examples.
git config --global alias.d 'diff -M -C --patience -U8'
git config --global alias.ds 'diff -M -C --patience -U8 --staged'
git config --global alias.st 'status'
git config --global alias.ci 'commit'
git config --global alias.pl 'pull'
git config --global alias.co 'checkout'
git config --global alias.br 'branch'
git config --global alias.hist 'log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short'
git config --global alias.type 'cat-file -t'
git config --global alias.dump 'cat-file -p'
git config --global alias.cb 'checkout -b'
git config --global alias.f 'fetch -v --all'
git config --global core.editor /usr/bin/vim
git config --global core.quotepath false
git config --global color.ui auto

echo "Please check your commit name and email:"
echo "  (if there are multiple valuse mapped to one perporty, the last setting works)"
echo
git config --list | grep user
echo
echo "Use these command to change your user name and email if necessary:"
echo
echo "    # per repo / project settings"
echo "    git config user.name 'your name'"
echo "    git config user.email 'your@email.address'"
echo
echo "    # global default settings"
echo "    git config --global user.name 'your name'"
echo "    git config --global user.email 'your@email.address'"
echo
echo "Have a nice day ;-)"
