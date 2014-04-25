#!/bin/bash
## ssh -CfNg -D 127.0.0.1:port username@hotsname 
sudo ssh -CfNg -D 127.0.0.1:1088 533c68a2e0b8cd34700002f0@wp-hcaijin.rhcloud.com
ps aux | grep 1088
