# Record helper script for Streamtuner 2

This script contains some logic to download different streaming types in Streamtuner 2 with streamripper.

👤 Author: Axel Hahn \
📄 Source: <https://github.com/axelhahn/st2_record_helper> \
📜 License: GNU GPL 3.0

Links to related products:

* **Streamtuner 2**: internet radio directory browser <https://sourceforge.net/projects/streamtuner2/> 
* **Streamripper**: record streams as mp3 to your hard drive <https://streamripper.sourceforge.net/>

## Why

I was a bit frustrated: why does nothing happen if I press [Record] in Streamripper 2?!
So it was my challenge: show something what happens or show an error that I am able to read and to analyze.

If this was done I saw why a few streams do not start to donload.
Do I need to fetch a real stream first by following "location:" or grep the 1st line of a m3u playlist.

With the different station plugins exist several constellations. This script is an initial point and not feature complete yet.

![screenshot](./docs/images/st2_record_helper.png)

## Installation

### Get the files

Extract archive or better: git clone the repository somewhere. If you use git clone it is easier to update all files.

I used `/home/axel/scripts/st2_record_helper/`.

```txt
cd ~/scripts
git clone https://github.com/axelhahn/st2_record_helper.git
```

### Create config

In the subdir `./config/` is a file "default.dist". Copy it to "default" (without .dist).

**Remark**:
If your user has write permissions in the config directory it will be done automatically on the first run of a record call.

### Configure Streamtuner 2

In Streamtuner2 press F12 for settings. In the record section for `audio/*` set

`konsole -e /home/axel/scripts/st2_record_helper/record_helper.sh`
or
`gnome-terminal -- /home/axel/scripts/st2_record_helper/record_helper.sh`

## Requirements

* Bash
* curl
* ffmpeg (to fetch id3 tags in Jamendo tracks)
* streamripper

It was tested on Linux only.

## Features

* You get output! Which stream was requested, http headers for details. 
* on error: a window does not just close - you have 60 sec to read it
* automatic fetching for a real streaming url in some playlist types
* support for the download of files (Jamendo, MODarchive) with automatic renaming
* remove unused streamripper output directories and cleanup of 'incomlete' dirs
* command line parameter support

## Update

If you used git clone to install:

```txt
cd ~/scripts/st2_record_helper
git pull
```
Otherwise extract the archive over existing files.

Both variants don't modify your custom configuration.

## Configuration

In the ./config/default you can set:

```shell
#!/bin/bash

# download dirs:
_dirstreamripper=~/Music/streamripper
_dirfiles=~/Music/streamripper

# custom user agent
# _userAgent="VLC/3.0.6 LibVLC/3.0.6"

# curl connect timeout
_iTimeout=3

# waiting time in sec before exit
_iWait=60

# colors
_col_h1="1;33"
_col_h2="33"
_col_err="1;31"
_col_debug="36"
_col_work="34"
```

Variable | Type | Description
---|---|---
_dirstreamripper | string | Directory for streamripper; below it creates a subdir per station
_dirfiles        | string | Directory to download single files
_userAgent       | string | override user agent
_iTimeout        | int    | curl connect timeout in sec; default: 3
_iWait           | int    | waiting time in sec before exit; default: 60
_col...          | string | override colors<br>Hint: you can try to set the console profile instead of fiddling around with color values.


## Command line parameters

Without a parameter or (better) with using -h you get a help.
The command line parameters override settings from ./config/default

```txt
> ./record_helper.sh -h
_______________________________________________________________________________

 Axel Hahn's           ⡀⣀ ⢀⡀ ⢀⣀ ⢀⡀ ⡀⣀ ⢀⣸   ⣇⡀ ⢀⡀ ⡇ ⣀⡀ ⢀⡀ ⡀⣀ 
  Streamtuner 2        ⠏  ⠣⠭ ⠣⠤ ⠣⠜ ⠏  ⠣⠼   ⠇⠸ ⠣⠭ ⠣ ⡧⠜ ⠣⠭ ⠏           ______
________________________________________________________________________/ v1.0

DEBUG Config was loaded: /home/axel/skripte/streamtuner/config/default

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
record_helper.sh [OPTIONS] [URL]

OPTIONS:
    -c                cleanup empty ripping dirs and exit; start dir is
                      '/home/axel/Music/streamripper'
    -h                show this help and exit
    -t <seconds>      override connect timeout of curl; value in config: 3
    -u <user_agent>   set another user agent; it overides value in config
                      'Axels streamtuner2 record_helper v1.0'
    -w <seconds>      override time to wait; value in config: 60

```

