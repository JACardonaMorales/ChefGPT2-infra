#!/bin/bash
dnf update -y
dnf install -y python3 python3-pip git

pip3 install fastapi uvicorn pika pymongo boto3

git clone https://github.com/JACardonaMorales/ChefGPT2-app.git /app
cd /app

nohup uvicorn api:app --host 0.0.0.0 --port 8000 > /tmp/api.log 2>&1 &
