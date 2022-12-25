## Features

* You get output! Which stream was requested, http headers for details. 
* on error: a window does not just close - you have 60 sec to read it
* automatic fetching for a real streaming url in some playlist types
* support for the download of files (Jamendo, MODarchive) with automatic renaming
* remove unused streamripper output directories and cleanup of 'incomlete' dirs
* command line parameter support

## Screenshots

### Stop on error

If any error occours before the download starts you get a few debug infos about the http header.
On exist the script waits that you are able to read the output.

![screenshot](images/st2_record_helper_stop_on_error.png)

### Donwload files

Next to streamripper I detect single foles for mp3 or tracker files (.mod, .it, .st3).
If a file was found it will be downloaded.

![screenshot](images/st2_record_helper_jamendo_download.png)
