#!/bin/bash
#REMOTE@ chi /usr/local/bin/kakucronjob

VERBOSE=false

if [ "$1" = "-v" ] ; then
	VERBOSE=true
fi

debug(){
	if $VERBOSE ; then
		echo $*
	fi
}

hour=$(date +%H | sed 's/^0//')
debug hour=$hour
NOW=$(date)
if [ -f codes ] ; then
	CODEFILE=codes
else
	CODEFILE=/var/www/data/kaku/codes
fi
debug CODEFILE=$CODEFILE
declare -A codemap

codefile=$(sed 's/ /_/g;s/#.*//' $CODEFILE)
for line in $codefile ; do
	debug line=$line
	key=${line%%;*}
	codes=${line##*;}
	codemap[$key]=$codes
	debug codemap filling $key=$codes ${codemap[$key]}
done

debug test ${codemap[test]}

if [ -f data ] ; then
	DATAFILE=data
else
	DATAFILE=/var/www/data/kaku/data
fi
debug DATAFILE=$DATAFILE

if [ -x /usr/local/bin/newkaku ] ; then
	KAKU=/usr/local/bin/newkaku
else
	KAKU=/bin/echo
fi
debug KAKU=$KAKU

kakucode(){
	debug entering kakucode
	code="$1"
	sub="$2"
	state="$3"
	codes=${codemap[$code]}
	debug code=$code sub=$sub state=$state
	debug codes=$codes
	while [ "$codes" != "" ] ; do
		c=${codes%%,*}
		codes=${codes#*,}
		if [ "$codes" = "$c" ] ; then
			codes=''
		fi
		$KAKU $c $sub $state | logger 2>&1
	  	sleep 1
		$KAKU $c $sub $state | logger 2>&1
	done
}
		
if $VERBOSE ; then
	echo -n "on: "
	cat $DATAFILE | grep "on$hour;" | sed 's/,.*//' 
fi
cat $DATAFILE | grep "on$hour;" | sed 's/,.*//' |
while read code ; do
	  logger "KAKU ON $NOW - $hour: $code"
	  debug kakucode $code 1 on 
	  kakucode $code 1 on 
	  sleep 1
	  kakucode $code 1 on 
	  sleep 1
done

if $VERBOSE ; then
	echo ""
	echo -n "off: "
	cat $DATAFILE | grep "off$hour;" | sed 's/,.*//' 
fi
cat $DATAFILE | grep "off$hour;" | sed 's/,.*//' |
while read code ; do
	  logger "KAKU OFF $NOW - $hour: $code"
	  debug kakucode $code 1 off 
	  kakucode $code 1 off 
	  sleep 1
	  kakucode $code 1 off 
	  sleep 1
done

if $VERBOSE ; then
	echo ""
fi
