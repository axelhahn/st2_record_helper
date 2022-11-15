#!/bin/bash
# ============================================================================
# 
# RECORDING HELPER
# for streamtuner2
#
# ----------------------------------------------------------------------------
# 👤 Author: Axel Hahn
# 📄 Source: <https://github.com/axelhahn/st2_record_helper>
# 📜 License: GNU GPL 3.0
# 📗 Docs: <https://www.axel-hahn.de/docs/st2_record_helper/>
# ----------------------------------------------------------------------------
# 2022-11-03  v0.1  www.axel-hahn.de  init
# 2022-11-07  v0.2  www.axel-hahn.de  enable external config; add pls + mpegxurl as stream
# 2022-11-08  v0.3  www.axel-hahn.de  add support for MyOggRadio plugin: read from a local pls file
# 2022-11-09  v0.4  www.axel-hahn.de  complete check of radio plugins; more error details
# 2022-11-14  v1.0  www.axel-hahn.de  detect empty streaming url in playlist; customize colors; cli params, ...
# 2022-11-xx  v1.1  www.axel-hahn.de  check required tools | WIP ...
# ============================================================================

# ----------------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------------

_version="1.1 (dev)"
_url="$1"

# download dirs:
_dirstreamripper=~/Music/streamripper
_dirfiles=~/Music/streamripper

_tmpdlfile=_download__$( date "+%Y-%m-%d__%H_%M_%S" )

_userAgent="Axels streamtuner2 record_helper v$_version"

# curl connect timeout
_iTimeout=3

# waiting time in sec before exit
_iWait=60

_sType=
_errfile="$( dirname $0 )/error_details.txt"

# colors
_col_h1="1;33"
_col_h2="33"
_col_err="1;31"
_col_debug="36"
_col_work="34"

# ----------------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------------

# show headline 2
# paramm string  message text
function _h2(){
    echo -e "\e[${_col_h2}m>>> $*\e[0m" >&2
}

# show a debug info
# paramm string  message text
function _wd(){
    echo -e "\e[${_col_debug}mDEBUG $*\e[0m" >&2
}
# show a debug info
# paramm string  message text
function _exit_with_error(){
    echo -e "\e[${_col_err}m$*\e[0m" >&2
    _wait
    exit 1
}
# print text and wait for end or RETURN
function _wait(){
    echo -e "\e[0m"
    echo -n "... wait for $_iWait sec ... or press RETURN to exit >"
    read -rt $_iWait dummy 
    echo
    echo
}

# show http response header
# param  string  url
# param  string  optional: http response header; if not given it will be fetched
function _showHttpResponseHeader(){
    local _url="$1"
    local _header="$2"

    test -z "$_header" && _header=$( curl -I -L --connect-timeout $_iTimeout --user-agent "$_userAgent" "$_url" 2>/dev/null )
    _wd "Response header of $_url\n\r$_header" 
}
# detect a supported strem in http response
#
# examples
# Server: Icecast 2.4.99.2
# icy-name:Dark Radio - Die Darkzone im Netz ...
#
# param  string  http response header
function _detectHttpIsStream(){
    local _header="$1"
    echo "$_header" | grep -iE "^(Content-Type:.*audio/x-scpls)"    && return 0
    echo "$_header" | grep -iE "^(Content-Type:.*audio/x-mpegurl)"  && return 0
    echo "$_header" | grep -iE "^(Server: Icecast|icy-name:)"       && return 0
    return 1
}

# detect a http OK (200)
# param  string  http response header
function _detectHttpOK(){
    local _header="$1"
    echo "$_header" | grep -i "^http/.*200" >/dev/null
}

# detect a non existing or non functional stream based on http code 400 or 50x
# param  string  http response header
function _detectHttpFail(){
    local _header="$1"

    echo "$_header" | grep -iE "^http/.*(404|500|503|504)" >/dev/null || return 0
    _err=$( _getHttpDetails "$_header" )
    _exit_with_error "ERROR: unable to reach target server.\n\r$_err"
}

