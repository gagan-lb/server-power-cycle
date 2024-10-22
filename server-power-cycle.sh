#!/bin/bash
#
# server-power-cycle.sh
# Description: Cycles server through disable/enable states with reboots for 24 hours
# Usage: bash server-power-cycle.sh
# Author: Gagan Gill
# Date: October 22, 2024

# Server name to work with
SERVER_NAME="server00"

# Create directory & server.name file for scripts
mkdir -p /root/server_cycle
echo "${SERVER_NAME}" > /root/server_cycle/server.name

# Create the main cycle script
cat > /root/server_cycle/cycle.sh << 'EOF'
#!/bin/bash

# Check for server.name file which contains server name we are working on
if [ ! -f /root/server_cycle/server.name ]; then
    echo "`date` error: server.name file does not exist" >> /root/server_cycle/error.txt
    exit 1
fi

SERVER_NAME=$(cat /root/server_cycle/server.name)

# If start time file doesn't exist, create it
if [ ! -f /root/server_cycle/start_time.txt ]; then
    date +%s > /root/server_cycle/start_time.txt
    # Since this is first run, enable the server first
    lbcli enable server --name "${SERVER_NAME}"
    sleep 30
fi

# Check if 24 hours have passed
start_time=$(cat /root/server_cycle/start_time.txt)
current_time=$(date +%s)
end_time=$((start_time + 24*60*60))

if [ $current_time -lt $end_time ]; then
    # Disable server
    lbcli disable server --name "${SERVER_NAME}"
    
    # Wait 2 minutes
    sleep 120
    
    # Reboot
    reboot
fi
EOF

# Create the enable script
cat > /root/server_cycle/enable.sh << 'EOF'
#!/bin/bash

# Check for server.name file which contains server name we are working on
if [ ! -f /root/server_cycle/server.name ]; then
    echo "`date` error: server.name file does not exist" >> /root/server_cycle/error.txt
    exit 1
fi

SERVER_NAME=$(cat /root/server_cycle/server.name)

# Wait 1 second for system to stabilize
sleep 1

# Enable server
lbcli enable server --name "${SERVER_NAME}"

# Wait for enable to complete
sleep 30

# Start next cycle
systemctl restart server-cycle
EOF

# Fix permissions
chmod 755 /root/server_cycle/cycle.sh
chmod 755 /root/server_cycle/enable.sh

# Create systemd service for main cycle
cat > /etc/systemd/system/server-cycle.service << 'EOF'
[Unit]
Description=Server Cycle Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/server_cycle/cycle.sh
Restart=no
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for enable script
cat > /etc/systemd/system/server-cycle-enable.service << 'EOF'
[Unit]
Description=Server Enable After Boot
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /root/server_cycle/enable.sh
RemainAfterExit=yes
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# Fix permissions and reload systemd
chmod 644 /etc/systemd/system/server-cycle.service
chmod 644 /etc/systemd/system/server-cycle-enable.service
systemctl daemon-reload

# Enable and start services
systemctl enable server-cycle
systemctl enable server-cycle-enable

# First enable the server since it might be disabled
lbcli enable server --name "${SERVER_NAME}"
sleep 30

# Now start the cycle service
systemctl start server-cycle

echo "Server Power Cycle script installed and started!"
echo "The server will cycle every 2 minutes for 24 hours"
echo "To check status: systemctl status server-cycle"
