#! /bin/bash

#set -xv

if [ $# -lt "3" ]; then
	echo " Missing Arguments "
	exit 1
fi

QIPADDR="localhost"
QPORT="8080"
SRIP="192.168.1.152"
SRPORT="9001"
TSAVEPATH="$1" 										# /media/Media/torrent/Download/Sickrage/
COMPLETEPATH="/media/Media/torrents/Complete"		# Path to Completed torrents
TNAME="$2"											# "Big.MommaS01E02-fxp"
THASH="$3"											# "sd9fd8fsd9f98df8ghd9f0"
TSLOCATION="$(dirname $TSAVEPATH)"					# /media/Media/torrent/Download
FULLPATH="$TSAVEPATH""$TNAME"						# /media/Media/torrent/Download/Sickrage/"Big.MommaS01E02-fxp"
LABEL="$(basename $TSAVEPATH)"						# Sickrage

#SickRage Only
USERNAME="7h3ju57"									# SickRage username
PASSWORD="Il0v3Kir\$tyn"								# Sickrage password
PROCESS_DIR=""$COMPLETEPATH"/SickRage"				# directory to process
WGET_OPTIONS=""
LOGIN_HTML_FILE="/dev/null"
PROCESS_HTML_FILE="/dev/null"
LOGIN_HTML_FILE="/tmp/sickrage_post_process_wget_login.html"
PROCESS_HTML_FILE="/tmp/sickrage_post_process_wget_processEpisode.html"

#Do Stuff
echo "Processing..."
curl -d "hash=$THASH" http://"$QIPADDR":"$QPORT"/command/recheck
curl -d "hashes=$THASH&category=$LABEL" http://"$QIPADDR":"$QPORT"/command/setCategory
sleep 2s

TSTATE=0
until [ $TSTATE == 1 ]
do
WAITRECHECK="$(curl -s http://$QIPADDR:$QPORT/query/torrents | jq --arg TORRENTHASH "$THASH" -c '[ .[] | select( .hash | contains($TORRENTHASH)) ]' | jq .[].state)"
if [[ $WAITRECHECK == *"checking"* ]]; then
echo " QBittorent still performing rechack, waiting ten seconds "
sleep 10s
else
TSTATE=1
#echo "$WAITRECHECK"
fi
done


#sleep 2m
if [ -d $FULLPATH ]; then
	#look for rars
	cd $FULLPATH || exit
	if [ "$(find . -maxdepth 1 -name "*.part01.rar" | wc -l)" -ge 1 ]; then
		echo " Extracting rar archive "
		unrar e -inul "*part01.rar"
	elif [ "$(find . -maxdepth 1 -name "*.part1.rar" | wc -l)" -ge 1 ]; then
		echo " Extracting rar archive "
		unrar e -inul "*.part1.rar"
	elif [ "$(find . -maxdepth 1 -name "*.rar" | wc -l)" -ge 1 ]; then
		echo " Extracting rar archive "
		unrar e -inul "*.rar"
	fi
fi

echo " Copying and hardlinking where possible "
chmod -R 777 "$FULLPATH"
cp -Rl "$FULLPATH" "$COMPLETEPATH"/"$LABEL"

if [ "$LABEL" == "SickRage" ]; then
	echo " SickRage postprocessing commencing"
	wget --quiet --save-cookies /tmp/sickrage_post_process_wget_cookies.txt -O $LOGIN_HTML_FILE --keep-session-cookies --post-data "username="$USERNAME"&password="$PASSWORD"" $WGET_OPTIONS http://$SRIP:$SRPORT/tv/login/
	wget --quiet --load-cookies /tmp/sickrage_post_process_wget_cookies.txt -O $PROCESS_HTML_FILE --post-data "proc_dir=$PROCESS_DIR&process_method=move&delete_on=on" $WGET_OPTIONS http://$SRIP:$SRPORT/tv/home/postprocess/processEpisode
	rm /tmp/sickrage_post_process_wget_cookies.txt
fi
