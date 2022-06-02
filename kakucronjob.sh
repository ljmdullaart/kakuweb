#!/bin/bash
#DEP tag/pgm.do_me
#REMOTE@ chi /usr/local/bin/kakucronjob

DOMOTICZ=domoticz.home:8888
domocodes=/tmp/domocodes

curl "http://$DOMOTICZ/json.htm?type=command&param=devices_list" | jq '.result[]|{value,name}|join(" ")'  | sed 's/"//g'  > $domocodes

LOG=/tmp/kakucron.log
logsize=$(ls -s $LOG | sed 's/ .*//')
if [ $logsize -ge 500 ] ; then
    mv $LOG.1 $LOG.2
    mv $LOG $LOG.1
    touch $LOG
fi

date >>$LOG

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
	echo "NO GLOBAL DATA FILE">>$LOG
else
	DATAFILE=/var/www/data/kaku/data
fi
debug DATAFILE=$DATAFILE

if [ -x /usr/local/bin/newkaku ] ; then
	KAKU=/usr/local/bin/newkaku
else
	KAKU=/bin/echo
	echo "NO KAKU COMMAND">>$LOG
fi
debug KAKU=$KAKU

kakucode(){
	debug entering kakucode
	nstate=0
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
		debug "    loop - c=$c - codes=$codes"
		if echo "$c" | grep -q '^domo' ; then
			c=${c#domo}
			idx=$(sed -n "s/ $c$//p" $domocodes);
			debug "        c=$c - idx=$idx"
			if [ "$state" = "on" ] ; then
				debug curl "http://$DOMOTICZ/json.htm?type=command&param=switchlight&idx=$idx&switchcmd=On"
				curl "http://$DOMOTICZ/json.htm?type=command&param=switchlight&idx=$idx&switchcmd=On"
			else
				debug curl "http://$DOMOTICZ/json.htm?type=command&param=switchlight&idx=$idx&switchcmd=Off"
				curl "http://$DOMOTICZ/json.htm?type=command&param=switchlight&idx=$idx&switchcmd=Off"
			fi
					
		elif echo "$c" | grep -q '^kaku' ; then
			c=${c#kaku}
			debug "$c $sub $state">>$LOG
			$KAKU $c $sub $state | logger 2>&1
	  		sleep 1
			$KAKU $c $sub $state | logger 2>&1
		else
			debug "$c $sub $state">>$LOG
			$KAKU $c $sub $state | logger 2>&1
	  		sleep 1
			$KAKU $c $sub $state | logger 2>&1
		fi
	done
}
		
if $VERBOSE ; then
	echo -n "on: "
	cat $DATAFILE | grep "on$hour;" | sed 's/,.*//' 
fi
cat $DATAFILE | grep "on$hour;" | sed 's/,.*//' |
while read code ; do
	  logger "KAKU CRON ON $NOW - $hour: $code"
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
	  logger "KAKU CRON OFF $NOW - $hour: $code"
	  debug kakucode $code 1 off 
	  kakucode $code 1 off 
	  sleep 1
	  kakucode $code 1 off 
	  sleep 1
done

if $VERBOSE ; then
	echo ""
fi