# detect a streaming url
# - by following all locations 
# - reading the first line if url is a m3u
# param  string  http response header
function _detectStreamUrl(){
    local _header="$1"
    local _newUrl

    local _bRead1stLine=0

    _newUrl="$_url"

    # --- (1) follow "location:"
    if echo "$_header" | grep -i "^location: " >/dev/null ; then
        _wd "take last location line from http response header\n\r$(echo "$_header" | grep -i "^location: ")"
        _newUrl=$( echo "$_header" | grep -i "^location: " | tail -1 | cut -f 2- -d ":" | tr -d " " | tr -d "\r" | tr -d "\n" )
    fi

    # --- (2) read 1st line if it is a m3u playlist
    echo "$_newUrl" | grep "\.m3u" >/dev/null                                 && _bRead1stLine=1
    echo "$_header" | grep -iE "^(Content-Type:.*audio/x-mpegurl)" >/dev/null && _bRead1stLine=1

    if [ $_bRead1stLine = 1 ]; then
        _wd "reading 1st url from playlist [$_newUrl] ..."
        _newUrl=$( curl -L -k --connect-timeout $_iTimeout --user-agent "$_userAgent" "$_newUrl" 2>/dev/null | grep -v "^#" | grep "://" | head -1 )
    fi

    if echo "$_newUrl" | grep -v "://" | grep "\.pls" >/dev/null; then
        _wd "scan local pls file [$_newUrl] ..."
        _newUrl=$( cat "$_newUrl" | grep "^File.*=.*http" | head -1 | cut -f 2- -d "=" )
    fi

    test "$_url" != "$_newUrl" && (
        if [ -z "$_newUrl" ]; then
            echo "ERROR: detected an empty streaming url. Maybe the playlist is corrupt."
        fi
        echo "Set streaming url to [$_newUrl]"
        _showHttpResponseHeader "$_newUrl"
        _detectHttpFail "$_header"
    ) || (
        echo "Url does not change."
    )
    _url="$_newUrl"
    
    echo
}

# when detecting a local file ... check if it is 
# - a playlist file of jamendo mp3 files
# return value is unix like: 0 = yes/ OK; 1 = false
function _detectFilePlaylist(){
    cat "$_url" | grep "jamendo\.com.*trackid=.*format=mp3" >/dev/null && return 0
    return 1
}
# when detecting an url ... check if it is 
# - a playlist file of jamendo mp3 files
# return value is unix like: 0 = yes/ OK; 1 = false
function _detectHttpPlaylist(){
    echo "$_url" | grep "jamendo\.com.*/tracks.*format=mp3" >/dev/null && return 0
    return 1
}

# when detecting a local file ... check if it is a playlist file of streams
# return value is unix like: 0 = yes/ OK; 1 = false
# param  string  http response header
function _detectPlaylist(){
    local _header="$1"
    echo "$_header" | grep -i "^Content-Disposition: attachment"             >/dev/null && return 1

    echo "$_header" | grep -i "^Content-Type: application/octet-stream"      >/dev/null && return 0
    echo "$_header" | grep -i "^Content-Type: application/vnd.apple.mpegurl" >/dev/null && return 0
    return 1
}

# detect a file
# param  string  http response header
function _detectFile(){
    local _header="$1"

    if echo "$_header" | grep -i "^content-length: [1-9][0-9]*" >/dev/null; then 
        if _detectPlaylist "$_header"; then
                false
        else
            true
        fi
    else
        false
    fi
}

# helper of _getmp3filename
# get a single info
# param  string  metadata (from ffprobe)
# param  string  what line to fetch; one of title|artist|date
function _getMetaItem(){
    local _meta="$1"
    local _what="$2"
    local _default="$3"
    local _out
    _out=$( echo "$_meta" | grep "$_what" | cut -f "2" -d ":" | sed "s#[^a-zA-Z0-9\.\-\ \_]##g" | sed "s#^ ##g" )
    test -n "$_out" && echo "$_out" || echo "$_default"
}

# get a generated new filename based on id3 tag of a local file
# ffprobe 1.mp3 2>&1 | grep -E "(title|artist|date)"
#     title           : Monkey Sax
#     artist          : Monkeyman
#     date            : 2012
# param  string  filename of a local mp3 file
function _getmp3filename(){
    local _meta
    _require ffprobe 1
    _meta=$( ffprobe "$1" 2>&1 | grep -E "(title|artist|date)" )
    if test -n "$_meta"; then
        _title=$(  _getMetaItem "$_meta" "title" "unknown_title" )
        _artist=$( _getMetaItem "$_meta" "artist" "unknown_artist" )
        _year=$(   _getMetaItem "$_meta" "date"  "" )
        test -n "$_year" && _year=" (${_year})"
        echo "${_title} - ${_artist}${_year}.mp3"
    fi
}

# fetch the 3 digit http stazus code number from header
# if there is a redirect with location: it will return the status of the last hop
# param  string  http response header
function _getHttpCode(){
    local _header="$1"
    echo "$_header" | grep -i "^http.* [1-9][0-9]*" | cut -f 2 -d " " | tail -1
}

# get a detailed message of a http status code
# param  string  http response header
function _getHttpDetails(){
    local _header="$1"
    local _iHttpcode
    local _sInfo
    _iHttpcode=$( _getHttpCode "$_header" )
    _sInfo=$( _getErrorDetails "http_${_iHttpcode}" )
    echo -n "Http status code $_iHttpcode"
    test -n "$_sInfo" && echo ": $_sInfo" || echo
}

