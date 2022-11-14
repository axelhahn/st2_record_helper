## Get the files

### Use git

Extract archive or better: git clone the repository somewhere. If you use git clone it is easier to update all files.

I used `/home/axel/scripts/st2_record_helper/`.

```txt
cd ~/scripts
git clone https://github.com/axelhahn/st2_record_helper.git
```

## Create config

In the subdir `./config/` is a file "default.dist". Copy it to "default" (without .dist).

**Remark**:
If your user has write permissions in the config directory it will be done automatically on the first run of a record call.

## Configure Streamtuner 2

In Streamtuner2 press F12 for settings. In the record section for `audio/*` set

`konsole -e /home/axel/scripts/st2_record_helper/record_helper.sh`
or
`gnome-terminal -- /home/axel/scripts/st2_record_helper/record_helper.sh`
