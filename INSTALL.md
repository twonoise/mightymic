Checks:
------
I've tested with Archlinux. Sorry, don't know how it will work for others.

Install:
-------
1. Select mains frequency @ `mightymic.dsp`, Line ~54.
2. 

    pacman -S lv2 boost faust
    mkdir /usr/local/lib/lv2

3. Then, please see at top of `.dsp` files.

Uninstall:
---------
    rm -rvf /usr/local/lib/lv2/mightymic.lv2/ 
    rm -rvf /usr/local/lib/lv2/mightymictestsource.lv2/ 


