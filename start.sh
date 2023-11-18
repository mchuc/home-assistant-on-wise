#!/bin/sh
#configure Z-Wave JS Server
# These are only sample slogans,
# change them to your own
# to są hasła przykładowe
# zmień je na swoje
S2_ACCESS_CONTROL_KEY="7764841BC794A54442E324682A550CEF"
S2_AUTHENTICATED_KEY="66EA86F088FFD6D7497E0B32BC0C8B99"
S2_UNAUTHENTICATED_KEY="2FAB1A27E19AE9C7CC6D18ACEB90C357"
S0_LEGACY_KEY="17DFB0C1BED4CABFF54E4B5375E257B3"
NETWORK="ha-on-wyse"
IPS="192.17.0"

#
docker network create --subnet=$IPS.0/16 $NETWORK

################### change if You know, what to do!
# zmień, jeżeli wiesz, co robisz!

#create dirs
sudo mkdir -p /var/docker/home-assistant/data
sudo mkdir -p /var/docker/home-assistant/config/custom_components/nodered
sudo mkdir -p /var/docker/node-red/data
sudo mkdir -p /var/docker/deconz/config
sudo mkdir -p /var/docker/zwave-js-server/cache

#add permission
sudo chown -R root.docker /var/docker
sudo chmod -R ug+rw /var/docker
sudo chmod -R a+wrx /var/docker/node-red
#use of /dev/ttyACM0 etc
sudo usermod -a -G dialout $USER
sudo usermod -a -G dialout root

#remove old docker and instal a new one
#from https://docs.docker.com/engine/install/ubuntu/
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

#instal zig-bee conbee
sudo wget -O - http://phoscon.de/apt/deconz.pub.key | \
           sudo apt-key add -
sudo sudo sh -c "echo 'deb [arch=amd64] http://phoscon.de/apt/deconz \
            $(lsb_release -cs) main' > \
            /etc/apt/sources.list.d/deconz.list"
sudo apt update
#apt update --allow-insecure-repositories
#sudo apt install deconz -y -f
#sudo systemctl enable deconz.service
#sudo systemctl start deconz.serivce


# go to /dev/serial/
sudo docker run -d \
--name=deconz \
--restart=always \
--ip $IPS.5 \
-v /etc/localtime:/etc/localtime:ro \
-v '/var/docker/deconz/config':/root/.local/share/dresden-elektronik/deCONZ \
--device=/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2123062-if00
:/dev/ttyACM99 \
-e DECONZ_WEB_PORT=80 \
-e DECONZ_WS_PORT=443 \
-e DECONZ_VNC_PORT=5900 \
-e DECONZ_VNC_PASSWORD=test \
-e DECONZ_VNC_MODE=1 \
-e DECONZ_DEVICE=/dev/ttyACM99 \
-p 8124:80 \
-p 8125:443 \
-p 8126:5900 \
marthoc/deconz

####
# to edit service run: nanp /lib/systemd/system/deconz.service
# and set Your own port like 8124 or above

#install Z-Wave JS server
sudo touch /var/docker/zwave-js-server/.env
sudo echo "S2_ACCESS_CONTROL_KEY=$S2_ACCESS_CONTROL_KEY" >> /var/docker/zwave-js-server/.env
sudo echo "S2_AUTHENTICATED_KEY=$S2_AUTHENTICATED_KEY" >> /var/docker/zwave-js-server/.env
sudo echo "S2_UNAUTHENTICATED_KEY=$S2_UNAUTHENTICATED_KEY" >> /var/docker/zwave-js-server/.env
sudo echo "S0_LEGACY_KEY=$S0_LEGACY_KEY" >> /var/docker/zwave-js-server/.env
#sudo bash -c 'cat << EOF > /var/docker/zwave-js-server/.env
#S2_ACCESS_CONTROL_KEY=$S2_ACCESS_CONTROL_KEY
#S2_AUTHENTICATED_KEY=$S2_AUTHENTICATED_KEY
#S2_UNAUTHENTICATED_KEY=$S2_UNAUTHENTICATED_KEY
#S0_LEGACY_KEY=$S0_LEGACY_KEY
#EOF'

sudo docker run -d --name=jsc --restart=always -p 3000:3000 -v "/var/docker/zwave-js-server/cache:/cache" --env-file=/var/docker/zwave-js-server/.env --device "/dev/serial/by-id/usb-0658_0200-if00:/dev/zwave" kpine/zwave-js-server:latest

#install node-red
sudo apt-get install g++ build-essential make -y
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
sudo docker run -d --name=nodered --restart=always \
-p 1880:1880 \
-e 'TZ'='Europe/Warsaw' \
-v /etc/localtime:/etc/localtime:ro \
-v '/var/docker/node-red/data':'/data' \
nodered/node-red:latest

#creates plugin for NodeRed : node-red-contrib-home-assistant-websocket
#you have to add integeration (in Home Assistant) for NodeRed (url: http://[IP]:8123/config/integrations)
#and then link it in Node-Red, after You install node-red-contrib-home-assistant-websocket
sudo git clone https://github.com/zachowj/hass-node-red.git /var/docker/home-assistant/data/hass
sudo cp -R /var/docker/home-assistant/data/hass/custom_components /var/docker/home-assistant/config/custom_components/nodered


#home assistant
sudo docker run --restart always \
-d --name homeassistant \
-v /var/docker/home-assistant/config:/config \
-v /var/docker/home-assistant/data:/data \
-e TZ=Europe/Warsaw \
--net=host \
ghcr.io/home-assistant/home-assistant:stable
