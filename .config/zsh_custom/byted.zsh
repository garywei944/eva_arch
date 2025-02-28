#!/bin/zsh

alias ctlag="code tunnel --name lagrange-tf"
alias ctorch="code tunnel --name torch"

black-erdos() {
    for _path in trainer/common/launcher trainer/worker norbert/driver/coordinator; do
        bash black-format.sh "$_path"
    done
}
