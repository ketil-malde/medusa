# A metadata-enriched distributed universal service archive

This is a rough implementation of a generic data store and associated
services.  It was developed based on the need for a structured way to
manage molecular data, data with a variety of file formats and
analyses, and where a rapidly advancing technology ensures that new
formats keep coming.

This is a [darcs](http://darcs.net/) repository, if you have `darcs`
installed, you can get a copy by doing

    darcs get http://malde.org/~ketil/medusa

## Basic structure

Each data set is a separate subdirectory, containing arbitrary files
and subdirectories.  A file named `meta.xml` is mandatory, and
contains the metadata describing the data set.

## The 'medusa' directory

This directory contains the bulk of the implementation, mostly in the
form of shell scripts.

 * [mdz](medusa/mdz) - The main driver script that sets up the
   environment and calls other commands
 * [medusa.conf.example](medusa.conf.example) - Example config file,
   copy to $HOME/.medusa.conf and edit as appropriate
 * [meta.rnc](medusa/meta.rnc) - RelaxNG schema for metadata XML files
 * [mimetypes.txt](medusa/mimetypes.txt) - a list of known file types. Note that this is not
   exhaustive, and unknown file type is not an error.
 * [xmlcheck.sh](medusa/xmlcheck.sh) - checks the data sets given as command-line parameters
   for consistency and correctness
 * [checkall.sh](medusa/checkall.sh) - checks all data sets using xmlcheck.sh, and outputs a
   summary
 * [gen_meta.sh](medusa/gen_meta.sh) - builds a skeleton metadata file for the given
   dataset, trying to automatically determine file types
 * [scriptindex.sh](medusa/scriptindex.sh) - builds a generic search index using xapian and
   omega
 * [index.def](medusa/index.def) - definitions for scriptindex
 * [viroblast.sh](medusa/viroblast.sh) - builds a Viroblast sequence search service

## Required software

The scripts rely heavily on
[`xmlstarlet`](http://xmlstar.sourceforge.net/) to extract information
from the metadata files.  This is availabe through most Linux
distributions, or the link above.  Unfortunately, `xmlstarlet` cannot
read RNC schemas directly, and we need
[`trang`](https://code.google.com/p/jing-trang/) to convert to RNG.

Some of the services require special software, e.g. the viroblast
service requires
[`viroblast`](http://indra.mullins.microbiol.washington.edu/viroblast/viroblast.php),
and the metadata search service uses
[`xapian`](http://xapian.org/) and its
[`omega`](http://xapian.org/docs/omega/overview.html) web interface.

## Adding a dataset

To add a data set, make a new subdirectory, and populate it with the
files that constitute the dataset.  Then run `gen_meta.sh`.

    mkdir DataSet
    mv [....] DataSet/
	medusa/gen_meta.sh DataSet
	
You should now have a `meta.xml` file in DataSet.  If you run
`medusa/xmlcheck.sh`, you will likely get some warnings.  Now, edit the
metadata file, and fill in details.  Then check it (again) with
`xmlcheck`, and when it passes, you are done as far as the system is
concerned.

When `gen_meta.sh` is run, two metadata sections are generated with
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

### Dataset

Often it is useful to refer to other datasets.  Again, the contents is
plain text, but a required attribute must point to the dataset ID
(i.e. its directory name), and an optional attribute describes the
kind of relationship. For example:

    ...replaces the <dataset id="LSalSFF" rel="supersedes">454 libraries</dataset>...

The possible values for `rel` is `supersedes`, `subsumes`, and `uses`.

### Person and location

Currently plain text fields, this is likely to change as more
structure is added in the future.

## Test dataset

A simple [test dataset](Test/) (aptly, if not imaginatively, named `Test`) is
also included.
