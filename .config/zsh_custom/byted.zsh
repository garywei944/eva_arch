#!/bin/zsh

alias ctlag="code tunnel --name lagrange-tf"
alias ctorch="code tunnel --name torch"

black-erdos() {
    _paths=(
        "trainer/common/launcher"
        "trainer/worker"
        "norbert/driver/coordinator"
        "trainer/runner"
    )

    for _path in $_paths; do
        bash black-format.sh "$_path"
    done
}
