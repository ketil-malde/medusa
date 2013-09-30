Xapian-index service

This service indexes all metadata using Xapian.  It can
then be searched using the xapian-omega CGI.  It is mainly
a free-text index, but also tags keywords (currently the
contents of the 'species' element and 'filetype' from 
'file' elements)
