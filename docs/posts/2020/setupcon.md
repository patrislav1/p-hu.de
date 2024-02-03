---
date: 2020-07-29
categories:
  - linux
---

# Powerline font in framebuffer console

When using a "Powerline"-based prompt such as [ZSH agnoster](https://github.com/agnoster/agnoster-zsh-theme),
the prompt looks good in a graphical terminal emulator, but will probably look garbage in the framebuffer or VGA console, due to the missing font glyphs.

There is a special [bitmap-based powerline font](https://github.com/powerline/fonts/tree/master/Terminus/PSF) suitable for the framebuffer console. On some systems the console setup tool `setupcon` is buggy and has to be patched in order to enable loading a custom font.

* Download bitmap font from [powerline repository](https://github.com/powerline/fonts/tree/master/Terminus/PSF)

* Copy the `ter-powerline-*.psf.gz` files to `/usr/share/consolefonts`

* Add `FONT=...` to `/etc/default/console-setup`. It may be worth to experiment with different font sizes depending on screen resolution.
  ```
  FONT="ter-powerline-v32n.psf.gz"
  ```

* `/bin/setupcon` has a bug preventing it from finding and activating the font.
  Fix with following patch:

    ```diff
    --- /bin/setupcon.orig 2020-07-29 08:57:20.792643590 +0200
    +++ /bin/setupcon 2020-07-29 09:11:24.295472896 +0200
    @@ -684,10 +684,11 @@
                 fdec="${f%.gz}"
                 RES=`findfile $fontdir $fdec`
             fi
    -        FONTFILES="$FONTFILES $RES"
    +        FONTFILES="$RES"
         done
     fi
     FONTFILES=`echo $FONTFILES` # remove extra spaces
    +
     if [ -n "$FONTFACE" -a -z "$FONTFILES" ]; then
         case "$kernel" in
             linux)
    ```

* Run `setupcon`

Now the Terminus powerline font should be active in the framebuffer console.

