#!/usr/bin/env bash

echo "deb http://ftp.au.debian.org/debian testing main" >> /etc/sources.list

apt-get update
apt-get install -y ruby-dev rubygems git libsqlite3-dev puppet

gem install bundler

mkdir -p /app/
cd /app/

git clone https://github.com/bstascavage/groupme_stats.git

cd groupme_stats/
bundle install

#cp camping/debain-service/camping-server /etc/init.d/

#service camping-server start


