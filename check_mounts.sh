#!/bin/bash
#============================================================================================
#       FILE:  check_mounts.sh
#       USAGE:  ./check_mounts.sh
#       description:  Alerts in case the current mounts do not match the /etc/fstab
#                       entries or the other way around.
#       author:  Jess Portnoy <kernel01@gmail.com>
#       VERSION:  0.4
#       CREATED:  07/13/2011 02:34:58 AM EDT
#       REVISION:  ---
#       CHANGELOG:
#       05/25/2014 03:00:00 PM MSK:
#       - Fixed messages output [patch by jazzl0ver]
#       04/19/2012 04:56:00 PM EDT:
#       - Added support for nfs4 [patch by Michael Hüm.huebner@reinform.de]
#       11/02/2012 05:07:00 PM EDT:
#       - Added support for s3fs
#       12/08/2013 06:21:00 PM EDT:
#       - Added test to touch a file in the mount, will only be checked if timeout util exists
#       - Fixed EOL prints
#=============================================================================================
if [ -f  `basename $0`/utils.sh ];then
        . `basename $0`/utils.sh
else
        STATE_OK=0
        STATE_WARNING=1
        STATE_CRITICAL=2
fi
TMP_MOUNTS_FILE=/tmp/mounts1
TMP_FSTAB_FILE=/tmp/fstab1
CLUSTER_CONF_FILE=/etc/cluster/cluster.conf
cat /etc/fstab |sed "s@\s+@\s@g;s@\(^s3fs\).*\s\(\/.*\)@\1 \2@g"|grep "nfs\|cifs\|smb\|fuse\|s3fs" |grep -v "^#"|awk '{print $1" "$2}'|sed "s@/\$@@g" |sort -u >$TMP_FSTAB_FILE
mount -t nfs|grep -v "sunrpc"|sed "s@/\$@@g;s@/ @ @g" |awk -F " " '{print $1" "$3}'> $TMP_MOUNTS_FILE
mount -t nfs4|grep -v "sunrpc"|sed "s@/\$@@g;s@/ @ @g"|awk -F " " '{print $1" "$3}'>> $TMP_MOUNTS_FILE
mount -t cifs|sed "s@/\$@@g;s@/ @ @g" |awk -F " " '{print $1" "$3}'>> $TMP_MOUNTS_FILE
mount -t smb|sed "s@/\$@@g;s@/ @ @g" |awk -F " " '{print $1" "$3}'>> $TMP_MOUNTS_FILE
mount -t fuse.s3fs|sed "s@/\$@@g;s@/ @ @g;s@s3fs#.*\s@s3fs@g" |awk -F " " '{print $1" "$3}'>> $TMP_MOUNTS_FILE
MSG=""
while read ENTRY ;do
        MP=`echo $ENTRY|awk -F " " '{print $2}'`
        timeout -s9  10s touch $MP/tmpfile
        if [ $? -ne 0 ];then
            MSG="${MSG}Failure to touch a file under $MP/tmpfile :( \n"
            RC=$STATE_CRITICAL
        fi

done <$TMP_MOUNTS_FILE
if [ -f "$CLUSTER_CONF_FILE" ];then
        while read ENTRY ;do
                MP=`echo $ENTRY|awk -F " " '{print $2}'`
                if grep -q "mountpoint=\"$MP" $CLUSTER_CONF_FILE;then
                        sed "/\\$MP/d" -i $TMP_MOUNTS_FILE
                        EXCLUDED="$EXCLUDED\n$ENTRY"
                fi
                timeout -s9  10s touch $MP/tmpfile
                if [ $? -ne 0 ];then
                    MSG="${MSG}Failure to touch a file under $MP/tmpfile :( \n"
                    RC=$STATE_CRITICAL
                fi

        done <$TMP_MOUNTS_FILE
fi
sort -u $TMP_MOUNTS_FILE >/tmp/mounts
rm $TMP_MOUNTS_FILE
TMP_MOUNTS_FILE=/tmp/mounts
if diff -u $TMP_MOUNTS_FILE $TMP_FSTAB_FILE >/tmp/mounts_fstab.diff;then
        echo -en "${MSG}All mount points are properly mounted :)\n"
        if [ -n "$EXCLUDED" ];then
                echo -en "Excluded (defined in $CLUSTER_CONF_FILE):$EXCLUDED\n"
        fi
        if [ -z "$RC" ];then
            RC=$STATE_OK
        fi
else
        echo -en "/etc/fstab and /proc/mounts are not identical :(\n\n"
        MOUNTED_NO_TAB=`grep  "^-" /tmp/mounts_fstab.diff|sed 's/--- .*//g'`
        TAB_NOT_MOUNTED=`grep  "^+" /tmp/mounts_fstab.diff|sed 's/+++ .*//g'`
        if [ -n "$MOUNTED_NO_TAB" ];then
        MOUNTED_NO_TAB_MSG=`cat  <<EOL
        <b>Warning: the following are mounted but do not have a matching /etc/fstab entry:</b>$MOUNTED_NO_TAB

EOL`
                if [ -z "$RC" ];then
                    RC=$STATE_WARNING
                fi
        fi
        if [ -n "$TAB_NOT_MOUNTED" ];then
        TAB_NOT_MOUNTED_MSG=`cat <<EOL
        <b>Critical: these are not mounted but do appear in /etc/fstab:</b> $TAB_NOT_MOUNTED
EOL`
                RC=$STATE_CRITICAL
        fi
        echo -en "${MSG}$MOUNTED_NO_TAB_MSG\n$TAB_NOT_MOUNTED_MSG\n"
fi
rm $TMP_MOUNTS_FILE $TMP_FSTAB_FILE  /tmp/mounts_fstab.diff
exit $RC
