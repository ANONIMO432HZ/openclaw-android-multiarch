# Termux SSH Setup Guide

By connecting to Termux via SSH from your computer, you can type all commands using your computer keyboard.

## Prerequisites

- Both phone and computer must be on the **same Wi-Fi network**

## Step 1: Install openssh

Open the Termux app on your phone and type:

```bash
pkg install -y openssh
```

Wait for the installation to complete (1-2 minutes).

## Step 2: Set Password

```bash
passwd
```

Enter a password (e.g., `1234`):

```
New password: 1234          ← type
Retype new password: 1234   ← type the same password again
```

> It's normal that nothing shows on screen while typing the password. Just type it and press Enter.

## Step 3: Start SSH Server

> **Important**: Run `sshd` directly in the Termux app on your phone, not via SSH.

```bash
sshd
```

If the prompt (`$`) returns with no error message, it's working.

<img src="images/termux_tab_2.png" width="300" alt="sshd running in Termux">

## Step 4: Find the Phone's IP Address

```bash
ifconfig
```

Look for the `wlan0` section:

```
wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.45.139  netmask 255.255.255.0
```

The number after `inet` is your phone's IP address (in this example, `192.168.45.139`).

## Step 6: Dashboard Tunneling (Recommended)
OpenClaw's web dashboard often restricts access to `localhost` for security. To access it from your PC browser, you need to "tunnel" the ports:

1. Close your current SSH connection (type `exit`)
2. Reconnect using this command:
   ```bash
   ssh -p 8022 -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 u0_aXXX@IP_ADDRESS
   ```
3. Open your PC browser and go to: `http://localhost:18789`

**What do these flags mean?**
- `-L 18789:127.0.0.1:18789`: Maps the phone's Dashboard port to your PC's localhost.
- `-L 18791:127.0.0.1:18791`: Maps the Gateway's communication port.
- This bypasses `Origin not allowed` errors and lets you use the visual dashboard on your big screen.

Once connected, you'll see the Termux `$` prompt. From now on, you can type all Termux commands using your computer keyboard and view the UI in your browser.

## Notes

- Termux uses SSH port **8022** (not the standard Linux port 22)
- If you close the Termux app, the SSH server stops. To reconnect, open Termux on the phone and run `sshd`
