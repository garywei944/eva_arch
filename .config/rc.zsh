#!/bin/zsh

[[ -z ${EVA+x} ]] && source $HOME/.envrc

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="astro"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$HOME/.config/zsh_custom

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Load version comparision
autoload is-at-least

if [[ -n $(command -v pacman) ]]; then
	plugins+=(archlinux)
elif [[ -n $(command -v apt-get) ]]; then
	plugins+=(ubuntu)
elif [[ -n $(command -v yum) ]]; then
	plugins+=(yum)
elif [[ -n $(command -v brew) ]]; then
	plugins+=(brew)
fi

[[ -z ${NOSUDO+x} ]] && plugins+=(sudo)

[[ -n $(command -v fd) ]] && plugins+=(fd)
[[ -n $(command -v rg) ]] && plugins+=(ripgrep)
[[ -n $(command -v heroku) ]] && plugins+=(heroku)
[[ -n $(command -v vagrant) ]] && plugins+=(vagrant)

[[ -n $(command -v aws) ]] && is-at-least 5.3 && plugins+=(aws)

[[ -n $(command -v subl) ]] && plugins+=(sublime)
[[ -n $(command -v smerge) ]] && plugins+=(sublime-merge)

plugins+=(
	systemd man screen gpg-agent
	python pip pyenv npm
	git gitignore git-flow git-flow-avh
	rsync extract
	z history zsh_reload themes zsh-autosuggestions zsh-syntax-highlighting
	conda
)



source $ZSH/oh-my-zsh.sh


# Welcome message
box_out() {
	local s=("$@") b w

	for l in "${s[@]}"; do
		((w<${#l})) && { b="$l"; w="${#l}"; }
	done
	tput setaf 3

	# Top line
	echo " -${b//?/-}-
| ${b//?/ } |"

	# Print sentences
	for l in "${s[@]}"; do
		printf '| %s%*s%s |\n' "$(tput setaf 4)" "-$w" "$l" "$(tput setaf 3)"
	done

	#Bottom line
	echo "| ${b//?/ } |
 -${b//?/-}-"
	tput sgr 0
}

if [[ -n $(command -v figlet) && -n $(command -v lolcat) ]]; then
	echo "$(echo "ariseus" | figlet)\nWelcome back, ariseus." | lolcat
elif is-at-least 5.8; then
	if [[ -n $(command -v lolcat) ]]; then
		box_out "Welcome back, ariseus." | lolcat
	else
		box_out "Welcome back, ariseus."
	fi
else
	echo " ------------------------
|                        |
| Welcome back, ariseus. |
|                        |
 ------------------------"
fi
