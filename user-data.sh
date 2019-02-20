#!/usr/bin/env bash

#!/bin/bash
# ubuntu Auto install following
# Prometueus & Node exporter
# grafana

PROM_VER="2.0.0"
NODE_EXPORTER_VER="0.15.1"
GRAFANA_VER="5.4.2"



function install_pre(){
  apt-get update -y
  apt-get install -y adduser libfontconfig apt-transport-https systemd git
}
function install_go(){
  wget https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz
  tar -C /usr/local -xzf go*.tar.gz
  echo -e "\nexport PATH=$PATH:/usr/local/go/bin" >> /etc/profile
}
function install_prom(){
  useradd --no-create-home --shell /bin/false prometheus
  mkdir /etc/prometheus
  mkdir /var/lib/prometheus
  chown prometheus:prometheus /etc/prometheus
  chown prometheus:prometheus /var/lib/prometheus
  curl -LO https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
  tar xvf prometheus-*.linux-amd64.tar.gz
  cp prometheus-*.linux-amd64/prometheus /usr/local/bin/
  cp prometheus-*.linux-amd64/promtool /usr/local/bin/
  chown -R prometheus:prometheus /etc/prometheus/consoles
  chown -R prometheus:prometheus /etc/prometheus/console_libraries
  cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF



  cat <<EOF >> /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
remote_write:
  - url: "http://localhost:9201/write"
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
EOF
  systemctl daemon-reload
  systemctl enable prometheus
  systemctl start prometheus
  systemctl status prometheus
}

function install_nodeExporter(){
  useradd --no-create-home --shell /bin/false node_exporter
  curl -LO https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/node_exporter-${NODE_EXPORTER_VER}.linux-amd64.tar.gz
  tar xvf node_exporter-0.15.1.linux-amd64.tar.gz
  cp node_exporter-0.15.1.linux-amd64/node_exporter /usr/local/bin
  chown node_exporter:node_exporter /usr/local/bin/node_exporter
  rm -rf node_exporter-0.15.1.linux-amd64.tar.gz node_exporter-0.15.1.linux-amd64
  cat << EOF >  /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable node_exporter
  systemctl start node_exporter
  systemctl status node_exporter


}

function install_graphite(){
  apt-get install python-pip  python-cairo python-django --yes
  pip install cffi
  pip install -r https://raw.githubusercontent.com/graphite-project/whisper/master/requirements.txt
  pip install -r https://raw.githubusercontent.com/graphite-project/carbon/master/requirements.txt
  pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/master/requirements.txt
  export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
  pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/master
  pip install --no-binary=:all: https://github.com/graphite-project/carbon/tarball/master
  pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/master
  cp /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf
  cp /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf
  cp /opt/graphite/conf/storage-aggregation.conf.example /opt/graphite/conf/storage-aggregation.conf
  cp /opt/graphite/webapp/graphite/local_settings.py.example /opt/graphite/webapp/graphite/local_settings.py
  PYTHONPATH=/opt/graphite/webapp/ django-admin migrate  --settings=graphite.settings --run-syncdb
  chown -R www-data:www-data /opt/graphite/
  apt-get install uwsgi uwsgi-plugin-python --yes
  cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py
  cd /etc/uwsgi/apps-available/
  curl -O https://raw.githubusercontent.com/yesoreyeram/graphite-nginx-uwsgi/master/uWSGI/graphite
  ln -s /etc/uwsgi/apps-available/graphite /etc/uwsgi/apps-enabled/graphite



}

function install_storageGW(){
  go get github.com/prometheus/prometheus/documentation/examples/remote_storage/remote_storage_adapter
  cp go/bin/remote_storage_adapter /usr/local/bin/remote_storage_adapter
  cat << EOF >  /etc/systemd/system/remote_storage_adapter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/remote_storage_adapter  --graphite-address=localhost:8080

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable remote_storage_adapter
  systemctl start remote_storage_adapter
  systemctl status remote_storage_adapter
}

function install_grafana(){
  wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VER}_amd64.deb
  dpkg -i grafana_${GRAFANA_VER}_amd64.deb
  service grafana-server start
  cat << EOF >/etc/grafana/provisioning/datasources/Graphite
# config file version
apiVersion: 1

deleteDatasources:
  - name: Graphite
    orgId: 1

datasources:
- name: Graphite
  type: graphite
  access: proxy
  orgId: 1
  url: http://localhost:8080
  password:
  # <string> database user, if used
  user:
  # <string> database name, if used
  database:
  # <bool> enable/disable basic auth
  basicAuth:
  # <string> basic auth username
  basicAuthUser:
  # <string> basic auth password
  basicAuthPassword:
  # <bool> enable/disable with credentials headers
  withCredentials:
  # <bool> mark as default datasource. Max one per org
  isDefault:
  # <map> fields that will be converted to json and stored in jsonData
  jsonData:
     graphiteVersion: "1.1"
     tlsAuth: true
     tlsAuthWithCACert: true
  # <string> json object of data that will be encrypted.
  secureJsonData:
    tlsCACert: "..."
    tlsClientCert: "..."
    tlsClientKey: "..."
  version: 1
  # <bool> allow users to edit datasources from the UI.
  editable: true
EOF
}

function main(){
    install_pre
    install_go
    install_prom
    install_nodeExporter
    install_graphite
    install_storageGW
    install_grafana
}
main