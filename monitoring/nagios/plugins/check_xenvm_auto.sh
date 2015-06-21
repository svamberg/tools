#!/bin/bash
#
# AUTHOR       : Michal Svamberg <svamberg@civ.zcu.cz> 
# DESCRIPTION  : Check running virtuals with configuration in auto folder

TOOLSTACK=`/usr/lib/xen-common/bin/xen-toolstack`
TOOLSTACK_BASENAME=`basename $TOOLSTACK`

# test of supported toolstack
if [ "x$TOOLSTACK_BASENAME" != 'xxl' -a "$TOOLSTACK_BASENAME" != 'xxm' ]; then
	echo "This is unsupported Xen toolstack."
	exit 3
fi

VMS=`sudo $TOOLSTACK list | grep -v '^Name ' | grep -v '^Domain-0 ' | awk '{print $1}' | sort`
# VMS=`echo -e "$VMS\nzz_vms"` # use only for development or debug

AUTO=`ls /etc/xen/auto | sort` 
# AUTO=`echo -e "$AUTO\nzz_auto"` # use only for development or debug

# equality, if true, then everything is ok:
LIST=`diff -q <(echo -e "$VMS") <(echo -e "$AUTO")`
RET=$?
if [ $RET -eq 0 ] ; then
	VMS_JOIN=`echo $VMS | tr "\\n" " "`
	echo "OK: Running virtuals: $VMS_JOIN"
	exit 0
fi

# substract (sets not equal)
LIST=`comm --output-delimiter=',' -3 <(echo "$VMS") <(echo "$AUTO") | tr ',' '\n'`
RET=$?
if [ "x$LIST" != "x" ] ; then
	# configured in /etc/xen/auto but not running -> critical
	NOT_RUN_LIST=`sort <(echo "$AUTO" ; echo "$LIST") | uniq -d | tr '\n' ' '`
	echo "Some virtuals configured in /etc/xen/auto but not running: $NOT_RUN_LIST";
        exit 2	

	# not configured but running -> warning
	NOT_AUTO_LIST=`sort <(echo "$VMS" ; echo "$LIST") | uniq -d | tr '\n' ' '`
	echo "Some virtuals not configured in /etc/xen/auto but running: $NOT_AUTO_LIST";
	exit 1
fi

echo "Unknown problem, see source of plugin code."
exit 3

