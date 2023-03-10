#!/bin/sh

shell=$(/usr/bin/basename "$(/bin/ps -p $$ -ocomm=)")

if [ -f "/usr/share/modules/init/$shell" ]; then
   . "/usr/share/modules/init/$shell"
else
   . /usr/share/modules/init/sh
fi