# check if a binary exists in $PATH
# param  string  name of binary
function _require(){
    local _bin="$1"
    local _warningonly="$2"
    if ! which "$_bin" >/dev/null; then
        if [ -n "$_warningonly" ]; then
            echo >&2
            echo -e "\e[0mWARNING: missing an optional binary: $_bin">&2
            echo -n "Wait 5 sec ... or RETURN to continue" >&2
            read -r -t 5 >&2 
            echo >&2
            echo >&2
        else
            _exit_with_error "Missing required binary: $1"
        fi
    fi
}

# get a more detailed message to a given error code
# this function searches for the error code in error_details.txt
#param  string  an error code
function _getErrorDetails(){
    local _code="$1"
    grep -F "$_code" "$_errfile" | cut -f 2- -d "|"
}

# cleanup files in streamripper target directory.
# It removes subdirs without a file and cleans up "incomplete" subdirs
function _doCleanup(){

    typeset -i local iFiles
    typeset -i local iFiles2

    test -z "$_dirstreamripper" && _exit_with_error "ERROR: _dirstreamripper is empty. Aborting."
    cd "$_dirstreamripper" || exit 1

    _h2 "CLEANUP STREAMING DIRS [$(pwd)]"
    echo "I remove subdirs without a file and clean up 'incomplete' subdirs"
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
}

# show help text
function _doShowHelp(){
    local _self=$( basename "$0" )
echo "
HELP:
A helper script to record streams and audiofiles listed in Streamtuner2.
You can add it in Streamtuner2 settings as recording handler.

It makes several checks of a given url 
- detect last location on redirects
- read sreaming url from a m3u playlist

It shows http response header to analyze what happens.

It tries to show a clear error message to see why a stream cannot be recorded
and keeps the console window open for 60 sec that you are able to read the
message on exit.

Next to Radiostreams the donwload of single audio files is supported:
- Jamendo tracks: mp3 files
- MODarchive: all tracker files

See README.md with the list of supported streams and plugins.


Author: Axel Hahn | License: GNU GPL 3.0


SYNTAX:
$_self [OPTIONS] [URL]

OPTIONS:
    -c                cleanup empty ripping dirs and exit; start dir is
                      '$_dirstreamripper'
    -h                show this help and exit
    -t <seconds>      override connect timeout of curl; value in config: $_iTimeout
    -u <user_agent>   set another user agent; it overides value in config
                      '$_userAgent'
    -w <seconds>      override time to wait; value in config: $_iWait
"
}
# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------

echo -en "\e[${_col_h1}m"
echo "_______________________________________________________________________________"
echo
echo " Axel Hahn's           ⡀⣀ ⢀⡀ ⢀⣀ ⢀⡀ ⡀⣀ ⢀⣸   ⣇⡀ ⢀⡀ ⡇ ⣀⡀ ⢀⡀ ⡀⣀ "
echo "  Streamtuner 2        ⠏  ⠣⠭ ⠣⠤ ⠣⠜ ⠏  ⠣⠼   ⠇⠸ ⠣⠭ ⠣ ⡧⠜ ⠣⠭ ⠏               ______"
echo "________________________________________________________________________/ v$_version"
echo -e "\e[0m"

# ---------- LOAD CONFIG
defaultcfg=$( dirname $0 )/config/default
test -f "$defaultcfg" || cp "${defaultcfg}.dist" "$defaultcfg"
if ! . $( dirname $0 )/config/default; then
    _exit_with_error "Failed to load config"
fi
_wd "Config was loaded: $( dirname $0 )/config/default"

# ---------- CHECK REQUIREMENTS
_require curl
_require streamripper

# ---------- CHECK PARAMS
while getopts ":c :h :t: :u: :w:" OPT; do
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    c) _doCleanup; exit 0; ;;
    t) _iTimeout=$OPTARG; _wd "SET: connect timeout of curl [$_iTimeout] sec" ;;
    u) _userAgent="$OPTARG"; _wd "SET: user agent is [$_userAgent]" ;;
    h) _doShowHelp; exit 0; ;;
    w) _iWait=$OPTARG; _wd "SET: wait time on exit [$_iWait] sec" ;;
  esac
done

shift $((OPTIND - 1))

test -z "$*" && _doShowHelp 
test -z "$*" && _exit_with_error "ERROR: no url was given"

_url="$1"

echo
echo -en "\e[${_col_h1}m> $_url\e[0m"
echo

    # _sStreamHost=$( echo "$_url" | cut -f 3 -d "/")
    # _wd "Host: $_sStreamHost"

    # streamcfg=$( dirname $0 )/config/${_sStreamHost}
    # streamcfg=$( echo "$streamcfg" | sed "s#[\.\:]#_#g" )

    # test -r "$streamcfg" && echo "Loading $streamcfg" || _wd "SKIP - a custom config does not exist [$streamcfg]"
    # test -r "$streamcfg" && . "$streamcfg"
