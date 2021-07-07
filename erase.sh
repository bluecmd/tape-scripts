#!/bin/bash

sn=()
sn+=( P0016SL4 )

set -euo pipefail

CHR="/dev/sg3"
DRV="/dev/nst1"

slots=()
IFS='
'
for line in $(mtx -f /dev/sg3 status)
do
  if [[ "${line}" == *" Storage Element"* ]] && \
    [[ "${line}" == *"VolumeTag"* ]]; then
    slot="$(echo "${line}" | awk '{split($3,a,":"); print a[1]}')"
    tag="$(echo "${line}" | awk '{split($4,a,"="); print a[2]}')"
    for s in ${sn[@]}
    do
      if [[ "${tag}" == "${s}" ]]; then
        echo "Registered ${tag} in slot ${slot}"
        slots+=( ${slot} )
        break
      fi
    done
  fi
done

pi=-1
for i in ${slots[@]}
do
  if [[ "${pi}" != "-1" ]]; then
    echo "=> Unloading tape $pi"
    mtx -f "${CHR}" unload $pi 1
  fi
  pi="${i}"
  echo "=> Loading tape $i"
  mtx -f "${CHR}" load $i 1
  mam-info -f "${DRV}" &>/dev/null || true
  sleep 1

  ok=0
  csn="$(mam-info -f "${DRV}" | awk '/Barcode:/ {print $2}')"
  if [[ -z "${csn}" ]]; then
    echo "Failed to read barcode, skipping"
    continue
  fi
  for s in ${sn[@]}
  do
    if [[ "${s}" == "${csn}" ]]; then
      ok=1
      break
    fi
  done

  if [[ "${ok}" == "0" ]]; then
    echo "=> Barcode ${csn} not found in erase list, skipping"
    continue
  fi
  echo "=> Barcode ${csn} found in erase list, erasing"
  echo "Waiting 3 seconds for user abort"
  sleep 3
  mt -f "${DRV}" weof
done
