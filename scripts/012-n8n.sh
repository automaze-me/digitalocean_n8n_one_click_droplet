#!/bin/sh

cd /opt
git clone https://github.com/n8n-io/n8n-docker-caddy.git
cd n8n-docker-caddy

# set data directory in .env file
sed -i "s/<directory-path>/opt/g" ".env"

docker volume create caddy_data
docker volume create n8n_data


