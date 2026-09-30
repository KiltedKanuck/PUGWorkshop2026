# AWS k6 Runtime Setup

This guide details the full setup instructions for creating an EC2 instance which can run the k6 tests for OpenEdge Dev Suite (OELS).

## Initial Updates

`sudo apt update && sudo apt upgrade`

## Add a Swap File

Follow the [SWAPFILE.md](SWAPFILE.md) guide.

## Implement the `earlyoom` Service

Follow the [EARLYOOM.md](EARLYOOM.md) guide.

## Install Basic Tools

```
sudo apt install -y \
  curl \
  wget \
  unzip \
  jq \
  git \
  htop \
  btop \
  vim \
  net-tools \
  dnsutils \
  ca-certificates \
  gnupg \
  lsof \
  sysstat \
  ufw
```

## Install k6 and Supporting Utilities

```
sudo gpg -k

curl -fsSL https://dl.k6.io/key.gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | \
sudo tee /etc/apt/sources.list.d/k6.list

sudo apt update
sudo apt install -y k6
```

```
sudo apt install -y \
  cloud-guest-utils \
  build-essential \
  linux-tools-common \
  linux-tools-generic
```

> For some Linux distributions such as Rocky Linux, using the `yum` package manager may be required.
> For that distro first run `sudo yum install https://dl.k6.io/rpm/repo.rpm` then `sudo yum install k6`.

## Kernel Tuning and System Limits

```
# ---- Kernel tuning (persistent) ----
sudo tee /etc/sysctl.d/99-k6.conf > /dev/null << 'EOF'
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65536
fs.file-max = 1000000
EOF

# Apply immediately
sudo sysctl --system

# ---- File descriptor limits (persistent) ----
sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'
* soft nofile 250000
* hard nofile 250000
EOF

# ---- systemd limits (important for services + ssh sessions) ----
sudo sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=250000/' /etc/systemd/system.conf
sudo sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=250000/' /etc/systemd/user.conf

# Reload systemd
sudo systemctl daemon-reexec

# ---- Apply for current shell immediately ----
ulimit -n 250000

# ---- Show current effective values ----
echo "ulimit:" && ulimit -n
echo "port range:" && cat /proc/sys/net/ipv4/ip_local_port_range
```

## Update Tests

Unzip the latest to a tests directory:

`unzip pug-1.0.0-k6-tests.zip`

Make the helper scripts executable:

`chmod 775 tests/*.sh`