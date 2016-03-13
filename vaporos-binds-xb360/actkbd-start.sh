#!/bin/bash
if [ -z $1 ] || [ -z $2 ];
then
echo "Usage: $0 inputdevice configfile"
exit 1
fi
/usr/sbin/actkbd -D --device $1 --config $2
