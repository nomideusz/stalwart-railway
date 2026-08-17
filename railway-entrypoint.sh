#!/bin/sh
# Stalwart persists two paths: /etc/stalwart holds config.json (the pointer to
# the store) and /var/lib/stalwart holds the RocksDB store itself — accounts,
# mail, and every setting made in the web UI. Railway allows one volume per
# service, so relocate both onto /data. Without this, a redeploy starts the
# server in bootstrap mode again and the previous mailboxes are gone.
set -e

# The image's WORKDIR is one of the paths replaced below; don't sit in it.
cd /

if [ -d /data ]; then
  for pair in etc:/etc/stalwart data:/var/lib/stalwart; do
    target="/data/${pair%%:*}"
    path="${pair#*:}"
    mkdir -p "$target"
    if [ ! -L "$path" ]; then
      # First boot: the image ships both paths empty, nothing to preserve.
      rm -rf "$path"
      ln -sfn "$target" "$path"
    fi
  done
fi

exec /usr/local/bin/stalwart "$@"
