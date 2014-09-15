#!/bin/bash -xe

# Copyright (C) 2014 Hewlett-Packard Development Company, L.P.
#    All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

HOSTNAME=$1
SUDO='true'
THIN='true'
PYTHON3='false'
PYPY='false'
ALL_MYSQL_PRIVS='true'
GIT_BASE=http://git.openstack.org

export http_proxy=$NODEPOOL_HTTP_PROXY
export https_proxy=$NODEPOOL_HTTPS_PROXY
export no_proxy=$NODEPOOL_NO_PROXY

TEMPFILE=`mktemp`
echo "Acquire::http::Proxy \"$http_proxy\";" >> $TEMPFILE
chmod 0444 $TEMPFILE
sudo chown root:root $TEMPFILE
sudo mv $TEMPFILE /etc/apt/apt.conf

TEMPFILE=`mktemp`
echo "Defaults env_keep += \"no_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY\"" >> $TEMPFILE
chmod 0440 $TEMPFILE
sudo chown root:root $TEMPFILE
sudo mv $TEMPFILE /etc/sudoers.d/60_keep_proxy_settings

sudo visudo -c

TEMPFILE=`mktemp`
echo "export http_proxy=$http_proxy
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,$no_proxy" >> $TEMPFILE
chmod 0444 $TEMPFILE
sudo chown root:root $TEMPFILE
sudo chmod +x $TEMPFILE
sudo mv $TEMPFILE /etc/profile.d/set_http_proxy.sh

source /etc/profile.d/set_http_proxy.sh

# Setup proxy settings in the environment, used by jenkins jobs
echo "http_proxy=$http_proxy
https_proxy=$http_proxy
ftp_proxy=$http_proxy
no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,$no_proxy" | sudo tee -a /etc/environment

#Disable ipv6
echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf


#Make sure the proxy settings are set, if not already
if [ -z $http_proxy ]; then
        export http_proxy=$http_proxy
        export https_proxy=$http_proxy
        export ftp_proxy=$http_proxy
        export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com,$no_proxy
fi

TEMPFILE=`mktemp`
echo "[global]
proxy = $http_proxy" >> $TEMPFILE
chmod 0444 $TEMPFILE
sudo chown root:root $TEMPFILE
mkdir -p ~/.pip/
sudo mv -f $TEMPFILE ~/.pip/pip.conf

#./prepare_node.sh "$HOSTNAME" "$SUDO" "$THIN" "$PYTHON3" "$PYPY" "$ALL_MYSQL_PRIVS" "$GIT_BASE"
./prepare_node_no_unbound.sh "$HOSTNAME" "$SUDO" "$THIN" "$PYTHON3" "$PYPY" "$ALL_MYSQL_PRIVS" "$GIT_BASE"

# While testing out the nodepool image creation, comment out the line below since it takes a long time.
sudo -u jenkins -i /opt/nodepool-scripts/prepare_devstack.sh $HOSTNAME

./restrict_memory.sh
