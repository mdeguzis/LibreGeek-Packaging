# Docker image for building rpm packages
FROM centos:7
MAINTAINER Michael DeGuzis <mdeguzis@gmail.com>

USER root

# Env vars
ENV GET_PIP="https://bootstrap.pypa.io/get-pip.py"

# GPG keys and packages
#RUN rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 \
RUN gpg="gpg --no-default-keyring --secret-keyring /dev/null --keyring /dev/null --no-option --keyid-format 0xlong" && \
    rpmkeys --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    rpm -qi gpg-pubkey-f4a80eb5 | $gpg | grep 0x24C6A8A7F4A80EB5 && \
    rpmkeys --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 && \
    rpm -qi gpg-pubkey-352c64e5 | $gpg | grep 0x6A2FAEA2352C64E5 && \
    rpmkeys --import https://openresty.org/package/pubkey.gpg && \
    rpm -qi gpg-pubkey-d5edeb74 | $gpg | grep 0x97DB7443D5EDEB74 && \
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
#
# packages
#
RUN yum update -y && \
	yum --enablerepo=updates clean metadata && \
	yum install -y epel-release && \
	# build tools
	yum install -y rpm-devel rpmlint rpmdevtools \
	# other stuffs..
	gzip2-devel gcc git-core hostname \
	java-1.8.0-openjdk-devel openssl-devel python-pip \
	tar unzip vim

# dev packages
RUN yum groups mark convert && \
	yum groupinstall -y "Development tools"

# Build area setup
RUN mkdir -p /home/builder

# Set workdir
WORKDIR /home/builder
