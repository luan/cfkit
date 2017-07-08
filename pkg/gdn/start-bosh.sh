#!/usr/bin/env bash

set -e

export LOG_DIR=/var/lib/gdn/log
mkdir -p $LOG_DIR

exec 1> $LOG_DIR/bosh.out.log
exec 2> $LOG_DIR/bosh.err.log

main() {
  # source /etc/profile.d/chruby.sh
  # chruby 2.3.1

  # export OUTER_CONTAINER_IP=$(ruby -rsocket -e 'puts Socket.ip_address_list
  #                         .reject { |addr| !addr.ip? || addr.ipv4_loopback? || addr.ipv6? }
  #                         .map { |addr| addr.ip_address }')
  export OUTER_CONTAINER_IP=127.0.0.1

  export GARDEN_HOST=${OUTER_CONTAINER_IP}

  start-garden

  local local_bosh_dir
  local_bosh_dir="/var/lib/gdn/director"
  cp -a /usr/local/bosh-deployment /var/lib/gdn

  export BOSH_HOME=/var/lib/gdn/.bosh
  mkdir -p $BOSH_HOME
  export BOSH_CONFIG=$BOSH_HOME/config
  export HOME=/var/lib/gdn

  pushd /var/lib/gdn/bosh-deployment > /dev/null
      export BOSH_DIRECTOR_IP="10.245.0.3"
      export BOSH_ENVIRONMENT="warden-director"

      mkdir -p ${local_bosh_dir}

      command bosh int bosh.yml \
        -o jumpbox-user.yml \
        -o bosh-lite.yml \
        -o bosh-lite-runc.yml \
        -o warden/cpi.yml \
        -v director_name=warden \
        -v internal_cidr=10.245.0.0/16 \
        -v internal_gw=10.245.0.1 \
        -v internal_ip="${BOSH_DIRECTOR_IP}" \
        -v garden_host="${GARDEN_HOST}" \
        ${@} > "${local_bosh_dir}/bosh-director.yml"

      command bosh create-env "${local_bosh_dir}/bosh-director.yml" \
              --vars-store="${local_bosh_dir}/creds.yml" \
              --state="${local_bosh_dir}/state.json"

      bosh int "${local_bosh_dir}/creds.yml" --path /director_ssl/ca > "${local_bosh_dir}/ca.crt"
      bosh -e "${BOSH_DIRECTOR_IP}" --ca-cert "${local_bosh_dir}/ca.crt" alias-env "${BOSH_ENVIRONMENT}"

      cat <<EOF > "${local_bosh_dir}/env"
      export BOSH_ENVIRONMENT="${BOSH_ENVIRONMENT}"
      export BOSH_CLIENT=admin
      export BOSH_CLIENT_SECRET=`bosh int "${local_bosh_dir}/creds.yml" --path /admin_password`
      export BOSH_CA_CERT="${local_bosh_dir}/ca.crt"

EOF
      source "${local_bosh_dir}/env"

      bosh -n update-cloud-config warden/cloud-config.yml

      route add -net 10.244.0.0/16 gw ${BOSH_DIRECTOR_IP}

  popd > /dev/null
}

main $@

wait
