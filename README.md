# Sign-DNSSEC
_ _ _
###### Automatic Maintenance for Signing and Re-Signing DNSSEC Zone with Pre-Publish and Rollover Keys (ZSK)

_ _ _

- - -
- - -
- - -

##### Resign the zone every month

By default these RRSIG records have a limited lifetime which by default is 28 days. Once this period is over, these results are no longer considered valid. To prevent this you have to resign the zone


##### How it Works:
- ZSK Rollover (pre-publish key)

	1. Generate Second ZSK
	2. Publish both (public) keys, but use only the old one for signing
	3. Wait at least propagation time + TTL of the DNSKEY-RR
	4. Use new key for zone signing; leave old one published
	5. Wait at least propagation time + maximum TTL of the old zone
	6. Remove old key


### ====Usage:====

##### Automatic Maintenance Sign:

E.g. Default zone dir is: `/etc/nsd/master` 

Create:
`/etc/nsd/master/scripts`

`/etc/nsd/master/keys`

`/etc/nsd/master/backup`

`/etc/nsd/master/pk-backup`

Place those files on `/etc/nsd/master/scripts` folder

Add on crontab to run

`first "re-assinar-zona-PK"`

`Second "re-assinar-zona-RK"`

`Last "re-assinar-zona-CL"`

e.g. `/etc/crontab:`

Every day 15 run PK

Every day 18 run RK

Every day 21 run CL

make your choice

```bash
#minute (0-59)
#|	   hour (0-23)
#|      |       day of the month (1-31)
#|      |       |       month of the year (1-12 or Jan-Dec)
#|      |       |       |       day of the week (0-6 with 0=Sun or Sun-Sat)
#|      |       |       |       |       who
#|      |       |       |       |       |       commands
#|      |       |       |       |       |       |
1      23      15       *       *       root    /etc/nsd/master/scripts/re-assinar-zona-PK | mail -s "Re-Sign Zone PK" root
1      23      18       *       *       root    /etc/nsd/master/scripts/re-assinar-zona-RK | mail -s "Re-sign Zone RK" root
1      23      21       *       *       root    /etc/nsd/master/scripts/re-assinar-zona-CL | mail -s "Re-sign Zone Clean" root
```


- - -

- - -
##### When i did some changes on zone:

Just run file "**assinar-zona**" and the script will detect last re-sign method and sign like before
- - -
- - -
- - -
- - -
- - -
- - -

* * *

* Tools:
	+ FreeBSD/OpenBSD
 - [LDNS](http://www.nlnetlabs.nl/projects/ldns/){target="_blank"} >= 1.6.17
 - [NSD](http://www.nlnetlabs.nl/projects/nsd/) > 4.0.0
 - Perl5
 - tmpwatch [sysutils/tmpwatch](http://www.freshports.org/sysutils/tmpwatch/)
 - **doesn't work on Bind and bash**

* * *

- - -
- - -
- - -
- - -
### In Action - Diagram:
![](http://wekers.org/git/dnssec-pk.jpg)
![](http://wekers.org/git/dnssec-rk.jpg)
![](http://wekers.org/git/dnssec-cl.jpg)


- - -
- - -

### Security Tips

*Note the ****DNSSEC**** have a Potential for DNS amplification attack

to prevent, Implement some practices:


- [BCP38](http://tools.ietf.org/html/bcp38) - Ingress filtering 
- DNS Damping
- [RRL](http://www.nlnetlabs.nl/blog/2012/10/11/nsd-ratelimit/) - Response Rate Limiting
- [SLIP](https://www.nlnetlabs.nl/blog/2013/09/16/rrl-slip-and-response-spoofing/) Settings
- [DNSBL](http://lists.blocklist.de/lists/) Botnet Blacklist up Firewall

- - -
- - -
- - -
- - -

##### P.S.: Algorithm Rollovers

The above only allows you to do key rollovers while sticking to the same algorithm set. If you want to change your signing algorithm (e.g. SHA1 to SHA256), a more complicated process is required, and I suggest you read [RFC 6781](http://tools.ietf.org/html/rfc6781#section-4.1.4). The same applies for changing from NSEC to NSEC3.


[^]: The **.tcsh** extension in file it is not necessary, has placed only for github detect correct syntax highlighting language on source
