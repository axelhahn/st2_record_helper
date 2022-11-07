#!/bin/bash
# ============================================================================
#
# CLEANUP SCRIPT for streamripper download directory
#
# ----------------------------------------------------------------------------
# 👤 Author: Axel Hahn
# 📄 Source: <https://github.com/axelhahn/st2_record_helper>
# 📜 License: GNU GPL 3.0
# ----------------------------------------------------------------------------
# 2022-11-06  v0.1  www.axel-hahn.de  init
# 2022-11-07  v0.2  www.axel-hahn.de  use typeset at beginning of the script
# ============================================================================

. $( dirname $0 )/config/default

test -z "$_dirstreamripper" && echo "ERROR _dirstreamripper is empty. Aborting."
test -z "$_dirstreamripper" && exit 1

typeset -i iFiles
typeset -i iFiles2

cd "$_dirstreamripper" || exit 1

echo
echo ">>>>> CLEANUP STREAMING DIRS [$(pwd)]"
echo
find . -maxdepth 1 -type d | grep -v "^.$" | sort | while read -r stationdir
do
    echo "--- ${stationdir}/"
    iFiles=$(find "$stationdir" -maxdepth 1 -type f | wc -l )
    printf "      +--- contains    : %4s files ... " "$iFiles"
    test $iFiles -eq 0 && (
        echo -n "DELETE ... "
        rm -rf "${stationdir}" && echo "OK" || echo "FAILED"
    ) || (
        echo "KEEP"
        iFiles2=$(find "$stationdir/incomplete" -maxdepth 1 -type f | wc -l )
        printf "      +--- [incomplete]: %4s files ... " $iFiles2
        test $iFiles2 -gt 0 && (
            echo -n "DELETE ... "
            find "$stationdir/incomplete" -maxdepth 1 -type f -delete && echo "OK" || echo "FAILED"
        ) || (
            echo "Nothing to do."
        )
    )
    echo
done

echo
echo "--- done."