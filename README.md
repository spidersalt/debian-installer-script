# debian-installer-script
System Setup and Configuration Script for Debian 13 GNOME
Overview
This Bash script automates the setup and configuration of a Debian 13 GNOME system. It handles system updates, installs essential packages, configures applications, sets up a firewall, and organizes directories for a secure and efficient environment. The script is designed to streamline the process of setting up a new Debian 13 GNOME installation with privacy and productivity tools.
Features

Directory Creation: Creates organized directories in the user's home folder, including Desktop/start-here, Applications, Scripts, Filen, and Syncthing subdirectories.
System Updates: Performs apt update and full-upgrade to ensure the system is up-to-date.
Package Installation: Installs a curated set of tools and applications, including:
Base tools: curl, neovim, wget, rsync, zip, git, zsh, terminator, ffmpeg, ufw, vlc, gimp, keepassxc, and more.
Flatpak apps: Obsidian, FreeTube, LocalSend, Cryptomator, Discord, VS Codium, and others from Flathub.
Specialized apps: Mullvad Browser, Mullvad VPN, Brave Browser, VeraCrypt, FreeFileSync, Filen, Syncthing, Proton apps, Standard Notes, Signal, Lynis, and Railway Wallet.


Firewall Configuration: Enables ufw and configures rules for LocalSend and Syncthing.
Autostart Setup: Configures autostart for applications like Filen, Syncthing, Cryptomator, KeePassXC, and Mullvad VPN.
Security Enhancements: Removes Firefox, installs privacy-focused browsers, and verifies VeraCrypt installation with PGP signatures.
Cleanup: Removes unnecessary files and optimizes the package cache.

Prerequisites

Operating System: Debian 13 with GNOME desktop environment.
Permissions: Must be run with sudo privileges.
Internet Connection: Required for downloading packages and repositories.

Usage

Clone or download the script from this repository.
Make the script executable:sudo chmod u+x installer.sh


Run the script with superuser privileges:sudo ./installer.sh



Post-Setup Instructions
After running the script, a readme.txt file will be created in ~/Desktop/start-here with the following recommended steps to complete your setup:

Run the FreeFileSync installer.
Harden browsers (Mullvad and Brave).
Download Whonix for VirtualBox.
Configure Syncthing (autostart enabled).
Set up Timeshift for backups.
Configure Cryptomator (autostart enabled).
Set up Tuta in ~/Applications.
Customize GNOME extensions, desklets, and applets.
Apply themes as needed.

Notes

Error Handling: The script includes error tracking. If any step fails, it logs the issue and reports failed steps at the end.
Reboot: A system reboot is recommended after successful completion to ensure all changes take effect.
Customizations: The script is tailored for Debian 13 GNOME. Modifications may be needed for other distributions or desktop environments.
Security: The script verifies the VeraCrypt package with PGP signatures and uses trusted repositories for other installations.

Troubleshooting

If the script fails, check the output for the specific step(s) that caused the issue (listed in the FAILED_STEPS array).
Ensure you have an active internet connection and sufficient disk space.
Run sudo apt update and sudo apt --fix-broken install manually if package installation issues persist.

Author

Author: Unknown
Version: 3.0
Date: 03 October 2025

License
This script is provided as-is without any warranty. Use at your own risk.
