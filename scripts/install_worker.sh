#!/bin/bash
exec > /var/log/install_worker.log 2>&1

echo "[1] Updating packages..."
dnf update -y
dnf install -y python3 python3-pip git

echo "[2] Installing Python dependencies..."
pip3 install pika pymongo boto3 fastapi uvicorn

echo "[3] Cloning repo..."
rm -rf /app
git clone https://github.com/JACardonaMorales/ChefGPT2-app.git /app

echo "[4] Creating systemd service..."
cat > /etc/systemd/system/worker.service << 'EOF'
[Unit]
Description=ChefGPT2 Worker
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/app
ExecStart=/usr/bin/python3 /app/worker.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

echo "[5] Enabling and starting service..."
systemctl daemon-reload
systemctl enable worker
systemctl start worker

echo "[6] Done."