## Supported downloads

### Stream file donwloads

* **shoutcast + icecast streams**<br>Streamripper will be used to download each single file
* playlist **m3u** will be fetched to grep the first stream in it. That one will be put to streamripper.
* playlist **mpegurl** will be fetched to grep the first stream in it. That one will be put to streamripper.
* playlist **pls** can be handled directly by streamripper.

### Single file donwloads

Single file downloads will be handled by `curl`.

* **Jamendo**: tracks - mp3 single files<br>downloaded files will be renamed to "TITLE - ARTIST (YEAR).mp3" by using `ffprobe` (which is part of ffmpeg package)
* **MODArchiv**: mod, it, s3m, xm<br>the name of the target file is taken from http reponse header - value `filename` in field `Content-Disposition:`

### Tested ST2 channel plugins

The following list gives you a general  overview about tested channel plugins. 

**Remarks**:
- In each type of plugin - even if it is marked as functional - can be some radiostations that do not work.
- Because of internal handling for local downloads and fetching urls you can download more station in this early version already compared to configuring the download with a streamripper binary directly.

In alphabetic order:

* ✔️ **filtermusic** direct streaming urls (Icecast)
* ✔️ **Internet-Radio** PLS playlist via http(s)
* 🔶 **Jamendo**<br>
  * ◻️ radios
  * ◻️ playlists
  * ◻️ albums
  * ✔️ track - download of a single file with curl including automatic renaming
* ✔️ **LiveRadio** direct streaming urls
* ✔️ **MODarchive** download of a single file with curl; the name of the target file will be detected from `Content-Disposition:`
* ✔️ **MyOggRadio** PLS playlist in local /tmp directory
* ✔️ **RadioBrowser** direct streaming urls (Icecast)
* ◻️ **reddit** not supported; videos will be shown in VLC
* ✔️ **Shoutcast** PLS playlist via http(s)
* ✔️ **SomaFM** PLS playlist via http(s)
* ✔️ **Streema** direct streaming urls (Icecast)
* ✔️ **Surfmusic** M3U playlist via http(s) - 1st sreaming url in it will be used
* ✔️ **TuneIn** audio/x-mpegurl playlist via http(s) - 1st sreaming url in it will be used
* ✔️ **UbuntuUsers** 
  * ✔️ M3U Playlist
  * ✔️ direct streaming urls (Icecast)
* ✔️ **Xiph.org** direct streaming urls (Icecast)

## Known errors

* **error -9 [SR_ERROR_PARSE_FAILURE]** 
  The streaming url cannot be parsed. Maybe there is a wrong or unencoded character in it.

* **error -28 [SR_ERROR_INVALID_METADATA]**
  This is a bug in streamripper: t tries to request metadata in protocol version http/1.1 - but streamripper can understand http 1.0 only.

## How does it work?

I started to draw the processing of the recording script using Mermaid.

