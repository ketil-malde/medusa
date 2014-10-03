#!/bin/bash
set -uf -o pipefail

. "$MDZ_DIR/functions.sh"

TMP_ST=/tmp/tmp_species_list
path="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX"

htmlnavbar(){
    cat <<EOF
      <div id="navbar">
        <a href="/">home</a>
EOF
    echo "<a href=\"/$MDZ_WEBSITE_DATA_PREFIX\">browse</a>"
    cat <<EOF
        <a href="/TSN">index</a>
        <a href="mailto:ketil.malde@imr.no">feedback</a>
        <a href="/cgi-bin/omega/omega">search</a>
	<form style="display: inline;" method="POST" action="/cgi-bin/omega/omega">
	  <input style="display: inline; margin: 2px 20px;" type="text" name="P" value="" />
	  <input type="hidden" name="DB" value="medusa" />
	</form>
    </div>
EOF
}

htmlhead(){
    echo "<html><head><title>$1</title>"
    cat <<EOF
      <link rel="shortcut icon" href="/images/favicon.jpg" />
      <link rel="stylesheet" type="text/css" href="/css/default.css" />
    </head>
    <body>
EOF
    htmlnavbar
    echo "<div id=\"header\"><h1>$1</h1></div>"
}

htmlfoot(){
    echo "</body></html>"
}

gen_desc(){
    xmlstarlet sel -t -m "//description" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
}

gen_prov(){
    echo "<h2>Provenance</h2>"
    xmlstarlet sel -t -m "//provenance" -c "." "$MDZ_DATADIR/$1/meta.xml" | xsltproc "$MDZ_DIR/services/website/format.xsl" - 2>/dev/null
    # discard warnings when dataset doesn't have provenance (sorry)
}

gen_files(){
    echo "<h2>Files</h2>"
    echo "<table><tr><th>Path</th><th>Description</th><th>Type</th><th>md5sum</th></tr><tr><th colspan=\"4\"><hr></th></tr>"
    DEST="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$1"
    files "$MDZ_DATADIR/$1" | while read f; do
	TYPE=$(xmlstarlet sel -t -m "//file[@path='$f']" -v @mimetype -n "$MDZ_DATADIR/$1/meta.xml")
	DESC=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "." -n "$MDZ_DATADIR/$1/meta.xml")
	MD5=$(xmlstarlet  sel -t -m "//file[@path='$f']" -v @md5 -n "$MDZ_DATADIR/$1/meta.xml")
        echo "  <tr> <td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$1/$f\">$f</a></td> <td>$DESC</td> <td>$TYPE</td> <td>$MD5</td> </tr>"
	echo "</tr>"

        mkdir -p "$DEST" || error "Failed to create directory - exiting"
        ln -fs "$MDZ_DATADIR/$1/$f" "$DEST" || error "Failed to create link - exiting"
    done
    ln -fs "$MDZ_DATADIR/$1/meta.xml" "$DEST"
    echo "</table>"
}

gen_index(){
    NAME="$1"
    htmlhead "$1"
    gen_desc "$NAME"
    gen_prov "$NAME"
    gen_files "$NAME"
    htmlfoot
}

extract_species(){
    FILE="$MDZ_DATADIR/$1/meta.xml"
    xmlstarlet sel -t -m "//species" -v "@tsn" -o "	"  -v "@sciname" -o "	" -v "." -o "	$1" -n "$FILE" 
}

