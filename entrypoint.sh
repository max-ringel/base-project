#!/bin/bash
[ "$GIT_USER_NAME" ] && git config --global user.name "$GIT_USER_NAME"
[ "$GIT_USER_EMAIL" ] && git config --global user.email "$GIT_USER_EMAIL"
[ "$GITHUB_TOKEN" ] && git config --global credential.helper '!f() { echo "password=$GITHUB_TOKEN"; }; f'

exec "$@"