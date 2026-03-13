#!/bin/bash

has_flag() {
    grep -q "^--> $1" ./setup.txt && echo "true" || echo "false";
}

INSTALL_CLAUDE_CODE=$(has_flag "claude_code");
INSTALL_PYTHON3=$(has_flag "python3");
INSTALL_NODEJS=$(has_flag "nodejs");

echo "Baue Image mit: Claude=$INSTALL_CLAUDE_CODE, Python=$INSTALL_PYTHON3, Node=$INSTALL_NODEJS";

docker compose build \
    --build-arg CACHEBUST=$(date +%s) \
    --build-arg INSTALL_CLAUDE_CODE=$INSTALL_CLAUDE_CODE \
    --build-arg INSTALL_PYTHON3=$INSTALL_PYTHON3 \
    --build-arg INSTALL_NODEJS=$INSTALL_NODEJS;

docker compose up -d;
docker compose exec -it app zsh;
