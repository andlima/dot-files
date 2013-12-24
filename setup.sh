#!/bin/bash
FILES=".emacs .tmux.conf .gitconfig .gitignore"
for i in $FILES; do
    ln -s $(pwd)/$i ~/$i
done
