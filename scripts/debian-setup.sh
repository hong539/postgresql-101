#!/usr/bin/env bash
set -euxo pipefail

# src: https://www.postgresql.org/download/linux/debian/

sudo apt install postgresql

# PostgreSQL Apt Repository
# sudo apt install -y postgresql-common
# sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh