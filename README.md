# conky-themes
conky monitor configurations and themes


## install & usage
In order to use a conky theme have the directory containing the files downloaded and copied on your system:
`~/.config/conky/themes/<theme>/conky.conf` and optionally `~/.config/conky/themes/<theme>/lua_widgets.lua` for instance.

Then launch conky as follows:
```bash
$ cd ~/.config/conky/themes/<theme>
...
$ conky -c conky.conf &
```

The ampersand is so you can leave that terminal session with conky left to run in the background.
To automate the process just use the same code in a startup script.


## Polar_desk_clock
It was heavily inspired from the infamous "polar clock screensaver" from **pixelbreaker** and a later derivation the polar clock III.

The code was based on [expander's Calendar Extra](https://github.com/alexsson-xexpanderx/Conky-themes/tree/master/Conky-Calendar-Extra/conky) and it was heavy refactored since.
<img width="2560" height="1440" alt="Screenshot_2026-09-22_20-59-22" src="https://github.com/user-attachments/assets/94a63e00-5839-4979-b88a-f52bbcec88ac" />

I've changed the clock behavior: now here are "feed" and "eat" passes on odd and even cycles...

Lacking a license on the source I've picked the permissive MIT licence, in hope anyone objecting would contact me...


Enjoy!
