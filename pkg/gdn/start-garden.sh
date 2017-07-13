#!/usr/bin/env bash

set -e -x

permit_device_control() {
  local devices_mount_info=$(cat /proc/self/cgroup | grep devices)

  if [ -z "$devices_mount_info" ]; then
    # cgroups not set up; must not be in a container
    return
  fi

  local devices_subsytems=$(echo $devices_mount_info | cut -d: -f2)
  local devices_subdir=$(echo $devices_mount_info | cut -d: -f3)

  if [ "$devices_subdir" = "/" ]; then
    # we're in the root devices cgroup; must not be in a container
    return
  fi

  RUN_DIR=$(mktemp -d)
  cgroup_dir=${RUN_DIR}/devices-cgroup

  if [ ! -e ${cgroup_dir} ]; then
    # mount our container's devices subsystem somewhere
    mkdir ${cgroup_dir}
  fi

  if ! mountpoint -q ${cgroup_dir}; then
    mount -t cgroup -o $devices_subsytems none ${cgroup_dir}
  fi

  # permit our cgroup to do everything with all devices
  echo a > ${cgroup_dir}${devices_subdir}/devices.allow

  umount ${cgroup_dir}
}

create_loop_devices() {
  set +e
  amt=${1:-256}
  for i in $(seq 0 $amt); do
    if ! mknod -m 0660 /dev/loop$i b 7 $i; then
      break
    fi
  done
  set -e
}

store_mountpoint() {
  echo "/var/lib/gdn"
}

unprivileged_root_mapping() {
  echo -n "0:4294967294:1"
}

unprivileged_range_mapping() {
  echo -n "1:1:4294967293"
}

volume_size() {
  echo 6000000000
}

create_volume_file() {
  local volume_file=$1

  # Do no recreate the volume file if it already exists
  if [ ! -f "$volume_file" ]
  then
    echo "creating volume..."
    truncate -s $(volume_size) $volume_file
  fi
}

create_store() {
  local store_path=$1
  local volume_file=$2
  local config_path=$3

  echo "Creating ${store_path} store"

  mkdir -p "$store_path"

  create_volume_file $volume_file
  format_volume_file $volume_file

  mount_btrfs_volume $volume_file $store_path
  enable_btrfs_quotas $store_path
}

init_privileged_store() {
  local config_path=$1
  grootfs --config ${config_path} init-store
}

init_unprivileged_store() {
  local config_path=$1
  grootfs --config ${config_path} init-store \
    --uid-mapping "$(unprivileged_root_mapping)" \
    --uid-mapping "$(unprivileged_range_mapping)" \
    --gid-mapping "$(unprivileged_root_mapping)" \
    --gid-mapping "$(unprivileged_range_mapping)"
}

drax_setup() {
  echo "setting up drax..."
  chmod u+s /usr/bin/drax
}

format_volume_file() {
  local volume_file=$1
  if [ -z "$(file $volume_file | grep -i "BTRFS Filesystem")" ]
  then
    echo "formatting btrfs volume..."
    mkfs.btrfs -f $volume_file
  fi
}

mount_btrfs_volume() {
  local volume_file=$1
  local store_path=$2

  echo "mounting the btrfs volume..."
  mount -o remount,user_subvol_rm_allowed $volume_file $store_path || mount -o user_subvol_rm_allowed $volume_file $store_path
}

enable_btrfs_quotas() {
  local store_path=$1
  btrfs quota enable $store_path
}

grootfs_setup() {
  local privileged_store_path=$(store_mountpoint)/grootfs/store/privileged
  local privileged_volume_file=$(store_mountpoint)/grootfs/store/privileged.backing-store
  local privileged_config=/etc/grootfs.yml
  local unprivileged_store_path=$(store_mountpoint)/grootfs/store/unprivileged
  local unprivileged_volume_file=$(store_mountpoint)/grootfs/store/unprivileged.backing-store
  local unprivileged_config=/etc/grootfs-unprivileged.yml

  create_store $privileged_store_path $privileged_volume_file $privileged_config
  init_privileged_store $privileged_config

  create_store $unprivileged_store_path $unprivileged_volume_file $unprivileged_config
  init_unprivileged_store $unprivileged_config

  drax_setup
}

main() {
  echo "nameserver 8.8.8.8" > /etc/resolv.conf
 
  # check for /proc/sys being mounted readonly, as systemd does
  if ! grep -qs '/sys' /proc/mounts; then
    mount -t sysfs sysfs /sys
  fi

  local mtu=$(cat /sys/class/net/$(ip route get 8.8.8.8|awk '{ print $5 }')/mtu)
  local tmpdir=$(mktemp -d)

  local depot_path=/var/lib/gdn/depot

  mkdir -p $depot_path

  export TMPDIR=$tmpdir
  export TEMP=$tmpdir
  export TMP=$tmpdir

  # GARDEN_GRAPH_PATH is the root of the docker image filesystem
  export GARDEN_GRAPH_PATH=/var/lib/gdn/graph
  rm -rf "${GARDEN_GRAPH_PATH}"
  mkdir -p "${GARDEN_GRAPH_PATH}"

  mkdir -p "$(store_mountpoint)/grootfs/store"

  # permit_device_control
  create_loop_devices 256

  grootfs_setup

  /usr/bin/gdn server \
    --allow-host-access \
    --depot $depot_path \
    --mtu $mtu \
    --graph=$GARDEN_GRAPH_PATH \
    --bind-ip 0.0.0.0 --bind-port 7777 \
    --graph-cleanup-threshold-in-megabytes=1024 \
    --iptables-bin=/usr/bin/iptables \
    --image-plugin=/usr/bin/grootfs \
    --image-plugin-extra-arg=--config \
    --image-plugin-extra-arg=/etc/grootfs-unprivileged.yml \
    --privileged-image-plugin=/usr/bin/grootfs \
    --privileged-image-plugin-extra-arg=--config \
    --privileged-image-plugin-extra-arg=/etc/grootfs.yml &

  vpnkit-expose-port -i \
    -host-ip      127.0.0.1 -host-port      7777 \
    -container-ip 127.0.0.1 -container-port 7777 \
    -no-local-ip
}

main $@