build_species_table(){
    htmlhead "Species index"
    echo "  <table><tr> <th>TSN</th> <th>sciname</th> <th>Descriptions</th><th>Datasets</th></tr><tr><th colspan=\"4\"><hr></th></tr>"
    for tsn in $(cut -f1 "$TMP_ST" | sort | uniq); do
	PAT="^$tsn	"
	echo -n "  <tr><td><a href=\"/TSN/${tsn}.html\">$tsn</a></td>"
        echo -n "      <td>$(grep $PAT $TMP_ST | cut -f2 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo -n "      <td>$(grep $PAT $TMP_ST | cut -f3 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo -n "      <td>"
        grep "$PAT" "$TMP_ST" | cut -f4 | grep . | while read ds; do
	    echo -n "<a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$ds\">$ds</a> "
	done
        echo "</td></tr>"
    done
    echo "</table>"
    htmlfoot
}

mk_worms_link(){
    echo "<a href=\"http://www.marinespecies.org/aphia.php?p=taxlist&tComp=is&searchpar=3&tName=$1\">WoRMS description</a>"
}

build_species_lists(){
    for tsn in $(cut -f1 "$TMP_ST" | sort | uniq); do
	PAT="^$tsn	"
	OUT="$MDZ_WEBSITE_DIR/TSN/${tsn}.html"
	CNAME=$(grep "$PAT" "$TMP_ST" | cut -f3 | sort | uniq -c | sort -n | head -1 | cut -c9-)
	SNAME=$(grep "$PAT" "$TMP_ST" | cut -f2 | sort | uniq -c | sort -n | head -1 | cut -c9-)
	if [ -z "$SNAME" ]; then
	    TITLE="$CNAME"
	else
	    TITLE="$CNAME <em>($SNAME)</em>"
	fi
	htmlhead "$TITLE" > "$OUT"
	mk_worms_link "$tsn" >> "$OUT"
        echo "<h3>Scientific name(s)</h3><p>" >> "$OUT"
	grep "$PAT" "$TMP_ST" | cut -f2 | sort | uniq -c | sort -n | cut -c9- | sed -e 's/$/<br>/g'  >> "$OUT"
        echo "</p><h3>Vernacular name(s)</h3><p>" >> "$OUT"
	grep "$PAT" "$TMP_ST" | cut -f3 | sort | uniq -c | sort -n | cut -c9- | sed -e 's/$/<br>/g'  >> "$OUT"
        echo "</p><h3>Data sets</h3><table><tr><th>Dataset</th><th>Scientific name</th><th>Description</th></tr><tr><th colspan=\"3\"><hr></th></tr>" >> "$OUT"
	grep "$PAT" "$TMP_ST" | while read line; do
	    ds=$(echo "$line" | cut -f4)
	    sn=$(echo "$line" | cut -f2)
	    vn=$(echo "$line" | cut -f3)
	    echo "<tr><td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$ds\">$ds</a></td> <td>$sn</td> <td>$vn</td></tr> " >> "$OUT"
	done
        echo "</table>" >> "$OUT"
	htmlfoot >> "$OUT"
    done
}


# Build front page
htmlhead "Medusa Data Repository" > "$MDZ_WEBSITE_DIR/index.html" || error "Couldn't create front page - exiting"
cat "$MDZ_DIR/services/website/index_template.html" >> "$MDZ_WEBSITE_DIR/index.html" 
htmlfoot >> "$MDZ_WEBSITE_DIR/index.html" 

# Build directories
mkdir -p "$path" "$MDZ_WEBSITE_DIR/TSN" "$MDZ_WEBSITE_DIR/css" || error "Failed to make directory - exiting"
cp "$MDZ_DIR/services/website/default.css" "$MDZ_WEBSITE_DIR/css/"

cat > "$path/HEADER.html" << EOF
<html>
  <head>      
  <link rel="shortcut icon" href="/images/favicon.jpg" />
      <link rel="stylesheet" type="text/css" href="/css/default.css" />
    </head>
    <body>
EOF
htmlnavbar >> "$path/HEADER.html"
echo "<div id=\"header\"><h1>List of data sets</h1></div>" >> "$path/HEADER.html"

# Iterate over data sets
rm -f "$TMP_ST"
for name in $(ls "$MDZ_DATADIR"); do 
    if [ -f "$MDZ_DATADIR/$name/meta.xml" ]; then
	echo "Processing ${name}..."
	mkdir -p "$path/$name"
        gen_index "$name" > "$path/$name/index.html"
	extract_species "$name" >> "$TMP_ST"
    else 
       warn "$name does not appear to be a valid dataset - skipping"
    fi
done

build_species_table > "$MDZ_WEBSITE_DIR/TSN/index.html"
build_species_lists
