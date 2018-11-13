#!/bin/sh
ansible-playbook ../deploy-app.yml -e env="staging" -i ../hosts/staging -u ubuntu "$@"
