#!/usr/bin/env bash
set -euxo pipefail

# build-essential for make postgresql
sudo apt update
sudo apt install -y bison \
                    flex \
                    libreadline-dev \
                    zlib1g-dev \
                    libxml2-dev \
                    libicu-dev \
                    pkg-config \
                    build-essential

# for clang-19
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-get install clang-19 lldb-19 lld-19

# postgresql source
wget https://ftp.postgresql.org/pub/source/v17.5/postgresql-17.5.tar.gz
wget https://ftp.postgresql.org/pub/source/v17.5/postgresql-17.5.tar.gz.sha256

echo "sha256sum check"
if sha256sum -c "postgresql-17.5.tar.gz.sha256"; then
    echo "check pass"
else
    echo "check failed"
    exit 1
fi

tar -xvzf postgresql-17.5.tar.gz

cd postgresql-17.5

./configure

make