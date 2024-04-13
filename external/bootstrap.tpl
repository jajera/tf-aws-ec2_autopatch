#!/bin/bash
# install ssm agent
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent
hostnamectl set-hostname ${FQDN}

# install the cloudwatch logs agent
yum install -y awslogs
systemctl start awslogsd
systemctl enable awslogsd.service

# configuration for cloudwatch logs agent
cat >/etc/awslogs/awslogs.conf <<-CONFIG
[/var/log/messages]
file = /var/log/messages
log_group_name = /ec2/instance/logs
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S
CONFIG

service awslogsd restart
