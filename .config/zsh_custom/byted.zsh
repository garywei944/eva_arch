#!/bin/zsh

alias ctlag="code tunnel --name lagrange-tf"
alias ctorch="code tunnel --name torch"
alias blade-clean-erdos="fd . -d1 --hidden --exclude .vscode --exclude erdos --exclude BLADE_ROOT --exclude BLADE_ROOT.local -x rm -rf"

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
