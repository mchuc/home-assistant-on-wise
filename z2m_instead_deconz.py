#!/bin/sh
docker pull koenkk/zigbee2mqtt:latest
sudo mkdir -p /var/docker/z2m
sudo chown -R root.docker /var/docker/z2m
sudo chmod -R ug+rw /var/docker/z2m
#dongle ID pobierzerz z katalogu /dev/serial/by-id
DONGLEID="usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_XXXXXXXXXXXXXXXXXX-if00-port0"
docker run -d \
--name zigbee2mqtt \
--restart=always \
--device=/dev/serial/by-id/$DONGLEID:/dev/ttyACM0 \
-p 8080:8080 \
-v /var/docker/z2m:/app/data \
-v /run/udev:/run/udev:ro \
-e TZ=Europe/Warsaw \
koenkk/zigbee2mqtt