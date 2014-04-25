#!/bin/sh
echo "start lighttpd & mysqld";
sudo systemctl start lighttpd.service
sudo systemctl start mysqld.service
