
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
