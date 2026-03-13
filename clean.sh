#!/bin/bash

docker compose down --rmi all
docker builder prune
docker compose rm

