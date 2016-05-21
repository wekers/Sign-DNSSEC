#!/bin/csh -f

# -------------------------------------------------------------------
# File: re-assinar-zona-RK                               /\
# Type: C Shell Script                                  /_.\
# By Fernando Gilli fernando<at>wekers(dot)org    _,.-'/ `",\'-.,_
# Last modified:2015-02-10                     -~^    /______\`~~-^~:
# ------------------------
# Re-signing DNSSEC Zone ZSK with method Rollover Keys
# This method is after method Pre-publish has completed
# Next run re-assinar-zona-CL - Will cleanup zone
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


# Change serial zone in format yymmddhh
echo "Setting new Serial to Zone"
set OT=`grep serial $ZONEDIR/${NomeDominio}.zone | awk '{print $1}'`
set NT=`date +%Y%m%d%H`
perl -p -i -e "s/${OT}/${NT}/" $ZONEDIR/${NomeDominio}.zone

echo "New SOA Serial: ${NT}"

# Remove current .signed zone
rm $ZONEDIR/${NomeDominio}.zone.signed

# Signing the zone with new ZSK and old ZSK that will be added to zone file
# #####################
echo "Re-Signing Zone"
# Search for KSK key name
set kskFile=`grep "ksk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`
# Search for ZSK key name
set zskFile=`grep "zsk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`

# Create a copy of original zone
cp $ZONEDIR/${NomeDominio}.zone $ZONEDIR/${NomeDominio}.zone.orig

# Add old key to zone
cat $ZONEDIR/${NomeDominio}.zone.temp.rk >> $ZONEDIR/${NomeDominio}.zone

# Signing with new key, was created in pre-publish method
ldns-signzone -n $ZONEDIR/${NomeDominio}.zone ${kskFile} ${zskFile}
# #####################

echo "ksk = ${kskFile}"
echo "zsk = ${zskFile}"


# Set permissions
chmod 640 $ZONEDIR/*.signed

# Replace original zone that was copied previously without the old ZSK key placed in zone file
mv $ZONEDIR/${NomeDominio}.zone.orig $ZONEDIR/${NomeDominio}.zone

# Remove file that have new key, used in method pre-publish
rm $ZONEDIR/${NomeDominio}.zone.temp.pk


echo "moving old ZSK on pk-backup to backup folder"
mv $ZONEDIR/pk-backup/K${NomeDominio}.* $ZONEDIR/backup/


# Reload nsd and notify slave
echo "Reloading NSD.."
nsd-control reload
nsd-control notify

cd $PDIR

exit 0

#EOF
