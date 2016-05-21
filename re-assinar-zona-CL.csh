#!/bin/csh -f

# -------------------------------------------------------------------
# File: re-assinar-zona-CL                               /\
# Type: C Shell Script                                  /_.\
# By Fernando Gilli fernando<at>wekers(dot)org    _,.-'/ `",\'-.,_
# Last modified:2015-02-10                     -~^    /______\`~~-^~:
# ------------------------
# Re-signing DNSSEC Zone ZSK and Clean zone
# This method is after method Rollover keys has completed
# Tools: Nsd + ldns
# / OS : $FreeBSD
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# First  Step: Run re-assinar-zona-PK - "Pre-Publish Keys"
# Second Step: Run re-assinar-zona-RK - "Rollover Keys"
# Last   Step: Run re-assinar-zona-CL - "Cleanup Keys"
# The time for run each file is defined by your TTL config on SOA
# Put these files to run on crontab once a month, following steps
# according your TTL SOA interval
# -------------------------------------------------------------------

# Uncomment nonomatch for debug
#set nonomatch

set PDIR=`pwd`

# Set domain name
set NomeDominio="domain.com"

# Set location of zone files
set ZONEDIR="/etc/nsd/master"

# The keys are on $ZONEDIR/keys and backup on $ZONEDIR/backup

cd $ZONEDIR

echo "Cleanup Keys"

# Change serial zone in format yymmddhh
echo "Setting new Serial to Zone"
set OT=`grep serial $ZONEDIR/${NomeDominio}.zone | awk '{print $1}'`
set NT=`date +%Y%m%d%H`
perl -p -i -e "s/${OT}/${NT}/" $ZONEDIR/${NomeDominio}.zone

echo "New SOA Serial: ${NT}"

# Remove current .signed zone
rm $ZONEDIR/${NomeDominio}.zone.signed

# Signing the zone with current ZSK without put anything on zone file
#######################
echo "Re-Signing Zone"
# Search for KSK key name
set kskFile=`grep "ksk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`
# Search for ZSK key name
set zskFile=`grep "zsk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`

# Signing
ldns-signzone -n $ZONEDIR/${NomeDominio}.zone ${kskFile} ${zskFile}
# #####################

echo "ksk = ${kskFile}"
echo "zsk = ${zskFile}"

echo "Set permissions"
# Set permissions
chmod 640 $ZONEDIR/*.signed

# Remove temporary file with old key used in rollover method
rm $ZONEDIR/${NomeDominio}.zone.temp.rk

# Delete backup files oldest than 90 days
# ########
# # max age to keep files of backups in hours
set maxage="2160" # 90 days

@ days = $maxage / 24

if ( -f "/usr/local/sbin/tmpwatch" ) then
        echo "Delete backup files oldest than $days days"
         /usr/local/sbin/tmpwatch $maxage $ZONEDIR/backup/
else
        echo "tmpwatch not found"
endif

# Reload nsd and notify slave
echo "Reloading NSD.."
nsd-control reload
nsd-control notify

cd $PDIR

exit 0

#EOF
