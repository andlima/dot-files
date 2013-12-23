#!/bin/bash
FILES=".emacs .tmux.conf .gitconfig"
for i in $FILES; do
    ln -s $(pwd)/$i ~/$i
done