```mermaid
graph TD

  %% ------------------------------------------------------------
  %% elements
  %% ------------------------------------------------------------
  Start((Start))
  End((End))

  LoadCfg(fa:fa-file Load config)
  UrlOrFile{Given param<br>is an url or<br>a local file?}
  
  ParamIsAFile(Param is a file<br>So far local PLS files only.)
  ParamIsAUrl(Url was detected)

  FetchHttpHeader
  GotResponse{Was there<br>a response?}
  noResponse(Exit: stream or service<br>does not exist)
  yesResponse(There was a response)
  ShowHttpHeader[For debugging:<br>Show http response<br>header of given url]

  ErrorResponse{Error in response?<br>404 or 50x?}
  YesErrorResponse(Exit: Stream does not<br>exist or not available)

  DetectedStream{Detect<br>stream<br>header}
  DetectedDownload{Detect<br>download<br>file}

  subgraph streamripper
    HandleAsStream
    CheckStreamUrl(Check redirects to get<br>last target url<br>or 1st streaming url<br>from a playlist)
    SRshowVersion(Show Version of Streamripper)
    SRrecordTest(Record 1 sec of the<br>stream to test<br> streamripper error)
    SRrecordTestFailed(Show detected error)
    SRStart(Run Streamripper to<br>download the stream until<br>it breaks or you stop it.)
  end

  subgraph file download
    HandleAsDownload
    fileGetfilenameFromHeader(Get filename from feader<br>Content-Disposition)
    setFile1(Set a filename)
    setFileTemp(Set temp filename)
    DownloadWithCurl1(Download With Curl)
    DownloadWithCurl(Download With Curl)
    fileGetfilenameFromFile{Get id3 tag<br>with ffprobe}
    setFile2(rename tempfile<br>to title+artist+year)
    EnterFilename
    setFile3(rename tempfile<br>to given file)
    NoFilename(Exit: no filename was given)
  end

  %% ------------------------------------------------------------
  %% styles
  %% ------------------------------------------------------------

  style Start              fill:#8dd,stroke:#088,color:#088,stroke-width:4px
  style End                fill:#8dd,stroke:#088,color:#088,stroke-width:4px

  style DownloadWithCurl1  fill:#8f8,stroke:#080,color:#080,stroke-width:4px
  style setFile2           fill:#8f8,stroke:#080,color:#080,stroke-width:4px
  style setFile3           fill:#8f8,stroke:#080,color:#080,stroke-width:4px
  style SRStart            fill:#8f8,stroke:#080,color:#080,stroke-width:4px

  style noResponse         fill:#f88,stroke:#800,color:#800,stroke-width:4px
  style YesErrorResponse   fill:#f88,stroke:#800,color:#800,stroke-width:4px
  style NoFilename         fill:#f88,stroke:#800,color:#800,stroke-width:4px
  style SRrecordTestFailed fill:#f88,stroke:#800,color:#800,stroke-width:4px

  %% ------------------------------------------------------------
  %% graphs
  %% ------------------------------------------------------------

  Start==>LoadCfg==>UrlOrFile
  UrlOrFile-->|File|ParamIsAFile --> HandleAsStream
  UrlOrFile==>|Url|ParamIsAUrl

  ParamIsAUrl ==> FetchHttpHeader ==> GotResponse

  GotResponse --> |No|noResponse--> End
  GotResponse ==> |Yes|yesResponse --> ShowHttpHeader --> ErrorResponse
  ErrorResponse --> |Yes|YesErrorResponse --> End
  ErrorResponse ==> |No|DetectedStream
  DetectedStream ==> |Yes| HandleAsStream
  DetectedStream --> |No| DetectedDownload

  DetectedDownload --> |Yes| HandleAsDownload
  DetectedDownload --> |no| HandleAsStream


  HandleAsDownload --> fileGetfilenameFromHeader
  fileGetfilenameFromHeader --> |Yes|setFile1 --> DownloadWithCurl1 --> End
  fileGetfilenameFromHeader 
    --> |no|setFileTemp 
    --> DownloadWithCurl 
    --> fileGetfilenameFromFile 
    fileGetfilenameFromFile --> |Yes|setFile2 --> End
    fileGetfilenameFromFile --> |Yes|EnterFilename

    EnterFilename --> |Yes| setFile3 --> End
    EnterFilename --> |no| NoFilename --> End
  
  HandleAsStream 
    ==> CheckStreamUrl
    ==> SRshowVersion
    ==> SRrecordTest
  SRrecordTest --> |Failed| SRrecordTestFailed --> End
  SRrecordTest ==> |OK| SRStart
```
Damn why did I start it?!