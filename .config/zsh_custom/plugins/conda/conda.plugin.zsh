alias ca="conda activate"
alias cab="conda activate base"
alias cde="conda deactivate"

alias cel="conda env list"
alias cl="conda list"
alias cle="conda list --export"
alias cles="conda list --explicit > spec-file.txt"

alias ci="conda install"
alias ciy="conda install -y"

alias cr="conda remove"
alias cry="conda remove -y"
alias crn="conda remove -y --all -n"
alias crp="conda remove -y --all -p"

alias ccn="conda create -y -n"
alias ccp="conda create -y -p"
alias ccf="conda env create -f"
alias ccfe="conda env create -f environment.yml"
alias ccfp="conda env create -f environment.yml -p .venv"

alias cconf="conda config"
alias ccss="conda config --show-source"
alias cu="conda update"
alias cuc="conda update conda"
alias cua="conda update --all"
alias cuf="conda env update -f"

clink() {
	local link
	link=$(wget -O - https://www.anaconda.com/distribution/ 2>/dev/null | sed -ne 's@.*\(https:\/\/repo\.anaconda\.com\/archive\/Anaconda3-.*-Linux-x86_64\.sh\)\">64-Bit (x86) Installer.*@\1@p')
	echo $link
}

cver() {
	local version
	version=$(echo $(clink) | sed -ne 's/.*Anaconda3-\(.*\)-Linux-x86_64.sh/\1/p')
	echo $version
}


# Mamba alias
if $(command -v mamba); then
	alias mel="mamba env list"
	alias ml="mamba list"
	alias mle="mamba list --export"
	alias mles="mamba list --explicit > spec-file.txt"

	alias mi="mamba install"
	alias miy="mamba install -y"

	alias mr="mamba remove"
	alias mry="mamba remove -y"
	alias mrn="mamba remove -y --all -n"
	alias mrp="mamba remove -y --all -p"

	alias mcn="mamba create -y -n"
	alias mcp="mamba create -y -p"
	alias mcf="mamba env create -f"
	alias mcfe="mamba env create -f environment.yml"
	alias mcfp="mamba env create -f environment.yml -p .venv"

	alias mconf="mamba config"
	alias mcss="mamba config --show-source"
	alias mu="mamba update"
	alias mum="mamba update mamba"
	alias mua="mamba update --all"
	alias muf="mamba env update -f"
fi
