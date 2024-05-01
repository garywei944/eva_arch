#!/bin/zsh

alias ca="conda activate"
#alias cab="conda activate base"
alias cde="conda deactivate"

alias cel="conda env list"
alias clst="conda list"
alias cle="conda list --export"
alias cles="conda list --export > spec-file.txt"
alias cee='conda env export'
alias ceee='conda env export > environment-spec.yml'

alias conin="conda install"
alias coniny="conda install -y"

#alias cr="conda remove"
#alias cry="conda remove -y"
alias crn="conda remove -y --all -n"
#alias crp="conda remove -y --all -p"

alias ccn="conda create -y -n"
#alias ccp="conda create -y -p"
alias ccf="conda env create -f"
alias ccfe="conda env create -f environment.yml"
#alias ccfp="conda env create -f environment.yml -p .venv"

alias cconf="conda config"
alias ccss="conda config --show-source"
#alias cu="conda update"
#alias cuc="conda update -n base conda"
alias cua="conda update --all"
alias cuf="conda env update -f"
alias cufe="conda env update -f environment.yml"
alias cufep="conda env update -f environment.yml --prune"
alias cufp="conda env update --prune -f"

clink() {
  local link
  link=$(wget -O - https://www.anaconda.com/download/ 2>/dev/null | sed -ne 's@.*\(https:\/\/repo\.anaconda\.com\/archive\/Anaconda3-.*-Linux-x86_64\.sh\)\">64-Bit (x86) Installer.*@\1@p')
  echo $link
}

cver() {
  local version
  version=$(echo $(clink) | sed -ne 's/.*Anaconda3-\(.*\)-Linux-x86_64.sh/\1/p')
  echo $version
}

# Mamba alias
alias ma="mamba activate"
alias mab="mamba activate base"
alias mde="mamba deactivate"

alias mel="mamba env list"
alias mlst="mamba list"
alias mle="mamba list --export"
# alias mles="mamba list --export > spec-file.txt"
# alias mee='mamba env export'
# alias meee='mamba env export > environment-spec.yml'

alias mamin="mamba install"
alias maminy="mamba install -y"

#alias mr="mamba remove"
#alias mry="mamba remove -y"
alias mrn="mamba env remove -y -n"

alias mcn="mamba create -y -n"
#alias mcp="mamba create -y -p"
alias mcf="mamba env create -f"
alias mcfe="mamba env create -f environment.yml"
#alias mcfp="mamba env create -f environment.yml -p .venv"

alias mconf="mamba config"
alias mcss="mamba config --show-source"
#alias mu="mamba update"
#alias muc="mamba update -n base conda"
alias mua="mamba update --all"

alias muf="mamba env update -f"
alias mufe="mamba env update -f environment.yml"
alias mufep="mamba env update -f environment.yml --prune"
alias mupf="mamba env update --prune -f"

alias mel="mamba env list"
alias mlst="mamba list"
alias mle="mamba list --export"
alias meel="mamba list --export > spec-file.txt"
alias mee='mamba env export'
alias meee='mamba env export > environment-spec.yml'

alias mrqs="mamba repoquery search"
alias mrqd="mamba repoquery depends"

# All aliases for micromamba
alias mm="micromamba"
alias mma="micromamba activate"
alias mmde="micromamba deactivate"

alias mmel="micromamba env list"
alias mmlst="micromamba list"
alias mmle="micromamba list --export"

alias mmi="micromamba install"
alias mmiy="micromamba install -y"

alias mmrn="micromamba env remove -y -n"

alias mmcn="micromamba create -y -n"
alias mmcf="micromamba env create -f"
alias mmcfe="micromamba env create -f environment.yml"
