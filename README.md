# EROAS

EROAS stands for "Electrum Running On A Stick". 
It runs Electrum wallet, the best open source bitcoin wallet, on cheap USB drives,
with cold-wallet level security and warm-wallet like convenience.
It is meant to operate like a saving account for infrequent transactions (<1 transaction per day).
Its strong security level makes it suitable to protect assets over millions of dollars.

### Use EROAS

- Insert EROAS USB drive into PC/MacBook and boot from USB drive.
  Different machines have different methods for this step.  See wiki page. (TODO)
- First time booting up, you may need to set up wifi connection.  On the top right corner, click an icon with 2 arrows.  You only need to do this once for each new wifi network.
- Click on the Electrum launcher icon on Desktop to run Electrum. 
    Select "Auto connect" option when prompted for the first time running.
- Follow Electrum GUI to set up your wallets and perform transactions accordingly
- Afterwards shut down the machine and unplug the USB drive.

Note, since we are using Tor networking, it might take up to 1 minute for Electrum to make a connection to Electrum open network.

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

We recommend using USB 3.0 or above drive for fast speed.  
You can also use fingerprint-protected or keypad protected USB drives for addtional security. 

- (optional) Build EROAS ISO image from scratch. (See below).
- Or download [the latest EROAS ISO image](http://junsun.net/misc/latest-eroas.html)
- We recomment using [Etcher](https://www.balena.io/etcher/) for flushing.  It runs on Mac, Windows and Linux.
    - For windows, one can also use rufus.  Please use all default options and "dd" method to do the flashing.
    - For Linux, one can simply use dd command (e.g., "dd if=eroas-v0.8.0-20201018-152032.iso of=/dev/sdb bs=4M")
- To flush into fingerprint-protected secure drive, please use your finger to unlock secure dirve first.
    - Please do not install EROAS into both public and secure drive.  The persistent data partition will get mixed up.  

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

