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

_checkline() {
	cd ~/byted/torch.blade/torch

	ADD_LIMIT=200 \
		INPUT_EXCLUDES='[".codebase/**","**/*.md","docs/**","**/*test*","tests/csrc/BUILD","tests/csrc/build.sh","bytedance/auto/**/*.yaml","tests/lagrange_torch/ops/bench/**","bytedance/auto/**/*generated*","bytedance/auto/**/go.sum","bytedance/lagrange_torch/csrc/device/cuda/nova/**","bytedance/lagrange_torch/nova/sparse/native/**","bytedance/lagrange_torch/csrc/torch_extension/native/","bytedance/nodus/csrc/service/**","bytedance/lagrange_torch/common/gen_pb.py","bytedance/**/*.pyi"]' \
		py ~/byted/line_checker/main.py
}

alias checkline="(_checkline)"
