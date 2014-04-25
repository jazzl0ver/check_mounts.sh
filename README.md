check_mounts.sh
===============

Verifies the current mounts correspond to those defined in /etc/fstab

The original project is at:
http://exchange.nagios.org/directory/Plugins/Network-and-Systems-Management/check_mounts-2Esh/details

Summary
=======
Return 0 [OK] if true, 1 [WARNING] if mounted but has no matching entry in /etc/fstab and 2 [CRITICAL] if an /etc/fstab entry is not currently mounted.
Supports: NFS3, NFS4, CIFS, SMBFS and S3FS mounts.

Sample usage:
$ ./check_mounts.sh

OUTPUT:
/etc/fstab and /proc/mounts are not identical :(

Critical: these are not mounted but do appear in /etc/fstab:
+//10.0.0.3/my_vol /mnt/my_vol
Verifies the current mounts correspond to those defined in /etc/fstab.
Return 0 [OK] if true, 1 [WARNING] if mounted but has no matching entry in /etc/fstab and 2 [CRITICAL] if an /etc/fstab entry is not currently mounted.
Supports: NFS3, NFS4, CIFS, SMBFS and S3FS mounts.

Sample usage:
$ ./check_mounts.sh

OUTPUT:
/etc/fstab and /proc/mounts are not identical :(

Critical: these are not mounted but do appear in /etc/fstab:
+//10.0.0.3/my_vol /mnt/my_vol

CHANGELOG
=========
05/25/2014 03:00:00 PM MSK:
- Fixed messages output [patch by jazzl0ver]
04/19/2012 04:56:00 PM EDT:
- Added support for nfs4 [patch by Michael Hübner m.huebner@reinform.de]
11/02/2012 05:07:00 PM EDT:
- Added support for s3fs
12/08/2013 06:21:00 PM EDT:
- Added test to touch a file in the mount, will only be checked if timeout util exists
- Fixed EOL prints
