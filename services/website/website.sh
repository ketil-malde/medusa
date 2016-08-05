#!/bin/bash
set -euf -o pipefail
. "$MDZ_DIR/functions.sh"

TMP_ST=/tmp/tmp_species_list
path="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX"

# Output the HTML navbar - i.e. code to generate the black bar at the top of each page
# Mostly called from `htmlhead` below
htmlnavbar(){
    cat <<EOF
      <div id="navbar">
        <a href="/">home</a>
EOF
    echo "<a href=\"/$MDZ_WEBSITE_DATA_PREFIX\">browse</a>"
    cat <<EOF
        <a href="/TSN">index</a>
        <a href="mailto:ketil.malde@imr.no">feedback</a>
        <a href="/cgi-bin/omega/omega?DB=medusa">search</a>
	<form style="display: inline;" method="POST" action="/cgi-bin/omega/omega">
	  <input style="display: inline; margin: 2px 20px;" type="text" name="P" value="" />
	  <input type="hidden" name="DB" value="medusa" />
	</form>
    </div>
EOF
}

# Output HTML header section - call this at start, and `htmlfoot` at end
htmlhead(){
    echo "<html><head><title>$1</title>"
    cat <<EOF
      <link rel="shortcut icon" href="/images/favicon.jpg" />
      <link rel="stylesheet" type="text/css" href="/css/medusa.css" />
      <meta charset="UTF-8">
    </head>
    <body>
EOF
    htmlnavbar
    echo "<div id=\"icon\"><img src=\"/medusa-icon.png\"/></div>"
    echo "<div id=\"header\"><h1>$1</h1></div>"
    echo "<div id=\"main\">"
}

# Counterpart to `htmlhead`
htmlfoot(){
    echo "</div></body></html>"
}

# Extract the description field and format it appropriately as HTML
gen_desc(){
    echo "<h2>Description</h2>"
    xmlstarlet sel -t -m "//description" -c "." "$(datafile "$1")" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
}

