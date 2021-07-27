#!/bin/zsh

# MetaMap Server

if [[ -d /opt/metamap_2020/public_mm/bin ]]; then
	METAMAP_HOME=/opt/metamap_2020/public_mm
elif [[ -d $HOME/Downloads/public_mm/bin ]]; then
	METAMAP_HOME=$HOME/Downloads/public_mm
fi

if [[ -n ${METAMAP_HOME+x} ]]; then
	alias startmm="sudo $METAMAP_HOME/bin/skrmedpostctl start
	sudo $METAMAP_HOME/bin/wsdserverctl start"
	alias stopmm="sudo $METAMAP_HOME/bin/skrmedpostctl stop
	sudo $METAMAP_HOME/bin/wsdserverctl stop"
fi
