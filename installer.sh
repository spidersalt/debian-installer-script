#!/bin/bash
#
# System Setup and Configuration Script
# Description: Automates system updates, package installation, and application setup
# This script is specifically tweaked for Debian 13 GNOME
# Author: Unknown
# Version: 3.0
# Date: 03 October 2025
# Usage: ./installer.sh
# Run: sudo chmod u+x installer.sh && sudo ./installer.sh;

# Define colors and formatting
print_message() {
    local color_code="\e[3${1}m"
    local message_type=$2
    local message=$3
    local reset="\e[0m"
    echo -e "\n${color_code}╔════════════════════════════════════╗"
    echo -e "║ ${message_type}${reset}"
    echo -e "${color_code}╚════════════════════════════════════╝${reset}"
    echo -e "${message}\n"
}

# Initialize status tracking
SUCCESS=true
FAILED_STEPS=()

throw_error() {
    SUCCESS=false
    FAILED_STEPS+=("$1")
    return 1
}

# Execute updates with error handling
{
    # 1. Create directories in user's home directory
    print_message 1 "CREATE DIRECTORIES" "Creating directories in user's home directory"
    echo "Home directory: $HOME"
    cd "$HOME" || throw_error "Cannot change to home directory"
    mkdir -pv /home/user/Desktop/start-here /home/user/Applications /home/user/Scripts /home/user/Filen || throw_error "CREATE DIRECTORIES"
    mkdir -pv /home/user/Syncthing/{00-Secure,01-Projects,02-References,03-Archive,04-Photos,05-Personal,06-Backups,07-Misc} || throw_error "CREATE SYNCTHING DIRECTORIES"
    mkdir -pv /home/user/.config/autostart
    chown -R user:user /home/user/.config/autostart /home/user/Desktop/start-here /home/user/Applications /home/user/Scripts /home/user/Filen /home/user/Syncthing
    echo "done."

    # 2. Update package lists & full upgrade
    print_message 2 "SYSTEM UPDATE" "Performing apt update & full-upgrade..."
    sudo apt update && \
    sudo apt full-upgrade -y && \
    sudo apt install --fix-broken -y || throw_error "SYSTEM UPDATE"
    echo "done."

    # 3. Install base tools
    print_message 5 "INSTALLATION" "Installing base tools..."
    sudo apt install -y curl neovim wget rsync zip \
    fastfetch git zsh terminator ffmpeg \
    ufw mat2 vlc bleachbit tar ssss tcpdump \
    gzip systemd-resolved build-essential flatpak \
    htop timeshift nwipe xfburn python3-pip \
    unzip gnome-shell-extension-manager p7zip-full \
    smartmontools kdenlive gimp keepassxc gparted \
    gnupg || throw_error "INSTALLATION"
    sudo apt install --fix-broken -y || throw_error "APT INSTALL"
    systemctl enable systemd-resolved
    systemctl start systemd-resolved
    echo "done."

    # 5. Enable firewall
    print_message 4 "FIREWALL" "Enabling firewall..."
    sudo ufw enable || throw_error "FIREWALL ENABLE"
    sudo ufw logging off
    sudo ufw allow 53317 || throw_error "UFW ALLOW 53317" #LocalSend
    sudo ufw status verbose
    echo "done."

    # 6. Enable the flathub repo and allow offline installs
    print_message 6 "FLATPAK SETUP" "Adding and modifying Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || throw_error "FLATPAK SETUP"
    flatpak remote-modify --collection-id=org.flathub.Stable flathub || throw_error "FLATPAK SETUP"

    # 6-1. Flatpak installs
    print_message 6 "FLATPAK APPS" "Installing flatpak apps..."
    flatpak install flathub -y md.obsidian.Obsidian \
        io.freetubeapp.FreeTube \
        org.localsend.localsend_app \
        org.cryptomator.Cryptomator \
        com.discordapp.Discord \
        org.onlyoffice.desktopeditors \
        com.vscodium.codium \
        org.onionshare.OnionShare \
        io.gitlab.news_flash.NewsFlash \
        org.kiwix.desktop \
        org.telegram.desktop \
        org.qbittorrent.qBittorrent \
        org.freecad.FreeCAD \
        io.github.aandrew_me.ytdn \
        com.bambulab.BambuStudio \
        com.prusa3d.PrusaSlicer \
        com.tutanota.Tutanota
        # flatpak install flathub com.github.unrud.VideoDownloader \
        # flatpak install flathub org.getmonero.Monero \
        # org.kde.okular || throw_error "FLATPAK INSTALLS"
    echo "done."

    # 7. Mullvad Browser
    print_message 7 "MULLVAD" "Installing Mullvad apps..."

    echo "Downloading Mullvad Browser signing key..."
    sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc || throw_error "MULLVAD KEY DOWNLOAD"

    echo "Adding Mullvad repo server to apt..."
    echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$(dpkg --print-architecture)] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list

    echo "Installing Mullvad apps..."
    sudo apt update
    sudo apt install -y mullvad-browser mullvad-vpn || throw_error "MULLVAD INSTALL"
    echo "done."

    # 8. Remove Firefox
    print_message 8 "REMOVE FIREFOX" "Removing Firefox..."
    sudo apt remove --purge -y firefox-esr firefox || throw_error "REMOVE FIREFOX"
    rm -rf ~/.mozilla/
    echo "done."

    # 9. Install Brave
    print_message 9 "BRAVE" "Installing Brave Browser..."
    curl -fsS https://dl.brave.com/install.sh | sudo sh || throw_error "BRAVE INSTALL"
    echo "done."

    # 10. Install Veracrypt with PGP verification
    print_message 10 "VERACRYPT" "Installing Veracrypt..."
    wget https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Debian-12-amd64.deb -O /tmp/veracrypt.deb || throw_error "VERACRYPT DOWNLOAD"
    wget https://amcrypto.jp/VeraCrypt/VeraCrypt_PGP_public_key.asc -O /tmp/VeraCrypt_PGP_public_key.asc || throw_error "VERACRYPT PUBLIC KEY DOWNLOAD"
    wget https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Debian-12-amd64.deb.sig -O /tmp/veracrypt-1.26.24-Debian-12-amd64.deb.sig || throw_error "VERACRYPT SIG DOWNLOAD"
    
    cd /tmp
    gpg --import VeraCrypt_PGP_public_key.asc

    # Verify the signature
    if gpg --verify veracrypt-1.26.24-Debian-12-amd64.deb.sig veracrypt.deb; then
    echo "PGP signature verified successfully. Proceeding with installation."
    apt install -y /tmp/veracrypt.deb || throw_error "VERACRYPT INSTALL"
    else
    throw_error "PGP signature verification failed. Installation aborted."
    fi
    # Show fingerprint for manual check if desired
    echo "Manual check if fingerprint matches."
    gpg --fingerprint 0x680D16DE

    cd ~
    rm -f /tmp/veracrypt-1.26.24-Debian-12-amd64.deb.sig /tmp/VeraCrypt_PGP_public_key.asc /tmp/veracrypt.deb

    # 11. Install FreeFileSync (without checksum verification)
    print_message 11 "FFS" "Installing FreeFileSync..."
    wget https://freefilesync.org/download/FreeFileSync_14.4_Linux.tar.gz -O /home/user/Desktop/start-here/FreeFileSync_14.4_Linux.tar.gz || throw_error "FFS DOWNLOAD"
    cd /home/user/Desktop/start-here || throw_error "Unable to access ~/Desktop/start-here"
    tar xf FreeFileSync_14.4_Linux.tar.gz || throw_error "FFS EXTRACT"
    cd ~
    rm -f /home/user/Desktop/start-here/FreeFileSync_14.4_Linux.tar.gz || throw_error "FFS REMOVE TAR"

    # 12. Install Filen
    print_message 12 "FILEN" "Installing Filen..."
    wget https://cdn.filen.io/@filen/desktop/release/latest/Filen_linux_amd64.deb -O /tmp/filen.deb || throw_error "FILEN DOWNLOAD"
    sudo apt install -y /tmp/filen.deb || throw_error "FILEN INSTALL"
    sudo apt --fix-broken install -y || throw_error "FILEN FIX BROKEN"
    # Clean up downloaded files
    rm -f /tmp/filen.deb
    echo "done."
    # Autostart on login
    cat <<-EOF > /home/user/.config/autostart/@filendesktop.desktop
	[Desktop Entry]
    Name=Filen
    Exec="/opt/Filen/@filendesktop" %U
    Terminal=false
    Type=Application
    Icon=@filendesktop
    StartupWMClass=Filen
    Comment=Filen Desktop Client
    Categories=Utility;
    X-GNOME-Autostart-enabled=true
    NoDisplay=false
    Hidden=false
    Name[en_SG]=Filen
    Comment[en_SG]=Filen Desktop Client
    X-GNOME-Autostart-Delay=0
	EOF
    sudo chmod +x /home/user/.config/autostart/@filendesktop.desktop || throw_error "FILEN AUTOSTART CHMOD"

    # 13. Install Syncthing
    print_message 13 "SYNCTHING" "Installing syncthing..."
    # Add the release PGP keys:
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
    echo "done."
    # Add the "stable-v2" channel to your APT sources:
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee /etc/apt/sources.list.d/syncthing.list
    echo "done."
    # Add the "candidate" channel to your APT sources:
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing candidate" | sudo tee /etc/apt/sources.list.d/syncthing.list
    # Update and install syncthing:
    sudo apt-get update
    sudo apt-get install syncthing
    echo "done."
    # Enable firewall
    echo "Enabling ufw syncthing"
    sudo ufw allow syncthing || throw_error "SYNCTHING FIREWALL"
    sudo ufw status verbose
    echo "done."
    # Autostart on login
    cat <<-EOF > /home/user/.config/autostart/syncthing-start.desktop
	[Desktop Entry]
    Name=Start Syncthing
    GenericName=File synchronization
    Comment=Starts the main syncthing process in the background.
    Exec=/usr/bin/syncthing serve --no-browser --logfile=default
    Icon=syncthing
    Terminal=false
    Type=Application
    Keywords=synchronization;daemon;
    Categories=Network;FileTransfer;P2P
    X-GNOME-Autostart-enabled=true
    NoDisplay=false
    Hidden=false
    Name[en_SG]=Start Syncthing
    Comment[en_SG]=Starts the main syncthing process in the background.
    X-GNOME-Autostart-Delay=0
	EOF
    sudo chmod +x /home/user/.config/autostart/syncthing-start.desktop || throw_error "CHMOD SYNCTHING AUTOSTART"
    
    # 14. Install Proton Apps
    print_message 14 "PROTON" "Installing Proton apps..."
    wget https://proton.me/download/pass/linux/proton-pass_1.32.7_amd64.deb -O /tmp/proton-pass.deb || throw_error "PROTON PASS DOWNLOAD"
    wget https://proton.me/download/mail/linux/1.9.1/ProtonMail-desktop-beta.deb -O /tmp/proton-mail.deb || throw_error "PROTON MAIL DOWNLOAD"
    # Install the downloaded packages
    sudo apt install -y /tmp/proton-pass.deb /tmp/proton-mail.deb || throw_error "PROTON INSTALL"
    sudo apt --fix-broken install -y || throw_error "PROTON-FIX-BROKEN"
    # Clean up downloaded files
    rm -f /tmp/proton-pass.deb /tmp/proton-mail.deb
    echo "done."

    # 15. Install Standard Notes
    print_message 15 "STANDARD NOTES" "Installing Standard Notes..."
    wget https://github.com/standardnotes/app/releases/download/%40standardnotes%2Fdesktop%403.198.5/standard-notes-3.198.5-linux-amd64.deb -O /tmp/standardnotes.deb || throw_error "STANDARDNOTES-DOWNLOAD"
    # Install the downloaded packages
    sudo apt install -y /tmp/standardnotes.deb || throw_error "STANDARD NOTES INSTALL"
    sudo apt --fix-broken install -y || throw_error "STANDARDNOTES-FIX-BROKEN"
    # Clean up downloaded files
    rm -f /tmp/standardnotes.deb
    echo "done."

    # 16. Install Signal
    print_message 18 "SIGNAL" "Installing Signal..."
    # Install our official public software signing key:
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg;
    cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null || throw_error "SIGNAL SIGN"
    # Add our repository to your list of repositories:
    wget -O signal-desktop.sources https://updates.signal.org/static/desktop/apt/signal-desktop.sources;
    cat signal-desktop.sources | sudo tee /etc/apt/sources.list.d/signal-desktop.sources > /dev/null || throw_error "SIGNAL ADD REPO"
    # Update your package database and install Signal:
    sudo apt update && sudo apt install signal-desktop || throw_error "SIGNAL INSTALL"
    echo "done."

    # 17. Install Lynis
    print_message 20 "LYNIS" "Installing Lynis..."
    # Import key
    curl -fsSL https://packages.cisofy.com/keys/cisofy-software-public.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cisofy-software-public.gpg
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/trusted.gpg.d/cisofy-software-public.gpg] https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list || throw_error "LYNIS KEY DOWNLOAD"
    sudo apt install apt-transport-https
    # Skip downloading translations
    echo 'Acquire::Languages "none";' | sudo tee /etc/apt/apt.conf.d/99disable-translations
    # Add repo
    echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list
    apt update
    apt install lynis || throw_error "LYNIS INSTALL"
    # Confirm Lynis version
    lynis show version
    echo "done."

    # 18. Get BIP39
    print_message 21 "BIP39" "Downloading BIP39 standalone html..."
    wget https://github.com/iancoleman/bip39/releases/download/0.5.6/bip39-standalone.html -O /tmp/bip39-standalone.html || throw_error "BIP39 DOWNLOAD"
    sudo mv /tmp/bip39-standalone.html /home/user/Documents
    echo "done."

    # 19. Install Railway App
    print_message 23 "RAILWAY" "Installing Railway app..."
    wget https://github.com/Railway-Wallet/Railway-Wallet/releases/download/v5.22.4/Railway-v5.22.4-linux-amd64.deb -O /tmp/railway.deb || throw_error "RAILWAY-DOWNLOAD"
    # Install downloaded package
    sudo apt install -y /tmp/railway.deb || throw_error "RAILWAY-INSTALL"
    sudo apt --fix-broken install -y || throw_error "RAILWAY-FIX-BROKEN"
    # Clean up downloaded files
    rm -f /tmp/railway.deb
    echo "done."

    # 24. Setup autostart apps
    print_message 24 "AUTOSTART" "Setting up autostart apps..."
    # Cryptomator
    echo "Cryptomator autostart"
    cat <<-EOF > /home/user/.config/autostart/org.cryptomator.Cryptomator.desktop
	[Desktop Entry]
    Name=Cryptomator
    Comment=Cloud Storage Encryption Utility
    Exec=/usr/bin/flatpak run --branch=stable --arch=x86_64 --command=cryptomator --file-forwarding org.cryptomator.Cryptomator @@ %F @@
    Icon=org.cryptomator.Cryptomator
    Terminal=false
    Type=Application
    Categories=Utility;Security;FileTools;
    StartupNotify=true
    StartupWMClass=org.cryptomator.launcher.Cryptomator$MainApp
    MimeType=application/vnd.cryptomator.encrypted;application/vnd.cryptomator.vault;
    X-Flatpak=org.cryptomator.Cryptomator
    X-GNOME-Autostart-enabled=true
    NoDisplay=false
    Hidden=false
    Name[en_SG]=Cryptomator
    Comment[en_SG]=Cloud Storage Encryption Utility
    X-GNOME-Autostart-Delay=1
	EOF
    sudo chmod +x /home/user/.config/autostart/org.cryptomator.Cryptomator.desktop || throw_error "CHMOD CRYPTOMATOR AUTOSTART"    
    echo "done."
    # Proton Pass
    echo "KeePassXC autostart"
    cat <<-EOF > /home/user/.config/autostart/org.keepassxc.KeePassXC.desktop
    [Desktop Entry]
    Name=KeePassXC
    GenericName=Password Manager
    Exec=keepassxc
    TryExec=keepassxc
    Icon=keepassxc
    StartupWMClass=keepassxc
    StartupNotify=true
    Terminal=false
    Type=Application
    Version=1.0
    Categories=Utility;Security;Qt;
    MimeType=application/x-keepass2;
    X-GNOME-Autostart-enabled=true
    X-GNOME-Autostart-Delay=2
    X-KDE-autostart-after=panel
    X-LXQt-Need-Tray=true
		EOF
    sudo chmod +x /home/user/.config/autostart/org.keepassxc.KeePassXC.desktop || throw_error "CHMOD KEEPASS AUTOSTART"    
    echo "done."    
    # Mullvad VPN
    echo "Mullvad VPN autostart"
    cat <<-EOF > /home/user/.config/autostart/mullvad-vpn.desktop
	[Desktop Entry]
    Name=Mullvad VPN
    Exec="/opt/Mullvad VPN/mullvad-vpn" %U
    Terminal=false
    Type=Application
    Icon=mullvad-vpn
    StartupWMClass=Mullvad VPN
    Comment=Mullvad VPN client
    Categories=Network;
    X-GNOME-Autostart-enabled=true
    NoDisplay=false
    Hidden=false
    Name[en_SG]=Mullvad VPN
    Comment[en_SG]=Mullvad VPN client
    X-GNOME-Autostart-Delay=0
	EOF
    sudo chmod +x /home/user/.config/autostart/mullvad-vpn.desktop || throw_error "CHMOD MULLVADVPN AUTOSTART"    
    echo "done."

    # Final cleanup of package lists - END
    print_message 1 "CLEANUP" "Removing unnecessary files..."
    # Readme file
    cat <<-EOF > ~/Desktop/start-here/readme.txt
	## Welcome to your new environment.
    
    Follow these steps to complete your setup:

    1. Run FFS installer
    2. Harden browsers (Mullvad & Brave)
    3. Download Whonix for Virtualbox
    4. Setup Syncthing (autostart enabled)
    5. Setup Timeshift
    6. Setup Cryptomator (autostart enabled)
    7. Setup Tuta in ~/Applications
    8. Play with extensions, desklets and applets
    9. Apply themes in #24 of the script
	EOF
    # Cleanup
    apt update
    apt install gir1.2-gnomedesktop-3.0
    apt autoremove --purge -y && \
    apt autoclean -y && \
    rm -rf /var/lib/apt/lists/* || throw_error "CLEANUP ERROR"
    echo "done."

} || {
    print_message 1 "ERROR" "Script process failed at step(s): ${FAILED_STEPS[*]}"
}

# Final status report
if $SUCCESS; then
    print_message 2 "COMPLETED" "System setup successful! Please reboot.\n$(date)"
    exit 0
else
    print_message 1 "FAILED" "Updates incomplete. Issues detected at:\n- ${FAILED_STEPS[*]}"
    exit 1
fi
