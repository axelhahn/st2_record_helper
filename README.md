# Record helper script for streamtuner

This script contains some logic to download different streaming types
in Streamtuner 2.

## Why

I was a bit frustrated: why does nothing happen if I press [Record] in Streamripper 2?!
So it was my challenge: show something what happens or show an error that I am able to read and to analyze.

If this was done I saw why a few streams do not start to donload.
Do I need to fetch a real stream first by following "location:" or grep the 1st line of a m3u playlist.

With the different station plugins exist several constellations. This script is an anitial point and not feature complete yet.

## Installation

Extract archive or git clone the repository somewhere. 
I used `/home/axel/scripts/streamtuner/`.

In Streamtuner2 press F12 for settings. In the record section for `audio/*` set

`konsole -e /home/axel/scripts/streamtuner/record_helper.sh`
or
`gnome-terminal -- /home/axel/scripts/streamtuner/record_helper.sh`

## Requirements

* Bash
* curl
* ffmpeg
* streamripper

## Supported downloads

### Stream file donwloads

* **shoutcast + icecast streams**<br>Streamripper will be used to download each single file
* **m3u** will be fetched to grep the first stream in it. That one will be put to streamripper.

### Single file donwloads

Single file downloads will be handled by `curl`.

* **Jamendo**: mp3<br>downloaded files will be renamed to "TITLE - ARTIST (YEAR).mp3" by using `ffprobe` (which is part of ffmpeg package)
* **MODArchiv**: mod, it, s3m, xm<br>names downloaded file are taken from http reponse header - valuie filename in field `Content-Disposition:`

## known errors

### error -28 [SR_ERROR_INVALID_METADATA]

This is a bug in streamripper: t tries to request metadata in http/1.1 but can understand http 1.0 only.
