#!/bin/bash

docker compose down --rmi all
docker image prune -f
docker builder prune -f