# Extract the provenance field and format it appropriately as HTML
gen_prov(){
    # only do this if we have a provenance field
    if [ "$(xmlstarlet sel -t -v "count(//provenance)" "$(datafile "$1")")" = "1" ]; then
      echo "<h2>Provenance</h2>"
      xmlstarlet sel -t -m "//provenance" -c "." "$(datafile "$1")" | xsltproc "$MDZ_DIR/services/website/format.xsl" -
    fi
}

# Extract the file contents and output the appropriate HTML section
gen_files(){
    echo "<h2>Files</h2>"
    echo "<table><tr><th>Path</th><th>Description</th><th>Type</th><th>checksum</th></tr><tr><th colspan=\"4\"><hr></th></tr>"
    DEST="$MDZ_WEBSITE_DIR/$MDZ_WEBSITE_DATA_PREFIX/$1"
    files "$1" | while read f; do
	TYPE=$(xmlstarlet sel -t -m "//file[@path='$f']" -v @mimetype -n "$(datafile "$1")")
	DESC=$(xmlstarlet sel -t -m "//file[@path='$f']" -v "." -n "$(datafile "$1")")
	CS=$(xmlstarlet  sel -t -m "//file[@path='$f']" -v @sha1 -n "$(datafile "$1")")
        echo "  <tr> <td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$1/$CS\">$f</a></td> <td>$DESC</td> <td>$TYPE</td> <td>$CS</td> </tr>"
	echo "</tr>"
        ln -fs "$(datafile "$CS")" "$DEST/" || error "Failed to create link - exiting"
    done
    ln -fs "$(datafile "$1")" "$DEST"
    echo "</table>"
}

gen_cite(){
    xmlstarlet sel -t -m "//cite" -v @doi -o "	" -v "." -n "$(datafile "$1")" | while read doi link; do
	cite="$(curl -sLH "Accept: text/bibliography; style=mla" "http://dx.doi.org/$doi")"
	echo -n "<li><a href=\"http://dx.doi.org/$doi\">"
        if test -z "$link"; then echo -n "[Citation]"; else echo -n "$link"; fi
	echo "</a>: $cite</li>"
    done
}

# Generate a web page for a dataset using the above functions
gen_index(){
    NAME="$1"
    htmlhead "$(xmlstarlet sel -t -m "/meta" -v "@name" "$(datafile "$1")" || true)"
    echo "<p>ID=$1</p>"
    # status is no longer a valid attribute of metadata files...
    # STATUS=$(xmlstarlet sel -t -m "/meta" -v "@status" "$(datafile "$1")" || true)
    # case "$STATUS" in
    #   invalid)
    #     htmlhead "$NAME <em class=\"error\">$STATUS</em>"
    #     ;;
    #   superseded)
    #     htmlhead "$NAME <em class=\"warn\">$STATUS</em>"
    #     ;;
    #   "")
    #     htmlhead "$NAME"
    #     ;;
    #   *)
    #     htmlhead "$NAME <em>$STATUS</em>"
    #     ;;
    # esac
    gen_desc "$NAME"
    gen_prov "$NAME"
    gen_files "$NAME"
    REFS=$(gen_cite "$NAME" || true)
    if test ! -z "$REFS"; then
       echo "<h2>References</h2><ul>"
       echo "$REFS"
       echo "</ul>"
    fi
    htmlfoot
}

# extract species info from a dataset
extract_species(){
    FILE="$(datafile "$1")"
    xmlstarlet sel -t -m "//species" -v "@tsn" -o "	"  -v "@sciname" -o "	" -v "." -o "	$1" -n "$FILE" || true
}

# Build the main species index, listing all species referenced
build_species_table(){
    htmlhead "Species index"
    echo "  <table><tr> <th>TSN</th> <th>sciname</th> <th>Descriptions</th><th>Datasets</th></tr><tr><th colspan=\"4\"><hr></th></tr>"
    for tsn in $(cut -f1 "$TMP_ST" | sort | uniq); do
	PAT="^$tsn	"
	echo -n "  <tr><td><a href=\"/TSN/${tsn}.html\">$tsn</a></td>"
        echo -n "      <td>$(grep "$PAT" "$TMP_ST" | cut -f2 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo -n "      <td>$(grep "$PAT" "$TMP_ST" | cut -f3 | grep . | sort | uniq | tr '\n' \;)</td>"
        echo -n "      <td>"
        grep "$PAT" "$TMP_ST" | cut -f4 | grep . | while read ds; do
	    echo -n "<a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$ds\">$ds</a> "
	done
        echo "</td></tr>"
    done
    echo "</table>"
    htmlfoot
}

# Link from a TSN to WoRMS entry
mk_worms_link(){
    echo "Search for <a href=\"http://www.marinespecies.org/aphia.php?p=taxlist&tComp=is&searchpar=3&tName=$1\">TSN=$1</a> in the WoRMS database."
}

# For a each TSN in the species table, generate a specific index listing datasets etc
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
	    echo "<tr><td><a href=\"/$MDZ_WEBSITE_DATA_PREFIX/$ds\">$ds</a></td> <td><em>$sn</em></td> <td>$vn</td></tr> " >> "$OUT"
	done
        echo "</table>" >> "$OUT"
	htmlfoot >> "$OUT"
    done
}

# Build cache
buildcache

# Build the front page
[ -d "$MDZ_WEBSITE_DIR" ] || mkdir -p "$MDZ_WEBSITE_DIR" || error "Website dir doesn't exist, and I couldn't create it."
htmlhead "Medusa Data Repository" > "$MDZ_WEBSITE_DIR/medusa.html" || error "Couldn't create front page - exiting"
cat "$MDZ_DIR/services/website/index_template.html" >> "$MDZ_WEBSITE_DIR/medusa.html"
htmlfoot >> "$MDZ_WEBSITE_DIR/medusa.html"
[ -f "$MDZ_WEBSITE_DIR/index.html" ] || ln -s "$MDZ_WEBSITE_DIR/medusa.html" "$MDZ_WEBSITE_DIR/index.html"

# Build directories
mkdir -p "$path" "$MDZ_WEBSITE_DIR/TSN" "$MDZ_WEBSITE_DIR/css" || error "Failed to make directory - exiting"
cp "$MDZ_DIR/services/website/medusa.css" "$MDZ_WEBSITE_DIR/css/"
cp "$MDZ_DIR/services/website/medusa-icon.png" "$MDZ_WEBSITE_DIR/"

cat > "$path/HEADER.html" << EOF
<html>
  <head>      
  <link rel="shortcut icon" href="/images/favicon.jpg" />
      <link rel="stylesheet" type="text/css" href="/css/medusa.css" />
    </head>
    <body>
EOF
htmlnavbar >> "$path/HEADER.html"
echo "<div id=\"icon\"><img src=\"/medusa-icon.png\"/></div>" >> "$path/HEADER.html"
echo "<div id=\"header\"><h1>List of data sets</h1></div>" >> "$path/HEADER.html"

# Iterate over all data sets, actually building the site
rm -f "$TMP_ST"
rm -f "$path/.htaccess"
for name in $(datasets); do 
    echo "Processing ${name}..."
    mkdir -p "$path/$name"
    gen_index "$name" > "$path/$name/index.html"
    echo "AddDescription \"$(xmlstarlet sel -t -m "/meta" -v "@name" "$(datafile "$name")" || true)\" $name" >> "$path/.htaccess"
    extract_species "$name" >> "$TMP_ST"
done

build_species_table > "$MDZ_WEBSITE_DIR/TSN/index.html"
build_species_lists
