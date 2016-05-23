#!/bin/csh -f

# -------------------------------------------------------------------
# File: assinar-zona
# Type: C Shell Script                                  /\
# By Fernando Gilli fernando<at>wekers(dot)org         /_.\
# Last modified:2016-05-23                       _,.-'/ `",\'-.,_
# ------------------------                    -~^    /______\`~~-^~:
# Signing DNSSEC Domain Zone
# Tools: Nsd + ldns
# / OS : $FreeBSD
# -------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------
# First  Step: Run re-assinar-zona-PK - "Pre-Publish Keys" - (Add only 'new key' to zone and sign with old)
# Second Step: Run re-assinar-zona-RK - "Rollover Keys"    - (Add only 'old key' to zone and sign with new)
# Last   Step: Run re-assinar-zona-CL - "Cleanup Keys"     - (Add  'nothing key' to zone and sign with new)
# Detect what last method used and signing with same method as before
# Keep this file on ie: $ZONEDIR/scripts
# This Method is when you change something on zone already signed
# PS: Do not run this file if it's the first time that you'll sign zone.
# ---------------------------------------------------------------------------------------------------------

# Uncomment nonomatch if need debug
#set nonomatch

set PDIR=`/bin/pwd`

# Set location of zone files
set ZONEDIR="/etc/nsd/master"


# Prompt will ask for domain
echo "Insert the domain name that you want sign eg: domain.com"
set NomeDominio = $<


# check if domain zone exist
if (! -e $ZONEDIR/${NomeDominio}.zone) then
        echo "Zone file for Domain [ ${NomeDominio} ] not found, try again and type correct domain name"
        exit 0
endif

# The keys are on $ZONEDIR/keys and backup on $ZONEDIR/backup

cd $ZONEDIR


echo "Sign Zone for domain $NomeDominio"

# Change serial zone in format yymmddhh
echo "Setting new Serial to Zone"
set OT=`/usr/bin/grep serial $ZONEDIR/${NomeDominio}.zone | /usr/bin/awk '{print $1}'`
set NT=`/bin/date +%Y%m%d%H`
/usr/local/bin/perl -p -i -e "s/${OT}/${NT}/" $ZONEDIR/${NomeDominio}.zone

echo "New SOA Serial: ${NT}"

# Remove current .signed zone
/bin/rm $ZONEDIR/${NomeDominio}.zone.signed

# Create a copy of original zone
/bin/cp $ZONEDIR/${NomeDominio}.zone $ZONEDIR/${NomeDominio}.zone.orig


echo -n "Method used to sign zone previously:"

if (-e $ZONEDIR/${NomeDominio}.zone.temp.pk) then

        echo "[ re-assinar-zona-PK ]"
        echo "Re-Signing zone with Pre-Publish Keys method"
        # Search old ZSK key name
        set zskFile=`/usr/bin/grep "zsk" -l $ZONEDIR/pk-backup/K${NomeDominio}*.key | /usr/bin/sed 's/\.key//'`
        /bin/cat $ZONEDIR/${NomeDominio}.zone.temp.pk >> $ZONEDIR/${NomeDominio}.zone

else if ( (! -e $ZONEDIR/${NomeDominio}.zone.temp.pk) && (-e $ZONEDIR/${NomeDominio}.zone.temp.rk) ) then

        echo "re-assinar-zona-RK"
        echo "Re-Signing zone with Rollover Keys method"
        # Search new ZSK key name
        set zskFile=`/usr/bin/grep "zsk" -l $ZONEDIR/keys/K${NomeDominio}*.key | /usr/bin/sed 's/\.key//'`
        /bin/cat $ZONEDIR/${NomeDominio}.zone.temp.rk >> $ZONEDIR/${NomeDominio}.zone

else

        echo "re-assinar-zona-CL"
        echo "Re-Signing zone Cleanup Keys method"
        # Search current ZSK key name
        set zskFile=`/usr/bin/grep "zsk" -l $ZONEDIR/keys/K${NomeDominio}*.key | /usr/bin/sed 's/\.key//'`

endif


# Search KSK key name
set kskFile=`/usr/bin/grep "ksk" -l $ZONEDIR/keys/K${NomeDominio}*.key | /usr/bin/sed 's/\.key//'`


# Sign zone according previously method used pk, rk or cl
# #####################
# Signing zone
/usr/local/bin/ldns-signzone -n $ZONEDIR/${NomeDominio}.zone ${kskFile} ${zskFile}

echo "ksk = ${kskFile}"
echo "zsk = ${zskFile}"
# #####################

# Replace original zone that was copied before
/bin/mv $ZONEDIR/${NomeDominio}.zone.orig $ZONEDIR/${NomeDominio}.zone


echo "Setting permissions"
# Set permissions
/bin/chmod 640 $ZONEDIR/*.signed

# Reload nsd and notify slave
echo "Reloading NSD.."
/usr/local/sbin/nsd-control reload
/usr/local/sbin/nsd-control notify

cd $PDIR

exit 0

#EOF
