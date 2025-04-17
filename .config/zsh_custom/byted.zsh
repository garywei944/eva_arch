#!/bin/zsh

alias ctlag="code tunnel --name lagrange-tf"
alias ctorch="code tunnel --name torch"

black-erdos() {
    _paths=(
        "trainer/common/launcher"
        "trainer/worker"
        "trainer/runner"
        "trainer/dispatcher"
        "trainer/producer"
        "norbert/driver/coordinator"
    )

    for _path in $_paths; do
        bash black-format.sh "$_path"
    done
}
