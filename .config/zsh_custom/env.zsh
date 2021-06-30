# Conda init
if [ -n ${CONDA_PATH+x} ]; then
	__conda_setup="$('$CONDA_PATH/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
		eval "$__conda_setup"
	else
		if [ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]; then
			source "$CONDA_PATH/etc/profile.d/conda.sh"
		else
			export PATH="$CONDA_PATH/bin:$PATH"
		fi
	fi
	unset __conda_setup
fi
