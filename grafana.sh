#!/bin/sh
sudo mkdir -p /var/docker/grafana/data
sudo chown -R root.docker /var/docker
sudo chmod -R ug+rw /var/docker
#sudo usermod -a -G dialout root
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release -y -f
sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin git -y -f

sudo apt-get update
sudo apt-get upgrade -y

docker run --restart=always -d -p 3000:3000 --name=grafana -v /var/docker/grafana/data:/var/lib/grafana grafana/grafana-oss
