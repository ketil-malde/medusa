Xapian-index service

This service indexes all metadata using Xapian.  It can
then be searched using the xapian-omega CGI.  It is mainly
a free-text index, but also tags keywords (currently the
contents of the 'species' element and 'filetype' from 
'file' elements)

The index can be searched using the omega CGI, make sure
that the search specifies DB=medusa (or whatever database is
specified in $TARGET_DIR)

For keyword search to work, you need to add the following
configuration to the query template (typically
/usr/share/xapian-omega/templates/query):

  $setmap{prefix,species,XS}
  $setmap{prefix,file,XF}

