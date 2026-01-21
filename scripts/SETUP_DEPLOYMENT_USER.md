# VPS Deployment User Setup

This guide will help you set up a secure, non-root deployment user on your VPS for the Salongroei deployment scripts.

## Why Use a Non-Root User?

Using a dedicated deployment user instead of root provides:
- **Security**: Limited sudo permissions (only what's needed for deployment)
- **Safety**: Cannot accidentally run destructive commands
- **Auditing**: Clear separation between deployment and system administration
- **Best Practice**: Follows principle of least privilege

## Setup Steps

### Step 1: Prepare Your SSH Key

On your local machine, copy your public SSH key to clipboard:

```bash
cat ~/.ssh/id_rsa.pub | pbcopy
```

Or if you have a different key:

```bash
cat ~/.ssh/id_ed25519.pub | pbcopy
```

Keep this handy - you'll need to paste it during setup.

### Step 2: Run Setup Script on VPS

From your local machine, run:

```bash
ssh root@31.97.217.189 'bash -s' < scripts/setup_vps_deploy_user.sh
```

This will:
1. Create user `kasper` on the VPS
2. Set up your SSH key for authentication
3. Configure limited sudo permissions
4. Set up temp user infrastructure
5. Install required tools (`at` command)

**During setup, you'll be prompted to paste your SSH public key.**

### Step 3: Test SSH Access

Open a **NEW terminal window** and test SSH access:

```bash
ssh kasper@31.97.217.189
```

If successful, you should be able to log in without a password.

**⚠️ Important**: Test this BEFORE closing your root SSH session!

### Step 4: Update Local Config (Optional)

The deployment script now defaults to `kasper` user. If you want to override:

```bash
# In your terminal, set these before running deploy_prod.sh
export SERVER_USER=kasper
export REMOTE_SUDO=sudo
```

Or create a `.env` file if needed.

### Step 5: Verify Deployment Script

Run the deployment script:

```bash
./scripts/deploy_prod.sh
```

You should see the SSH authentication succeed with the `kasper` user.

## What Permissions Does kasper Have?

The `kasper` user has limited sudo access for:

### User Management
- Create/delete users (for temp SSH users)
- Modify user groups

### File Operations
- Manage `/var/www/*` directories
- Manage `/opt/salongroei/*` directories
- Change ownership and permissions in these locations

### Nginx
- Test nginx config
- Reload/restart nginx service
- Manage sites-available/sites-enabled

### SSL/Certbot
- Run certbot commands

### Docker (if installed)
- All docker commands (for future use)

### Read-Only Operations
- View logs with journalctl
- List files and directories
- Read configuration files

### Temp User Management
- Schedule tasks with `at` command
- Manage sudoers.d for temp users

## Using Temp User Features

Once setup is complete, use the deployment menu:

```bash
./scripts/deploy_prod.sh
```

- **Option 7**: Create temporary SSH user (1-hour, limited access + docker)
- **Option 8**: Create firefighter user (1-hour, FULL sudo - emergencies only)

Temp users will:
- Use the same SSH key as `kasper`
- Expire automatically after 1 hour
- Have credentials saved to `scripts/temp-user.txt`

## Troubleshooting

### Cannot SSH with kasper user

1. Make sure you used the correct SSH public key
2. Check on VPS: `sudo cat /home/kasper/.ssh/authorized_keys`
3. Verify permissions: `sudo ls -la /home/kasper/.ssh/`

### "Permission denied" during deployment

1. Check if REMOTE_SUDO is set: `echo $REMOTE_SUDO`
2. Test sudo access: `ssh kasper@31.97.217.189 'sudo -n whoami'`
3. Verify sudoers file: `ssh root@31.97.217.189 'cat /etc/sudoers.d/kasper'`

### Temp user creation fails

1. Verify prefix exists: `ssh kasper@31.97.217.189 'cat /opt/salongroei/.temp_user_prefix'`
2. Check atd service: `ssh kasper@31.97.217.189 'sudo systemctl status atd'`
3. Test user creation: `ssh kasper@31.97.217.189 'sudo useradd --help'`

## Reverting to Root User

If you need to use root temporarily:

```bash
export SERVER_USER=root
export REMOTE_SUDO=
./scripts/deploy_prod.sh
```

## Security Notes

- The `kasper` user **cannot** modify system-level configs outside deployment scope
- Temp users are automatically deleted after 1 hour
- Firefighter users should only be created for genuine emergencies
- All sudo commands are logged in system logs for auditing
