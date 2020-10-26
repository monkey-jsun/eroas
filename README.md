# EROAS

EROAS stands for "Electrum Running On A Stick". 
It runs Electrum wallet, the best open source bitcoin wallet, on cheap USB drives,
with cold-wallet level security and warm-wallet like convenience.
It is meant to operate like a saving account for infrequent transactions (<1 transaction per day).
Its strong security level makes it suitable to protect assets over millions of dollars.

### Networking modes:

Curently we only support using Tor to connect to open Electrum netowrk.
In the future we will support connecting to designated Electrum server, either directly or via SSH tunneling.

Strict firewall is implemented:
- no incoming connections
- outgoing connections are allowed for port 53 (DNS), 9001 (Tor), 443 (HTTPS) only

### Security features

- The system image is an unmutable ISO image, resistent to all persistent attacks. 
  - No root user or sudoer in the whole system!
  - Persistent partition is mounted for /home (user data) only
- Data partition is password-protected crypto file system (TODO)
- Support fingerprint-protected secure drive for additional security
- Strict firewall enforcement
- Use Tor for additional privacy and security
- Support designated electrum server mode (TODO)
- Leverage usual security measures in Electrum (e.g, wallet password)
- Every byte of code is generated from open source software and everyone can build from scratch
- Use general purposed and open architecture hardware (PC/Mac/USB disks).  No proprietary code or hardware.
- support both Mac and PC

### Flash USB drive

- Get a spare USB drive with 2GB or bigger.
    - Backup exiting data as they will be wiped away.
    - USB 3.0 or above drive is strongly recommended for fast run-time speed.  
    - You can also look into fingerprint-protected or keypad protected USB drives for addtional security. 
- Download [the latest EROAS ISO image](http://junsun.net/misc/latest-eroas.html)
    - Optionally you can build EROAS ISO image yourself relatively easily. See Instructions below.
- Download/install [Etcher](https://www.balena.io/etcher/) and use it to flush the ISO image to USB drive.
    - Etcher runs on Mac, Windows and Linux.
    - Windows users can also use rufus.  Please use all default options and "dd" method to do the flashing.
    - Linux users can simply use dd command (e.g., "sudo dd if=eroas-v0.8.0-20201018-152032.iso of=/dev/sdb bs=4M")
- To flush into fingerprint-protected secure drive, use your finger to unlock secure dirve first.  Select the secure drive as the flushing target.
    - Please do not install EROAS into both public and secure drive.  The persistent data partition will get mixed up.  

### Use EROAS

- Insert EROAS USB drive into PC/MacBook and boot from USB drive.
  Different machines have different methods for this step.  See wiki page. (TODO)
- First time booting up, you may need to set up wifi connection.  On the top right corner, click an icon with 2 arrows.  You only need to do this once for each new wifi network.
- Click on the Electrum launcher icon on Desktop to run Electrum. 
    Select "Auto connect" option when prompted for the first time running.
- Follow Electrum GUI to set up your wallets and perform transactions accordingly
- Afterwards shut down the machine and unplug the USB drive.

Note - because we are using Tor networking with a very strict firewall, it might take up to 1 minute for Electrum to make an initial connection to Electrum network.

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

