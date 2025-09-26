#!/bin/bash
#
# alarm_send_helis.sh
#
# Script to fetch and email a mini
# helicorder plot (suitable for BB)
# when an alarm is triggered
#
# called by earthworm sound_alarm module
#
# Original PJS, MVO, 2011-09-23
#
# modified by PJS 2012-01-25, 2012-03-14
#
# This version, PJS, 2012-08-24
# modified by RCS 18-Sep-2020 to run on winston1
# modified by RCS 25-Sep-2021 to send two helicorders
# modified by RCS 16-Dec-2022 to send one helicorder only (obspy not working)
#
# Updated to have a unique filename for each helicorder image since Apple can't write a 
# proper mail program that doesn't cache and display the same image :-?
# Deletes all images older than 5 days in the "helis" folder. PJS, 2012-08-24
#

time_stamp=`date -u +%a\ %b\ %d\ %T\ %Y`
echo $0: $time_stamp

# ====================================================================
# Calls script on opsproc3 to dial phones
# RCS, 2021-06-04
echo "Forking dialer script on opsproc3"
##( ssh seisan@172.17.102.13 "cd STUFF/src/mvo/alarm_dialer; ./alarm_dialer.sh" ) &
( ssh seisan@172.17.102.12 "cd src/alarm_dialer; ./alarm_dialer.sh" ) &
# ====================================================================
##### process command line arguments ########
#
# these are passed to this script from the sound_alarm.d file
# via the newly re-compiled earthworm sound_alarm module
#
echo "Processing arguments"
min_arg=5
if [ $# -lt $min_arg ]; then
echo "usage: $0 num_email_addresses list_of_addresses mailserver username password"
exit 1
fi
# store arguments in an array
args=("$@")
## get email addresses:
num_add=$1
last_add=$((num_add))
# loop over and concatenate addresses into a single variable:
adds=""
for add in ${@:2:$last_add}
do 
adds=$adds" --to $add"
done
## get mailserver
mailserver=${args[$((last_add+1))]}
## get username
user=${args[$((last_add+2))]}
## get password
pass=${args[$((last_add+3))]}

####### wait to allow more signal.... ######
wait_time_secs=120
echo "Waiting for "$wait_time_secs" seconds"
sleep $wait_time_secs


#### change to working directory: ##########
work_dir="/home/wwsuser/tmp/minihelis"
if [ $PWD != $work_dir ]; then
cd $work_dir
echo "Changed to working directory: "$work_dir
fi
########## fetch and prepare mini helicorder ###########
# first delete mini heli images older than n days
n=5
find ./ -iname "*HZ_MV*.jpg" -mtime +$n | xargs rm -vf
#
echo "Preparing helicorder"
# create date string to use for unique filename: (UTC)
datestr=`date -u +%Y%m%d%H%M`
#
#heli_dir='/home/mvo/data/monitoring_data/helicorder_plots'
heli_dir='/mnt/earthworm3/monitoring_data/helicorder_plots'
#
# list of stations to use, in preferred order:
#stats=( MBLY MBGH MBLG MBFR MBWH MBBY MBRY MBHA MSS1 MBGB MBFL )
# RCS, 7-Oct-2020
#stats=( MBGH MBRY MBWH )
stats=( MBLY MBFL )
#stats=( MBGH MBLG MBFR MBWH MBRY MBBY MBHA MBGB MBFL MBLY )
# loop over stations
for s in "${stats[@]}";
do
	out=$s'_HHZ_MV_'$datestr'.jpg'
   # check if file exists:
  	file=$heli_dir'/'$s'_HHZ_MV_00.'`date -u +%Y%m%d`'00.gif'

	if [ -f $file ]; then
	echo "$file exists"
	break
	fi
done

# copy over locally for now
cp -v $file .
flocal=`echo $file | awk -F/ '{print $NF}'`

# helicorder dimensions
width=852
height=639
xoffset=0

# choose a section of the image based on the time:
hr=`date -u +%-H`
if [ $hr -lt 8 ]; then
# top of image
yoffset=0
elif [ $hr -gt 15 ]; then
# bottom of image
yoffset=861
else
# somewhere in between...
yoffset=$((($hr-8)*108))
fi
# call convert to resize and crop
geom=$width"x"$height"+"$xoffset"+"$yoffset
#echo $geom
fl1=`echo $flocal | cut -d"." -f1`.jpg
#echo $fl1
convert -crop $geom $flocal $fl1
convert -resize 37.5% $fl1 $out
convert -quality 60 -trim $out $out
#convert -trim $out $out
rm -v $flocal 

# ====================================================================
# Call script to create 4-channel plot
# RCS, 2021-09-28
echo "running obspy script"
`/home/mvo/src/obspy/plot_chans.py`
# ====================================================================

###### email ##############
echo "Sending email"
## prepare email body (as html to attach/embed image)

# get alarm type and time from the sound_alarm logfile
# since this is written to before this script is called...
today=`date -u +%Y%m%d`
date_message=`grep 'at UTC' /home/seisan/ew/run_mvo/log/sound_alarm_$today.log | tail -n 1 | cut -d":" -f4-6`
# use perl to replace relevant lines
perl -pe "s/.*/$date_message/ if $. == 6" < body.html > body1.html
file_line="<img src="cid:$out"><br>"
perl -pe "s/.*/$file_line/ if $. == 8" < body1.html > body2.html
# tidy up
mv -f body2.html body.html
rm -f body1.html body2.html

# actually send email - uses smtp-cli perl script
# construct email command string:
echo "Email command:"
# changed to not use html and inline, RCS 19-Sep-2020
email_command="smtp-cli --verbose --host="$mailserver" --port 587 --enable-auth --user "$user" --pass "$pass" --from seisan@mvo.ms "$adds" --subject '"'earthworm ALARM heli'"'  --body-plain '"'helicorder fragment attached'"' --attach $out --attach fig-4chan.png" 
#email_command="smtp-cli --verbose --host="$mailserver" --port 587 --enable-auth --user "$user" --pass "$pass" --from seisan@mvo.ms "$adds" --subject '"'earthworm ALARM heli'"'  --body-plain '"'helicorder fragment attached'"' --attach $out" 
echo $email_command
# execute command to send email:
eval "$email_command"


# all done!
echo $0" completed."
exit 0






