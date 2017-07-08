#!/usr/bin/env sh

set -e

export LOG_DIR=/var/lib/gdn/log
mkdir -p $LOG_DIR

exec 1> $LOG_DIR/garden.out.log
exec 2> $LOG_DIR/garden.err.log

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

main() {
  # check for /proc/sys being mounted readonly, as systemd does
  if ! grep -qs '/sys' /proc/mounts; then
    mount -t sysfs sysfs /sys
  fi

  # shellcheck source=/dev/null
  permit_device_control
  create_loop_devices 256

  local mtu=$(cat /sys/class/net/$(ip route get 8.8.8.8|awk '{ print $5 }')/mtu)
  local tmpdir=$(mktemp -d)

  local depot_path=/var/lib/gdn/depot

  mkdir -p $depot_path

  export TMPDIR=$tmpdir
  export TEMP=$tmpdir
  export TMP=$tmpdir

  # GARDEN_GRAPH_PATH is the root of the docker image filesystem
  export GARDEN_GRAPH_PATH=/var/lib/gdn/graph
  mkdir -p "${GARDEN_GRAPH_PATH}"


    # --bind-socket /var/run/gdn.sock \

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
    --image-plugin-extra-arg=/etc/grootfs.yml \
    --privileged-image-plugin=/usr/bin/grootfs \
    --privileged-image-plugin-extra-arg=--config \
    --privileged-image-plugin-extra-arg=/etc/grootfs.yml &
}

main $@

