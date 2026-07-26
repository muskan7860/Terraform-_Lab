#!/bin/bash

apt update -y
apt install -y python3
apt install -y docker.io

systemctl enable docker
systemctl start docker

echo "Bootstrap completed" > /tmp/bootstrap.log