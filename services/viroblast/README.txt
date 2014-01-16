  Viroblast service

Viroblast is a BLAST web front end.  The viroblast.sh script
generates the Viroblast data directory (a subdir "db" in the
directory pointed to by the TARGET_DIR variable) by identifying
FASTA-formatted files (protein and nucleotide) in the data
directory (identified by the DATA_DIR variable).

  Installation

Make sure you have Apache and PHP running and available.  Unpack
the viroblast tar file in /var/www (or similar directory). Viroblast
is 32-bit, so make sure your system supports 32-bit binaries. Configure
MDZ_VIROBLSAST_DIR to point to /var/www/viroblast.  Run
"mdz service viroblast".

It is also a good idea to increase the number of databases shown in
viroblast, edit viroblast.php and replace "size=4" with (say) "size=15"
on line 95. 

