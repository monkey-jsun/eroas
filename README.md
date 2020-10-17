# EROAS

EROAS stands for "Electrum Running On A Stick". 
EROAS runs Electrum wallet on fingerprint-protected USB disk to achieve
cold-wallet security and warm-wallet convenience at a budget price.  
It is meant to
operate like a safe or saving account for infrequent transactions (perhaps <1 transaction per day),
and is suitable to protect assets from anywhere from $1K to $10M USD.

To use EROAS, simply insert EROAS USB drive into PC/MacBook and boot
from it. Press your fingerprint to unlock the secure drive.  Afterwards,
Electrum will start and guide you through the transactions.
Afterwards you shut down the machine, unplug the drive and store it 
securely.


### Operating modes:

- Use EROAS with Tor to connect to open Electrum netowrk
- Use EROAS with a single designated Electrum server for better security and privacy

### Security features

- The system image is an unmutable ISO image, resistent to all persistent attacks.
- Data partition 
    - is password-protected crypto file system
    - is on a hidden, secondary partiton
    - is on a fingerprint-protect secure drive
- Networking
    - In Tor mode, no incoming traffic is allowed
    - In dedicated electrum server mode, no incoming traffic is allowed, and
      only outgoing traffic allowed is for the dedicated server at dedicated
      port
- Usual security measures in Electrum (e.g, wallet password)
- Every byte of code is generated from open source software and you can build from scratch
- Only use general purposed and open architecture hardware (PC/Mac/USB disks)

### Other features

- supported usb drives include: 
    - Lexar JumpDrive Fingerprint (https://www.lexar.com/portfolio_page/jumpdrive-fingerprint-f35-usb-3-0-flash-drive/)
    - Eaget fingerprint pendrive
- support 2 ways to backup and restore
    backup data partition as a backup file.
    backup Electrum Mnemonic phrases
- support both mac and PC


### User experience

One-time preparation
- (optional) Build EROAS ISO image from source
- Flash ISO image to the USB public drive

Running
- Insert USB into any PC or Mac and boot from the USB drive.
- Press finger to unlock secure drive
- if it is first time running
    - Upon prompt, select and enter password for encrypted filesystem
    - Select Electrum network options: using Tor or using a trusted server.
- Otherwise
    - Upon prompt, enter password for encrypted filesystem
- Electrum wallet will start automatically. Follow its UI to create wallet and start transactions.
- Power down machine after every use.
