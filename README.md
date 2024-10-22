# Server Power Cycle Script

## Overview
The `server-power-cycle.sh` script automates the process of cycling a server through disable/enable states with reboots for a 24-hour period. This is particularly useful for testing server resilience and state transitions.

## Features
- Cycles server every 2 minutes for 24 hours
- Disables server, waits 2 minutes, reboots
- Enables server 1 second after reboot
- Maintains cycle through system reboots
- Automatically stops after 24 hours

## Prerequisites
- Root access to the server
- `lbcli` command line tool installed
- SystemD-based Linux system

## Installation and Usage
1. Save script as `/root/server-power-cycle.sh`
2. Make script executable:
```bash
chmod +x /root/server-power-cycle.sh
```
3. Run the script:
```bash
 ./root/server-power-cycle.sh
```

## Cycle Process
1. Initial setup:
   - Creates necessary directories and service files
   - Enables the server if currently disabled
   - Waits 30 seconds for stable state

2. Main cycle:
   - Disables server using `lbcli disable server --name server00`
   - Waits 2 minutes
   - Reboots system
   - Waits 1 second after reboot
   - Enables server using `lbcli enable server --name server00`
   - Repeats

## Monitoring
- Check service status:
```bash
systemctl status server-cycle
```

- View system journal:
```bash
journalctl -u server-cycle
journalctl -u server-cycle-enable
```

## Stopping the Cycle
To stop the cycle before 24 hours:
```bash
systemctl stop server-cycle
systemctl disable server-cycle
systemctl disable server-cycle-enable
```

## Files Created
- Main script: `/root/server_cycle/cycle.sh`
- Enable script: `/root/server_cycle/enable.sh`
- SystemD services:
  - `/etc/systemd/system/server-cycle.service`
  - `/etc/systemd/system/server-cycle-enable.service`
- Timestamp file: `/root/server_cycle/start_time.txt`

