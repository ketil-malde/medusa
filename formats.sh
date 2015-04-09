#!/bin/bash

# check specific formats, take file path as parameter
check_format_fasta(){
    set +e
    egrep -n -m 3 -v '^>|^[A-Za-z]*$' "$1" && warn "Suspicious characters in FASTA sequence data!"
    grep -v '^>' "$1" | cut -c100- | grep -q . && warn "FASTA file contains very long lines"
    set -e
}

# check_format <path> <type>
check_format(){
    file="$1"
    type="$2"

    case "$type" in
	text/x-fasta-prot|text/x-fasta-rna|text/x-fasta-dna)
	    echo "$file har format $type, checking it..."
	    check_format_fasta "$file"
	    ;;
    esac
}
