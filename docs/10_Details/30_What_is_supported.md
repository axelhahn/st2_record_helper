
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

## Tested ST2 channel plugins

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
