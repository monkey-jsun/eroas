# EROAS

EROAS stands for "Electrum Running On A Stick". 
It runs Electrum wallet on USB disk to achieve cold-wallet level security while keeping warm-wallet-like convenience at a budget price.  
It is meant to operate like a safe or saving account for infrequent transactions (perhaps <1 transaction per day),
and is suitable to protect assets from anywhere from $1K to $10M USD.

To use EROAS, simply insert EROAS USB drive into PC/MacBook and boot
from it. You can use fingerprint-protected secure drive to achieve higher security.
After system boots up, Electrum will start and guide you through the transactions.
Afterwards you shut down the machine, unplug the drive and store it securely.


### Operating modes:

Two networking modes
- Use EROAS with Tor to connect to open Electrum netowrk
- Use EROAS with a single designated Electrum server for better security and privacy 

### Security features

- The system image is an unmutable ISO image, resistent to all persistent attacks. (TODO)
- Data partition is password-protected crypto file system (TODO)
- Support fingerprint-protected secure drive for additional security
- Default firewall that denies all incoming traffic and restrict outgoing traffic a few ports.
- Use Tor for additional privacy and security
- Support dedicated electrum server mode (TODO)
- Usual security measures in Electrum (e.g, wallet password)
- Every byte of code is generated from open source software and you can build from scratch
- Use general purposed and open architecture hardware (PC/Mac/USB disks).  No proprietary code or hardware.
- support both mac and PC


### User experience

One-time preparation
- (optional) Build EROAS ISO image from source. (See below).
    - Or download [the prebuilt v0.8.0 iso image](https://drive.google.com/file/d/16MnN00eq4RcCpbZa7cydGBBcpTLNSE8z/view?usp=sharing)
- Flash ISO image to the USB public drive (see below)

Running
- Boot up PC/Mac from USB drive
    - Insert USB into any PC or Mac
    - Power up 
    - Quickly interrupt boot up sequency and drop into bootup manager
        - Google around for your machine for detailed instructions
    - Optionally press finger to unlock secure drive
    - Select the proper USB drive to boot up
- Once desktop starts, start a terminal and type "electrum".
    - Follow its UI to create wallet and start transactions.
    - Go to "Tools"/"Network"/"Proxy" and select "Use Tor proxy at port 9050"
- Power down machine after every use.
- Reboot machine to check all data are persistent.

### Flash usb disk

- We recommend using USB 3.0 or above drive for fast speed.
- We recomment Etcher (https://www.balena.io/etcher/), which runs on Mac, Windows and Linux
    - For windows, one can also use rufus.  Please use all default options and "dd" method to do the flahsing.
    - For Linux, one can simply use dd command (e.g., "dd if=eroas-v0.8.0-20201018-152032.iso of=/dev/sdb bs=4M")
- To flush into fingerprint-protected secure drive, please press your finger and unlock secure dirve first.
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

### TODO

- add crypto FS to the persistent data partition 
- limit the ability to override system files and become truely immutable
- add script to set up network mode
    - start electrum differently accordingly to the mode
    - add additional firewall rules for designated server mode
