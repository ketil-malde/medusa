# Notes

This can potentially overwrite existing files, so be careful.  It will
produce a main page as medusa.html and retain existing index.html
(to which you will probably want to add a link to medusa.html), but
if no index.html exists, a link will be created.

The data directory needs the "AllowOverride Indexes" to be set for
descriptions to work.  Newer versions of Apache (2.4) will ignore
descriptions otherwise, but older (2.2) will break with an Internal
Server Error and no useful response.

