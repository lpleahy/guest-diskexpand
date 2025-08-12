#!/bin/bash

# Copyright 2020 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Checks if the OS is a RHEL 10+ variant.
is_rhel10_or_later() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    # Check for RHEL-like distributions (ID_LIKE) or specific IDs.
    # Then check if the major version number is 10 or greater.
    if [[ "${ID_LIKE}" =~ "rhel" || "${ID}" =~ ^(rhel|centos|rocky|almalinux)$ ]] &&
      [ -n "${VERSION_ID}" ] &&
      [ "${VERSION_ID%%.*}" -ge 10 ]; then
      return 0 # Success, it is RHEL 10+
    fi
  fi
  return 1 # Failure, it is not RHEL 10+
}

check() {
  command -v parted >/dev/null 2>&1
}

install() {
  inst "$moddir/expandroot-lib.sh" "/lib/expandroot-lib.sh"
  inst_hook cmdline 50 "$moddir/expand_root_dummy.sh"
  inst_hook pre-mount 50 "$moddir/expand_root.sh"

  dracut_install parted
  dracut_install cut
  dracut_install sed
  dracut_install grep
  dracut_install udevadm

  # Only install sgdisk on systems where it is required (pre-RHEL 10).
  if ! is_rhel10_or_later; then
    dracut_install sgdisk
  else
    # RHEL 10+ uses sfdisk.
    dracut_install sfdisk
  fi
}
