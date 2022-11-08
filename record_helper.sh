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
# ----------------------------------------------------------------------------
# 2022-11-03  v0.1  www.axel-hahn.de  init
# 2022-11-07  v0.2  www.axel-hahn.de  enable external config; add pls + mpegxurl as stream
# 2022-11-08  v0.3  www.axel-hahn.de  add support for MyOggRadio plugin: read from a local pls file
# ============================================================================

# ----------------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------------

_version=0.2
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


# ----------------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------------

# show headline 2
# paramm string  message text
function _h2(){
    echo -e "\e[36m>>> $*\e[0m" >&2
}

# show a debug info
# paramm string  message text
function _wd(){
    echo -e "\e[1;30mDEBUG $*\e[0m" >&2
}
# show a debug info
# paramm string  message text
function _exit_with_error(){
    echo -e "\e[1;31m$*\e[0m" >&2
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

    test -z "$_header" && _header=$( curl -I -L --connect-timeout $_iTimeout "$_url" 2>/dev/null )
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
    echo "$_header" | grep -iE "^http/.*(404|50.)" >/dev/null
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
    echo "$_newUrl" | grep "\.m3u$" >/dev/null                                && _bRead1stLine=1
    echo "$_header" | grep -iE "^(Content-Type:.*audio/x-mpegurl)" >/dev/null && _bRead1stLine=1

    if [ $_bRead1stLine = 1 ]; then
        _wd "reading 1st url from m3u playlist [$_newUrl] ..."
        _newUrl=$( curl -L -k --connect-timeout $_iTimeout "$_newUrl" 2>/dev/null | head -1 )
    fi

    if echo "$_newUrl" | grep -v "://" | grep "\.pls" >/dev/null; then
        _wd "scan pls file [$_newUrl] ..."
        _newUrl=$( cat "$_newUrl" | grep "^File.*=.*http" | head -1 | cut -f 2- -d "=" )
    fi

    test "$_url" != "$_newUrl" && (
        echo "Set streaming url to [$_newUrl]"
        _showHttpResponseHeader "$_newUrl"
    ) || (
        echo "Url does not change."
    )
    _url="$_newUrl"
    
    echo
}

# when detecting a file ... check if it is a playlist file
# param  string  http response header
function _detectPlaylist(){
    local _header="$1"
    echo "$_header" | grep -i "^Content-Type: application/vnd.apple.mpegurl" >/dev/null 
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
    _meta=$( ffprobe "$1" 2>&1 | grep -E "(title|artist|date)" )
    if test -n "$_meta"; then
        _title=$(  _getMetaItem "$_meta" "title" "unknown_title" )
        _artist=$( _getMetaItem "$_meta" "artist" "unknown_artist" )
        _year=$(   _getMetaItem "$_meta" "date"  "" )
        test -n "$_year" && _year=" (${_year})"
        echo "${_title} - ${_artist}${_year}.mp3"
    fi
}

# ----------------------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------------------

echo >&2
echo -en "\e[1;33m">&2
echo "_______________________________________________________________________________">&2
echo
echo "                         ⡀⣀ ⢀⡀ ⢀⣀ ⢀⡀ ⡀⣀ ⢀⣸   ⣇⡀ ⢀⡀ ⡇ ⣀⡀ ⢀⡀ ⡀⣀ " >&2
echo ">>>>> Axels Streamtuner  ⠏  ⠣⠭ ⠣⠤ ⠣⠜ ⠏  ⠣⠼   ⠇⠸ ⠣⠭ ⠣ ⡧⠜ ⠣⠭ ⠏             v$_version" >&2
echo >&2
echo -e "      url: [$_url]" >&2
echo "_______________________________________________________________________________">&2
echo -e "\e[0m" >&2
echo >&2

test -z "$_url" && _exit_with_error "ERROR: no url was given"

# ---------- LOAD CONFIG
# this section works but is not used yet ... so I comment it
_h2 "Load config"
_wd "loading $( dirname $0 )/config/default"
defaultcfg=$( dirname $0 )/config/default
test -f "$defaultcfg" || cp "${defaultcfg}.dist" "$defaultcfg"
if ! . $( dirname $0 )/config/default; then
    _exit_with_error "Failed to load config"
fi

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
    _sType="stream"
    _wd "It will be handled as a stream. I hope it is a playlist."
else
    # ---------- DETECT
    _h2 "Url detected - detect if it is a file or a stream ..."
    _header=$( curl -I -L --connect-timeout $_iTimeout "$_url" 2>/dev/null )
    _showHttpResponseHeader "$_url" "$_header"

    test -z "$_header"         && _exit_with_error "ERROR: No response from target server."
    _detectHttpFail "$_header" && _exit_with_error "ERROR: unable to reach target server."

    if _detectHttpIsStream "$_header"; then
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
        curl -i --connect-timeout $_iTimeout --output "$_dirfiles/$_outfile" "$_url"
        echo

        if [ "$_outfile" = "$_tmpdlfile" ]; then
            # ffprobe "$1" 
            _outfile=$( _getmp3filename $_dirfiles/$_tmpdlfile )
            if [ -z "$_outfile" ]; then
                echo "$_header"; echo -n "filename to write >" 
                read -r _outfile
            fi
            mv "$_dirfiles/$_tmpdlfile" "$_dirfiles/$_outfile"
        fi
        _h2 "Output:"
        ls -l "$_dirfiles/$_outfile" && ( echo; echo; echo "ALL DONE. A single file was downloaded."; echo )
        ;;
    "stream")
        _h2 "detect url to a real stream"
        _detectStreamUrl "$_header" # this overrides global var _url

        _h2 "starting streamripper ..."
        streamripper -v
        echo -e "\e[34m"
        set -vx
        streamripper "$_url" -u "$_userAgent" -d "$_dirstreamripper" -m 10
        set +vx
        echo -e "\e[0m"
        ;;
    *)
        echo "type [$_sType] is unknown."
esac
_wait
exit

# ----------------------------------------------------------------------------
