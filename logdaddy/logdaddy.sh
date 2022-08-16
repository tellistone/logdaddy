#!/bin/bash
#
# Copyright (c) 2022 TULLY ELLISTONE, UNTAMED MANBEAST
# 
#
echo
echo " /££        /££££££   /££££££    /£££££££   /££££££  /£££££££  /£££££££  /££     /££"
echo "| ££       /££__  ££ /££__  ££  | ££__  ££ /££__  ££| ££__  ££| ££__  ££|  ££   /££/"
echo "| ££      | ££  \ ££| ££  \__/  | ££  \ ££| ££  \ ££| ££  \ ££| ££  \ ££ \  ££ /££/ "
echo "| ££      | ££  | ££| ££ /££££  | ££  | ££| ££££££££| ££  | ££| ££  | ££  \  ££££/  "
echo "| ££      | ££  | ££| ££|_  ££  | ££  | ££| ££__  ££| ££  | ££| ££  | ££   \  ££/   "
echo "| ££      | ££  | ££| ££  \ ££  | ££  | ££| ££  | ££| ££  | ££| ££  | ££    | ££    "
echo "| ££££££££|  ££££££/|  ££££££/  | £££££££/| ££  | ££| £££££££/| £££££££/    | ££    "
echo "|________/ \______/  \______/   |_______/ |__/  |__/|_______/ |_______/     |__/    "
echo
# 
# - Welcome to the guts of the gangsta graylog log spam tool! Version 1.1 (03-08-2022)
#
# - EDIT THESE VARIABLES AS REQUIRED:
# 

# - (Default used only if none specified when running script) define over how many seconds the logs are sent. Low numbers = faster sending!

timeSeconds=180

# - Define IP of Graylog server.

server=127.0.0.1

# - Define IP of Graylog fowarder This is where logs for port 13301_* are sent. If you don't have a fowarder set up, just set it to IP of Graylog Server.

fowarderserver=127.0.0.1


#
# - END OF DEFAULT VARIABLES
#
# - DONT EDIT ANYTHING ELSE, YOU WILL VOID THE WARRANTY
#


# - Use flags to override default variables

while getopts 'l:t:i:s:f:' OPTION; do
  case "$OPTION" in
    l)
      runcount="$OPTARG"
      ;;
    t)
      timecount="$OPTARG"
      ;;
    i)
      ingestcount="$OPTARG"
      ;;
    s)
      server="$OPTARG"
      ;;
    f)
      forwarderserver="$OPTARG"
      ;;
    ?)
      echo "script usage: $(basename \$0) [-l ] [-t] [-a] [-s ipaddress] [-f ipaddress]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

cwd=$PWD
launchDir=${cwd}/bin
logDir=${cwd}/log
beats=${cwd}/cache/beats
nxlog=${cwd}/cache/nxlog

# - Clear the beats and nxlog cache  
rm -r $beats/*
rm -r $nxlog/*

# - Read the parameters yo!
re='^[0-9]+$'
if ! [[ "$runcount" =~ $re ]] ; then
   runcount=1
fi

if ! [[ "$timecount" =~ $re ]] ; then
   timecount=$timeSeconds
fi
  timeSeconds=$timecount

if ! [[ "$ingestcount" =~ $re ]] ; then
   ingestcount="switched off"
fi

# - crunch the big brain numbers to set log spam speed
sizeBytes=$(du -hsB 1 $logDir | cut -f 1 -d $'\t')
sizeMegaBytes=$(awk 'BEGIN {printf "%.2f\n", '$sizeBytes'/1048576}')

volumePerSecond=$(awk 'BEGIN {printf "%.2f\n", '$sizeMegaBytes'/'$timeSeconds'}')
volumePerDayEquivalent=$(awk 'BEGIN {printf "%.2f\n", '$volumePerSecond'*86400}')

# - if the ingest parameter is used, ignore the time parameter and yolo the values
if [[ $ingestcount =~ $re ]] ; then
    volumePerDayEquivalent=$(awk 'BEGIN {printf "%.1f\n", '$ingestcount'*1024}')
    volumePerSecond=$(awk 'BEGIN {printf "%.4f\n", '$volumePerDayEquivalent'/86400}')
    timeSeconds=$(awk 'BEGIN {printf "%.4f\n", '$sizeMegaBytes'/'$volumePerSecond'}')  
fi
volumePerDayEquivalentGB=$(awk 'BEGIN {printf "%.1f\n", '$volumePerDayEquivalent'/1024}')

# - console flavour text!
echo
echo "logs will be sent over the next $timeSeconds seconds, repeating $runcount times (Note: 0 = infinite times)"
echo
echo "total logs to be sent: $sizeMegaBytes Mb"
echo
echo "Traffic per second will be $volumePerSecond Mb"
echo
echo "Equivalent rate to daily traffic of $volumePerDayEquivalent Mb ($volumePerDayEquivalentGB Gb)"
echo

# - Defining the main loop
actions() {

port=1514
for f in ${logDir}/1514_*/*;
do
       echo "Processing $f"	
       perl $launchDir/replay-syslog.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port &>/dev/null &
done

port=1510
for f in ${logDir}/1510_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port &>/dev/null &
done

port=4739
for f in ${logDir}/4739_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port &>/dev/null &
done

# - filebeats input, calls a different script
port=5044
for f in ${logDir}/5044_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog-to-cache-dir.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port --cache $beats &>/dev/null &
done

port=5555
for f in ${logDir}/5555_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port &>/dev/null &
done

# - nxlog input, calls a different script
port=12201
for f in ${logDir}/12201_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog-to-cache-dir.pl --no-loop --server $server --timeseconds $timeSeconds --file $f --port $port --cache $nxlog &>/dev/null &
done


# - fowarder input, sends to fowarder instead of graylog server!
port=13301
for f in ${logDir}/13301_*/*;
do
       echo "Processing $f"
       perl $launchDir/replay-syslog.pl --no-loop --server $fowarderserver --timeseconds $timeSeconds --file $f --port $port &>/dev/null &
done

}

# - ok now it is defined.. start the main loop!
actions

# - shitty logic to make the script loop based in 1st parameter
runcount=$(($runcount - 1))

while [ $runcount != 0 ]; do
   echo "Looping again in $timeSeconds seconds"
   sleep $timeSeconds
   echo "Resuming loop"
   actions # Loop execution
   runcount=$(($runcount - 1))
done

# Logdaddy mission accomplished
echo "logdaddy has finished.."
echo
