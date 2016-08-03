# Medusa: A metadata-enriched distributed universal storage

This is a rough implementation of a generic data store and associated
services.  It was developed based on the need for a structured way to
manage molecular data, data with a variety of file formats and
analyses, and where a rapidly advancing technology ensures that new
formats keep coming.

## Basic structure

The repository is organized as a content adressable storage, where
objects are indexed by their SHA-1 checksum.  There is in principle no
limitation on content.

Each data set consists of a set of data objects, and a separate
metadata object, conforming to the `meta.rnc` schema.  The metadata
object describes the dataset, its relationship to other datasets, and
contains a list of data objects.

## The 'medusa' directory

This directory contains the bulk of the implementation, mostly in the
form of shell scripts.

 * [mdz](mdz) - The main driver script that sets up the
   environment and calls other commands
 * [medusa.conf.example](medusa.conf.example) - Example config file,
   copy to $HOME/.medusa.conf and edit as appropriate.

Supporting files and basic infrastructure (the shell scripts
correspond to `mdz` commands):

 * [meta.rnc](meta.rnc) - RelaxNG schema for metadata XML files
 * [mimetypes.txt](mimetypes.txt) - a list of known file types. Note that this is not
   exhaustive, and unknown file type is not an error.
 * [check.sh](check.sh) - checks the data sets given as command-line parameters
   for consistency and correctness
 * [checkall.sh](checkall.sh) - checks all data sets using `check.sh`, and outputs a
   summary
 * [prepare.sh](prepare.sh) - builds a skeleton metadata file for the given
   dataset, trying to automatically determine file types
 * [import.sh](import.sh) - calculates SHA-1 hashes, performs some
   further checks, and prompts the user before importing data into the repository
 * [export.sh](export.sh) - calculates SHA-1 hashes, performs some
   further checks, and prompts the user before importing data into the repository

Services are contained in their own subdirectories in the
[services](services) directory.  Each subdir contains a script of the
same name (plus a ".sh" extension) and optionally supporting or
configuration files.

 * [xapian-index](services/xapian-index/) - builds a generic search index using xapian and
   omega
 * [viroblast](servcies/viroblast/) - builds a Viroblast sequence search service
 * [website](servcies/website) - builds a website with metadata
    presented as web pages with links to data and index pages.

## Required software

The scripts rely heavily on
[`xmlstarlet`](http://xmlstar.sourceforge.net/) to extract information
from the metadata files.  This is availabe through most Linux
distributions, or the link above.  Unfortunately, `xmlstarlet` cannot
read RNC schemas directly, and we need
[`trang`](https://code.google.com/p/jing-trang/) to convert to RNG.
In addition, [`xsltproc`] is needed to process XSLT stylesheets.

Some of the services require special software, e.g. the viroblast
service requires
[`viroblast`](http://indra.mullins.microbiol.washington.edu/viroblast/viroblast.php),
and the xapian-index search service uses
[`xapian`](http://xapian.org/) and its
[`omega`](http://xapian.org/docs/omega/overview.html) web interface.

## Setting up

Get the necessary software, on Debian or Ubuntu, something like this
should do the trick:

    apt-get install xapian-omega xsltproc trang xmlstarlet libapache2-mod-php5

Copy and edit the `medusa.conf.example`, and store it as
`.medusa.config` in your home directory.

Take ownership of the default directory for the web server - for a
more complex setup, you will probably want to set up this as a
separate Apache service:

    sudo chown $USER /var/www/html
	sudo rm /var/www/html/index.html

Download Viroblast and unpack it in the /var/www/html (or whatever
directory MDZ_WEBSITE_DIR or MDZ_VIROBLAST_DIR points to).  Note that
you need to ensure that the `viroblast/data` directory is writable by
the webserver user.  Viroblast ships with 32-bit versions of the
BLAST+ suite, so on a 64bit system, you also need to get some
compatibility stuff:

    sudo apt-get install libc6-i386 libstdc++6:i386 zlib1g:i386 bzip2:i386

Xapian is by default installed in the /usr/lib/cgi-bin directory, but
you may need to link `mods-available/cgi.load` to `mods-enabled` in the
Apache config directory.  See also the README file in the
services/xapian-index directory.

## Adding a dataset

To add a data set, make a new subdirectory, and populate it with the
files that constitute the dataset.  Then run `mdz prepare`.

    mkdir DataSet
    mv [....] DataSet/
	mdz prepare DataSet
	
You should now have a `meta.xml` file in DataSet.  Now, edit the
metadata file, and fill in details.  When everything is satisfactory,
you can run `mdz import`, and if everything goes well, the data set is
imported into the repository.

When `mdz prepare` is run, two metadata sections are generated with
empty (that is, just an ellipsis) contents.  The `<description>`
section should contain a text describing what the data set _is_, while
the `<provenance>` section should describe how the data set _came
about_ (usually corresponding to 'methods').  Plain text is fine, and
can be used by many services, e.g. it will be indexed and searched by
the xapian/omega service.  But in order to be more directly useful,
one might want to add more structure to the text.  Currently, the
following tags are defined to help with this:

### Species

A reference to a species can be wrapped with a `<species>` tag.  The
contents is just free text, but the tag has a required attribute,
`tsn`, and an optional one `sciname`.  Typically, it would look
something like:

    <species tsn="89113" sciname="Lepeophtheirus salmonis">Atlantic salmon louse</species>

Currently, this will be indexed by xapain (so you can search for
e.g. `species:salmon`), and the website service builds a table linking
datasets to species.

### Dataset

Often it is useful to refer to other datasets.  Again, the contents is
plain text, but a required attribute must point to the dataset ID
(i.e. its directory name), and an optional attribute describes the
kind of relationship. For example:

    ...replaces the <dataset id="1234567890abcdef" rel="obsoletes">454 libraries</dataset>...

The possible values for `rel` are defined in the schema file `meta.rnc`.

### Person and location

Currently plain text fields, this is likely to change as more
structure is added in the future.

