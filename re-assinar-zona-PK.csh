#!/bin/csh -f

# -------------------------------------------------------------------
# File: re-assinar-zona-PK                               /\
# Type: C Shell Script                                  /_.\
# By Fernando Gilli fernando<at>wekers(dot)org    _,.-'/ `",\'-.,_
# Last modified:2015-08-08                     -~^    /______\`~~-^~:
# ----------
# Re-signing DNSSEC Zone ZSK with method pre-publish
# After pass time of TTL, we need rollover key with
# file "re-assinar-zone-RK"
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
# Keep this file on ie: $ZONEDIR/scripts
# Create also $ZONEDIR/pk-backup
# -------------------------------------------------------------------


# uncomment nonomatch if need debug
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

# Create a copy of original zone
cp $ZONEDIR/${NomeDominio}.zone $ZONEDIR/${NomeDominio}.zone.orig

# Create a new ZSK key
echo "Creating new Key ZSK"

###############
# ATTENTION ###
# Here set algorithm equal you did to sign in first time, also to key length for both (KSK and ZSK)
# eg: when you created DNSSEC in first time,
# you setting sign RSASHA256 and now you set RSASHA512 there's a problem
# your sign will be invalidated

#set NovaKey=`ldns-keygen -a RSASHA256 -b 1024 ${NomeDominio}`
set NovaKey=`ldns-keygen -a RSASHA512 -b 2048 ${NomeDominio}`

# Add the new key to zone
echo "Adding new key to zone"
cat $ZONEDIR/${NovaKey}.key >> $ZONEDIR/${NomeDominio}.zone

# Copy new key to a temporary file
echo "Doing copy of new key to $ZONEDIR/${NomeDominio}.zone.temp.pk"
cat $ZONEDIR/${NovaKey}.key > $ZONEDIR/${NomeDominio}.zone.temp.pk

# Set Permissions
chmod 640 $ZONEDIR/${NomeDominio}.zone.temp.pk

echo "Key: ${NovaKey} added"

# Remove current .signed zone
rm $ZONEDIR/${NomeDominio}.zone.signed

# Signing the zone with current ZSK and new ZSK was added in zone file
# #####################
echo "Re-Signing Zone"
# Search for KSK key name
set kskFile=`grep "ksk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`
# Search for ZSK key name
set zskFile=`grep "zsk" -l $ZONEDIR/keys/K${NomeDominio}*.key | sed 's/\.key//'`


echo "Signing with same and current key"

# Signing
ldns-signzone -n $ZONEDIR/${NomeDominio}.zone ${kskFile} ${zskFile}

echo "ksk = ${kskFile}"
echo "zsk = ${zskFile}"
# #####################

# Set permissions
chmod 640 $ZONEDIR/*.signed

# Replace original zone that was copied previously without the new ZSK key that was placed in zone file
mv $ZONEDIR/${NomeDominio}.zone.orig $ZONEDIR/${NomeDominio}.zone

###################
# Add the current key that was be old key a one temporary file, for able to do the next signing programmed, called "Roll the keys"
cat ${zskFile}.key > $ZONEDIR/${NomeDominio}.zone.temp.rk
###################

# Set permissions
chmod 640 $ZONEDIR/${NomeDominio}.zone.temp.rk

# Move current key ZSK to backup folder
echo "moving current ZSK to backup"
mv ${zskFile}.* $ZONEDIR/pk-backup/
# Move new key ZSK to /Keys folder
echo "moving new key to /keys folder"
mv $ZONEDIR/${NovaKey}.* $ZONEDIR/keys/

# Set permissionss
echo "Setting permissions.."
chmod 640 $ZONEDIR/keys/${NovaKey}.*
chmod 640 $ZONEDIR/backup/*
chmod 640 $ZONEDIR/pk-backup/*

# Reload nsd and notify slave
echo "Reloading NSD..."
nsd-control reload
nsd-control notify

cd $PDIR

exit 0

#EOF
