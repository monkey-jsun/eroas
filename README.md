# EROAS

EROAS stands for "Electrum Running On A Stick". 
It runs Electrum wallet, the best open source bitcoin wallet, on cheap USB drives,
with cold-wallet level security and warm-wallet like convenience.
It is meant to operate like a saving account for infrequent transactions (perhaps <1 transaction per day).
Its strong security level makes it suitable to protect assets over millions of dollars.

### Networking modes:

EROAS supports 3 networking modes:

- Use Tor to connect to Electrum open netowrk (default; easy)
- Connect to a designated Electrum server directly
- Connect to a designated Electrum server via SSH tunnel (advaned)

Strict firewall rules are imposed. 
- No incoming connections
- Outgoing connection is allowed for port 53 (DNS). 
- Additionally,
    - For Tor mode, port 9001 and optional 80/443 (HTTP/HTTPS) are allowed
    - For single server mode, connection to the server is allowed at Electrum port (50002) or ssh port (22)

### Security features

- The system image is an unmutable ISO image, resistent to all persistent attacks. 
    - No root user or sudoer in the whole system!
    - Persistent partition is mounted for /home (user data) only
- Data partition is password-protected crypto file system 
- Support fingerprint-protected secure drive for additional security
- Strict firewall enforcement
- Use Tor for additional privacy and security
- Support designated electrum server mode
- Leverage usual security measures in Electrum wallet (e.g, wallet password)
- Every piece of code is open source and everyone can build from scratch
- Use general purposed and open architecture hardware (PC/Mac/USB disks).  No proprietary code or hardware.
- support both Mac and PC

### Flash USB drive

- Get a spare USB drive with 2GB or bigger.
    - Backup exiting data as the whole drive will be wiped away.
    - USB 3.0 or above drive is strongly recommended for fast run-time speed.  
    - You can also look into fingerprint-protected or keypad protected USB drives for addtional security. 
- Download [the latest EROAS ISO image](http://junsun.net/misc/latest-eroas.html)
    - Optionally you can build EROAS ISO image yourself relatively easily. See Instructions below.
- Download/install [Etcher](https://www.balena.io/etcher/) and use it to flush the ISO image to USB drive.
    - Etcher runs on Mac, Windows and Linux.
    - Windows users can also use [rufus](https://rufus.ie/).  Use all default options and choose "dd" method to do the final flashing.
    - Linux users can simply use dd command (e.g., "sudo dd if=eroas-v0.8.0-20201018-152032.iso of=/dev/sdb bs=4M")
- To flush into fingerprint-protected or keypad-protected secure drive, unlock secure dirve first.  Select the secure drive as the flushing target.
    - Please do not install EROAS into both public and secure drive.  The persistent data partition will get mixed up.  

### Use EROAS

- Insert EROAS USB drive into PC/MacBook and boot from USB drive.
    - Different machines have different methods for this step.   
    - Refer to [a quick guide](https://www.acronis.com/en-us/articles/usb-boot/) and [a more comprehensive guide](https://neosmart.net/wiki/boot-usb-drive/)
- First time booting up, you may need to set up wifi connection.  On the top right corner, click an icon with 2 arrows.
    - You only need to do this once for each new wifi network.
- Click on the Electrum launcher icon on Desktop to run Electrum. 
    - Firt time running, you will go through a setup process.
- Follow Electrum GUI to set up your wallets and perform transactions accordingly
- Afterwards shut down the machine and unplug the USB drive.

Note - because we are using Tor networking with a very strict firewall, it might take up to 1 or 2 minutes for Electrum to make an initial connection to Electrum network.

### Build ISO image

- Have a ubuntu 20.04 host
    - other debian-based distro could work, but not tested and may need minor changes
    - no GUI necessary (e.g, AWS ubuntu 20.04 server suffices)
- git clone https://github.com/monkey-jsun/eroas.git
- cd eroas
- ./build_eroas.sh -
- During the build you will be presented a few screens of choices.  Always choose the default, except for the followings
    - "Configuring locales" screen #1 : select "end_US ISO-8859-1" and "en_US.UTF-8 UTF-8"
    - "Configuring locales" screen #2 : select "C.UTF-8"

