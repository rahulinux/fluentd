#!/bin/bash

## This script for install and configure td-agent for Ubuntu 14.04 Distros 
## as of now only configure to read nginx access and error logs 
## and forward it to fluent server on port 24224 
## Make sure Port 24224 TCP and UDP Should be open at server end 
## to communicate with server 

## Rahul Patil<http://www.linuxian.com>

## Fluentd server IP 
logserver=IP_OF_FLUENTD_SERVER

## Path of log files 
nginx_acces_log=$( echo /opt/chroot/opt/nginx/logs/{DOMAIN.COM.access.log,access.log} )
nginx_error_log=$( echo /opt/chroot/opt/nginx/logs/{DOMAIN.COM.error.log,error.log} )

## Install fluentd 
if ! dpkg -l | grep -q td-agent
then
  if lsb_release -c | grep -q trusty
  then
      curl -L http://toolbelt.treasuredata.com/sh/install-ubuntu-trusty-td-agent2.sh | sh
  else
      cd /usr/local/src/
      wget http://packages.treasuredata.com.s3.amazonaws.com/2/ubuntu/precise/pool/contrib/t/td-agent/td-agent_2.1.0-0_amd64.deb
      dpkg -i td-agent_2.1.0-0_amd64.deb
  fi
else 
  echo "This script only for Ubuntu"
  exit 1
fi 

## take backup of default conf
conf=/etc/td-agent/td-agent.conf
[[ ! -f ${conf}-default ]] && mv -v /etc/td-agent/td-agent.conf{,-default}

cat <<_EOF >> ${conf}
###############################################
## nginx logs to fluentd server
## Forwarding
## match tag=** and forward to another td-agent server
#
<match nginx.**>
  type forward
  send_timeout 10s
  recover_wait 5s
  heartbeat_interval 1s
  phi_threshold 16
  hard_timeout 60s

  <server>
    #name fluentdserver
    host $logserver
    port 24224
    weight 20
  </server>
</match>


## match tag=debug.** and dump to console
#<match debug.**>
#  type stdout
#</match>
_EOF

for log in $nginx_acces_log
do

## Configure fluentd agent 
cat <<_EOF >> ${conf} 
# Forward access log to Fluentd Server
<source>
  type tail
  # nginx customize format :
  # log_format main '$remote_addr $hostname $remote_user [$time_local] ' '"$request" $status $body_bytes_sent $request_time "$http_referer" ' '"$http_user_agent"';
  format /^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*)+ \S*)?" (?<code>[^ ]*) (?<size>[^ ]*) (?<request_time>[^ ]*) "(?<referer>[^\"]*)" "(?<agent>[^\"]*)"$/ 
  path $log
  tag nginx.access
  # Select a file to store offset position
  pos_file $(mktemp -u --suffix=-nginx-access-td-agent)
</source>
_EOF
done

for log in $nginx_error_log
do
cat <<_EOF >> ${conf}
# Forward error log to Fluentd Server
<source>
  type tail
  format /^(?<time>[^ ]+ [^ ]+) \[(?<log_level>.*)\] (?<pid>[0-9]*).(?<tid>[^:]*): (?<message>.*), client:(?<remote_addr>.*), server:(?<server>.*), request:(?<request>.*), host:(?<host>.*)/
  tag nginx.error
  pos_file $(mktemp -u --suffix=-nginx-error-td-agent)
  path $log
  time_format %Y/%m/%d %H:%M:%S
</source>
_EOF
done
