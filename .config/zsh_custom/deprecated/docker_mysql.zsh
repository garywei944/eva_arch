#!/bin/zsh

# docker mysql
alias dmysql='docker run -it --rm --network host mysql mysql'
alias nasumls='docker run -it --rm --network host mysql mysql -h nas.oasis.eva -P 33060 -u root -p123456'
