# 🔔 Gotify (Fly.io Edition)

[![Fly.io](https://img.shields.io/badge/Fly.io-Deploy-purple?style=for-the-badge&logo=flydotio)](https://fly.io)
[![Docker](https://img.shields.io/badge/Docker-ghcr.io-blue?style=for-the-badge&logo=docker)](https://ghcr.io/webees/gotify)
[![Gotify](https://img.shields.io/badge/Gotify-v2.6-green?style=for-the-badge)](https://github.com/gotify/server)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

> Production-ready Gotify on Fly.io with Caddy reverse proxy, Overmind process manager, and automated Restic backups to Cloudflare R2.

## ✨ Features

| Component | Description |
| :--- | :--- |
| **Gotify** | Self-hosted push notification server |
| **Caddy** | Automatic HTTPS, security headers, Cloudflare IP forwarding |
| **Overmind** | Tmux-based process manager (graceful restarts) |
| **Supercronic** | Cron daemon for containers |
| **Restic** | Encrypted incremental backups with retention policy |
| **msmtp** | Email notifications on backup failures |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Fly.io Edge                        │
└───────────────────────────┬─────────────────────────────┘
                            │ :443
┌───────────────────────────▼─────────────────────────────┐
│                        Caddy                            │
│              (TLS termination, headers)                 │
└───────────────────────────┬─────────────────────────────┘
                            │ :8080
┌───────────────────────────▼─────────────────────────────┐
│                        Gotify                           │
│                   (Push notifications)                  │
└─────────────────────────────────────────────────────────┘
         │
         │ Hourly backup
         ▼
┌─────────────────────────────────────────────────────────┐
│                  Restic → Cloudflare R2                 │
│          (7 daily, 4 weekly, 3 monthly, 3 yearly)       │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Create App & Volume

```bash
fly auth login
fly apps create gotify
cat .env | fly secrets import
fly volumes create app_data --region hkg --size 1
fly deploy
fly ssh console
```

### 2. Configure Secrets

```bash
# Required: Cloudflare R2 backup
fly secrets set RESTIC_PASSWORD="your-password"
fly secrets set RESTIC_REPOSITORY="s3:your-account-id.r2.cloudflarestorage.com/gotify"
fly secrets set AWS_ACCESS_KEY_ID="your-r2-access-key"
fly secrets set AWS_SECRET_ACCESS_KEY="your-r2-secret-key"

# Optional: Custom domains (default: :80)
fly secrets set CADDY_DOMAINS="gotify.example.com:80"

# Optional: Email notifications
fly secrets set SMTP_HOST="smtp.gmail.com"
fly secrets set SMTP_PORT="587"
fly secrets set SMTP_FROM="your@email.com"
fly secrets set SMTP_TO="notify@email.com"
fly secrets set SMTP_USERNAME="your@email.com"
fly secrets set SMTP_PASSWORD="app-password"
```

### 3. Deploy

```bash
fly deploy
```

## 🛠️ Management

### Fly CLI

> Use `-a <app-name>` to specify app when not in project directory.

```bash
# SSH into container
fly ssh console
fly ssh console -a gotify

# View logs
fly logs
fly logs -a gotify

# Deploy
fly deploy
fly deploy -a gotify

# Manage secrets
fly secrets list -a gotify
fly secrets set KEY=value -a gotify

# App status
fly status -a gotify
fly apps list

# Scale & restart
fly scale count 1 -a gotify
fly apps restart gotify
```

### Backup Commands (via SSH)

```bash
/restic.sh backup              # Run manual backup
/restic.sh snapshots           # List all snapshots
/restic.sh restore <id>        # Restore from snapshot
```

### View Logs (via SSH)

```bash
cat /var/log/restic/*.log      # Backup logs
tail -f /var/log/msmtp.log     # Email logs
```

## 📁 Configuration

| File | Purpose |
| :--- | :--- |
| `config/Caddyfile` | Reverse proxy, security headers |
| `config/Procfile` | Process definitions for Overmind |
| `config/crontab` | Backup schedule (default: hourly) |
| `scripts/restic.sh` | Backup script with email alerts |

## 🔒 Security

- **HSTS**: Strict-Transport-Security enabled
- **XSS Protection**: X-XSS-Protection header
- **Clickjacking**: X-Frame-Options DENY
- **MIME Sniffing**: X-Content-Type-Options nosniff
- **No Indexing**: X-Robots-Tag noindex, nofollow
- **Cloudflare**: CF-Connecting-IP forwarded as X-Real-IP

## 📊 Backup Retention

| Period | Kept |
| :--- | :--- |
| Daily | 7 |
| Weekly | 4 |
| Monthly | 3 |
| Yearly | 3 |

## 🔧 Environment Variables

| Variable | Required | Description |
| :--- | :--- | :--- |
| `CADDY_DOMAINS` | ❌ | Caddy domains (default: `:80`) |
| `RESTIC_PASSWORD` | ✅ | Encryption password for backups |
| `RESTIC_REPOSITORY` | ✅ | R2 URL: `s3:<account-id>.r2.cloudflarestorage.com/<bucket>` |
| `AWS_ACCESS_KEY_ID` | ✅ | Cloudflare R2 Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | ✅ | Cloudflare R2 Secret Access Key |
| `SMTP_HOST` | ❌ | SMTP server for notifications |
| `SMTP_PORT` | ❌ | SMTP port (default: 587) |
| `SMTP_FROM` | ❌ | Sender email address |
| `SMTP_TO` | ❌ | Recipient for backup alerts |
| `SMTP_USERNAME` | ❌ | SMTP authentication user |
| `SMTP_PASSWORD` | ❌ | SMTP authentication password |

## 📚 References

- [Gotify Documentation](https://gotify.net/docs/)
- [Gotify GitHub](https://github.com/gotify/server)

## 📝 License

MIT

---

Made with ❤️ for 🔔