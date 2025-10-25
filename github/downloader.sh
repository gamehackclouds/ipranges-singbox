#!/usr/bin/env bash

set -euo pipefail
set -x

export HOME_GITHUB=$(pwd)
export NAME_SERVICE=github

download_ip() {
    curl --max-time 30 --retry-delay 3 --retry 10 -4s -# \
        https://raw.githubusercontent.com/lord-alfred/ipranges/main/"$1"/ipv4_merged.txt
}

download_ip "${NAME_SERVICE}" > "${HOME_GITHUB}/${NAME_SERVICE}/ipv4.txt"

if [[ -f "${HOME_GITHUB}/${NAME_SERVICE}/ipv4.txt" ]]; then
    jq -n \
        --slurpfile ip_cidr_data <(jq -R . "${HOME_GITHUB}/${NAME_SERVICE}/ipv4.txt") '
{
  version: 1,
  rules: [
    {
      ip_cidr: $ip_cidr_data
    }
  ]
    }' > "${HOME_GITHUB}/${NAME_SERVICE}/${NAME_SERVICE}.json"
else
    echo "❗ IPv4 file not found!"
    exit 1
fi

sing-box rule-set compile "${HOME_GITHUB}/${NAME_SERVICE}/${NAME_SERVICE}.json"

rm -f "${HOME_GITHUB}/${NAME_SERVICE}"/*.{zst,zip}

zstd -q -o "${HOME_GITHUB}/${NAME_SERVICE}/${NAME_SERVICE}.json.zst" \
    "${HOME_GITHUB}/${NAME_SERVICE}/${NAME_SERVICE}.json"
rm -f "${HOME_GITHUB}/${NAME_SERVICE}/${NAME_SERVICE}.json" \
      "${HOME_GITHUB}/${NAME_SERVICE}/ipv4.txt"

cd "${HOME_GITHUB}/${NAME_SERVICE}/"
zip -9 "${NAME_SERVICE}.zip" "${NAME_SERVICE}.srs"