echo


if ! echo "$_url" | grep "://" >/dev/null
then
    _h2 "Local file detected"
    if _detectFilePlaylist; then
        _sType="download-local-playlist"
    else
        _sType="stream"
        _wd "It will be handled as a stream. I hope it is a playlist of streams."
    fi
else
    # ---------- DETECT
    _h2 "Url detected - detect if it is a file or a stream ..."
    _header=$( curl -I -L --connect-timeout $_iTimeout --user-agent "$_userAgent" "$_url" 2>/dev/null )
    _showHttpResponseHeader "$_url" "$_header"

    test -z "$_header" && _exit_with_error "ERROR: No response from target server.\n\rThe ip address or hostname does not exist anymore or the streaming service is offline."

    _detectHttpFail "$_header"

    if _detectHttpPlaylist; then
        _sType="download-playlist"
    elif _detectHttpIsStream "$_header"; then
        _sType="stream"
    else
        if _detectHttpOK "$_header"; then
            if _detectFile "$_header"; then
                _sType="file"
            else
                _sType="stream"
            fi
        else
            echo "HTTP ERROR ... unable to detect - fallback: handling it as a stream"
            _sType="stream"
        fi
    fi
fi

echo "type: $_sType"
echo

# ---------- SWITCH
case "$_sType" in
    "file")
        _outfile=$( echo "$_header" | grep -i "^Content-Disposition:.*attachment" | grep "filename=" | cut -f 2 -d "=" | tr -d "\n" | tr -d "\r" )
        test -z "$_outfile" && _outfile=$_tmpdlfile

        _h2 "Starting file download [$_dirfiles/$_outfile]..."
        echo -e "\e[${_col_work}m"
        curl -i --connect-timeout $_iTimeout --user-agent "$_userAgent" --output "$_dirfiles/$_outfile" "$_url"

        if [ "$_outfile" = "$_tmpdlfile" ]; then
            # ffprobe "$1" 
            _outfile=$( _getmp3filename $_dirfiles/$_tmpdlfile )
            if [ -z "$_outfile" ]; then
                echo "$_header"; echo -n "filename to write >" 
                read -r _outfile
            fi
            if [ -n "$_outfile" ]; then
                echo -e "\e[${_col_work}m"
                echo "renaming temporary download file $_tmpdlfile ..."
                mv "$_dirfiles/$_tmpdlfile" "$_dirfiles/$_outfile"
            fi
        fi
        echo

        _h2 "Output:"
        if [ -n "$_outfile" ]; then
            ls -l "$_dirfiles/$_outfile" && ( echo; echo; echo "ALL DONE. A single file was downloaded."; echo )
        else
            echo "removing temporary download file $_dirfiles/$_tmpdlfile ..."
            rm -f "$_dirfiles/$_tmpdlfile"
        fi
        ;;
    "download-local-playlist")
        _h2 "Multiple file download from local playlist."
        # _sPL="$( cat $_url 2>/dev/null )"
        # _wd "Playlist data: $_sPL"
        _exit_with_error "Download of files in a playlist is not implemented yet."
        ;;
    "download-playlist")
        _h2 "Multiple file download from playlist."
        # _sPL=$( curl -L --connect-timeout $_iTimeout --user-agent "$_userAgent" "$_url" 2>/dev/null )
        # _wd "Playlist data: $_sPL"
        # echo "$_sPL" | jq ".results"
        _exit_with_error "Download of files in a playlist is not implemented yet."
        ;;
    "stream")
        _h2 "detect url to a real stream"
        _detectStreamUrl "$_header" # this overrides global var _url

        _h2 "streamripper pre test ..."
        streamripper -v

        # start a pre check with recording 1 sec to detect a general streaming error
        _out=$( streamripper "$_url" -l 1 -u "$_userAgent" -d "$_dirstreamripper" -m 10 2>&1 )
        _sr_error=$( echo "$_out" | grep  "error -[1-9][0-9]* \[[A-Z]*" )

        if [ -n "$_sr_error" ]; then
            _err_detail=$( _getErrorDetails "$_sr_error" )
            _exit_with_error "ERROR: the stream recording cannot start. This is the error from streamripper:\n\r\n\r$_sr_error\n\r\n\r$_err_detail"
        else
            echo "OK: recording the stream looks fine."
            echo

            _h2 "starting streamripper ..."
            echo -e "\e[${_col_work}m"
            set -vx
            streamripper "$_url" -u "$_userAgent" -d "$_dirstreamripper" -m 10 
            set +vx
            echo -e "\e[0m"
        fi
        ;;
    *)
        echo "type [$_sType] is unknown."
esac
_wait
exit

# ----------------------------------------------------------------------------
