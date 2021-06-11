# HDFView
alias hdfview='/opt/HDFView/3.1.1/hdfview.sh'

# PyCharm
function pcm() {
	pycharm $@ &> /dev/null & disown
}
alias pcmt='pycharm . &> /dev/null & disown'
