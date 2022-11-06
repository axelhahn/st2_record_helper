#!/bin/bash
# ============================================================================
#
# CLEANUP SCRIPT for streamripper download directory
#
# ----------------------------------------------------------------------------
# 2022-11-06  v0.1  www.axel-hahn.de  init
# ============================================================================

. $( dirname $0 )/config/default

test -z "$_dirstreamripper" && echo "ERROR _dirstreamripper is empty. Aborting."
test -z "$_dirstreamripper" && exit 1

cd "$_dirstreamripper" || exit 1

echo
echo ">>>>> CLEANUP STREAMING DIRS [$(pwd)]"
echo
find . -maxdepth 1 -type d | grep -v "^.$" | sort | while read -r stationdir
do
    echo "--- ${stationdir}/"
    # printf "%-40s" "${stationdir}/ ..."
    # echo -n "${stationdir}/ ... "
    typeset -i iFiles=$(find "$stationdir" -maxdepth 1 -type f | wc -l )
    printf "      +--- contains    : %4s files ... " "$iFiles"
    test $iFiles -eq 0 && (
        echo -n "DELETE ... "
        rm -rf "${stationdir}" && echo "OK" || echo "FAILED"
    ) || (
        echo "KEEP"
        typeset -i iFiles2=$(find "$stationdir/incomplete" -maxdepth 1 -type f | wc -l )
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