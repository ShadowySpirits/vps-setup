#!/usr/bin/env bash
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install deluge"
    exit 1
fi

set -euo pipefail
apt install -y software-properties-common
add-apt-repository -y ppa:deluge-team/stable
apt update
apt install -y deluge
apt install -y deluged deluge-webui

adduser --system  --gecos "Deluge Service" --disabled-password --group --home /var/lib/deluge deluge
mkdir -p /var/log/deluge
chown -R deluge:deluge /var/log/deluge
chmod -R 750 /var/log/deluge

tee /etc/systemd/system/deluged.service << EOF
[Unit]
Description=Deluge Bittorrent Client Daemon
Documentation=man:deluged
After=network-online.target

[Service]
Type=simple
User=deluge
Group=deluge
UMask=007
ExecStart=/usr/bin/deluged -d -l /var/log/deluge/daemon.log -L warning
Restart=on-failure
# Time to wait before forcefully stopped.
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
EOF

tee /etc/systemd/system/deluge-web.service << EOF
[Unit]
Description=Deluge Bittorrent Client Web Interface
Documentation=man:deluge-web
After=network-online.target deluged.service
Wants=deluged.service

[Service]
Type=simple
User=deluge
Group=deluge
UMask=027
ExecStart=/usr/bin/deluge-web -d -l /var/log/deluge/web.log -L warning
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl enable /etc/systemd/system/deluged.service
systemctl start deluged


systemctl enable /etc/systemd/system/deluge-web.service
systemctl start deluge-web

systemctl status deluged
systemctl status deluge-web