#!/usr/bin/env bash
set -euxo pipefail

sudo su postgres

createuser candy
createuser --interactive candy
# dropuser candy

createdb mydb
dropdb mydb