#!/bin/bash

sn=()
sn+=( P0046SL4 )
sn+=( P0032SL4 )
sn+=( P0042SL4 )
sn+=( P0026SL4 )
sn+=( P0048SL4 )
sn+=( P0017SL4 )
sn+=( P0024SL4 )
sn+=( P0021SL4 )
sn+=( P0019SL4 )
sn+=( P0009SL4 )
sn+=( P0010SL4 )
sn+=( AAE714L4 )
sn+=( AAE713L4 )
sn+=( AAE712L4 )
sn+=( P0035SL4 )
sn+=( P0002SL4 )
sn+=( P0004SL4 )
sn+=( P0037SL4 )
sn+=( P0018SL4 )
sn+=( P0020SL4 )
sn+=( P0039SL4 )
sn+=( P0033SL4 )
sn+=( P0040SL4 )
sn+=( P0041SL4 )

set -euo pipefail

CHR="/dev/sg2"
DRV="/dev/nst1"

pi=-1
for i in 16 17 18 19 40 41 42 43 44
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
