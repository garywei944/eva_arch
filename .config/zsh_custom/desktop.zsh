# PyCharm
function pcm() {
	pycharm $@ &> /dev/null & disown
}
alias pcmt='pycharm . &> /dev/null & disown'
