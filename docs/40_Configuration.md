## Config file

In the ./config/default you can set a few variables:

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

In the table below you find a Description of the variables.

Variable | Type | Description
---|---|---
_dirstreamripper | string | Directory for streamripper; below it creates a subdir per station
_dirfiles        | string | Directory to download single files
_userAgent       | string | override user agent
_iTimeout        | int    | curl connect timeout in sec; default: 3
_iWait           | int    | waiting time in sec before exit; default: 60
_col...          | string | override colors<br>Hint: you can try to set the console profile instead of fiddling around with color values.
