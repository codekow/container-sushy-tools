#!/bin/bash

[ "${LOG_LEVEL}" = "debug" ] && set -x

SUSHY_DIR=${SUSHY_DIR:-/tmp}
SUSHY_EMULATOR_CONFIG=${SUSHY_EMULATOR_CONFIG:-${SUSHY_DIR}/sushy-emulator.conf}
SUSHY_EMULATOR_AUTH_FILE=${SUSHY_EMULATOR_AUTH_FILE:-${SUSHY_DIR}/auth.conf}
SUSHY_EMULATOR_LIBVIRT_URI=${SUSHY_EMULATOR_LIBVIRT_URI:-qemu:///system}

GUNICORN_HOST=${GUNICORN_HOST:-0.0.0.0}
GUNICORN_PORT=${GUNICORN_PORT:-8000}
GUNICORN_WORKER_COUNT=${GUNICORN_WORKER_COUNT:-2}

SERVER_CERT=${SERVER_CERT:-${SUSHY_DIR}/server.crt}
SERVER_KEY=${SERVER_KEY:-${SUSHY_DIR}/server.key}

LOG_LEVEL=${LOG_LEVEL:-info}

setup_sushy_config(){

cat >> "${SUSHY_EMULATOR_CONFIG}" <<CONFIG
# https://github.com/Gowrisankar2001/redfish_emulator/blob/main/example-sushy.conf

# SUSHY_EMULATOR_SSL_CERT = u'/etc/sushy/sushy.crt'
# SUSHY_EMULATOR_SSL_KEY = u'/etc/sushy/sushy.key'
# SUSHY_EMULATOR_LISTEN_IP = u'0.0.0.0'
# SUSHY_EMULATOR_LISTEN_PORT = 8000
# SUSHY_EMULATOR_BOOT_LOADER_MAP = {
#     u'UEFI': {
#         u'x86_64': u'/usr/share/OVMF/OVMF_CODE.secboot.fd'
#     },
#     u'Legacy': {
#         u'x86_64': None
#     }
# }

SUSHY_EMULATOR_LIBVIRT_URI = u'${SUSHY_EMULATOR_LIBVIRT_URI}'
# SUSHY_EMULATOR_AUTH_FILE = '${SUSHY_EMULATOR_AUTH_FILE}'
CONFIG

[ -e "${SUSHY_EMULATOR_AUTH_FILE}" ] && sed -i 's/# SUSHY_EMULATOR_AUTH_FILE/SUSHY_EMULATOR_AUTH_FILE/g' "${SUSHY_EMULATOR_CONFIG}"
}

setup_sushy_cert(){
  openssl req -x509 \
    -noenc -days 365 \
    -newkey rsa:2048 \
    -keyout "${SERVER_KEY}" \
    -out "${SERVER_CERT}" \
    -subj "/C=NA/ST=NA/L=NA/O=NA/OU=NA/CN=NA/emailAddress=NA" 2>/dev/null
}

setup_sushy_config
setup_sushy_cert

main(){
  CERT_ARGS=(--certfile="${SERVER_CERT}" --keyfile="${SERVER_KEY}")
  [ -e "${SERVER_CERT}" ] || unset CERT_ARGS
  [ -e "${SERVER_KEY}" ]  || unset CERT_ARGS

  /opt/vbmc/bin/gunicorn \
    -b "${GUNICORN_HOST}:${GUNICORN_PORT}" \
    --workers "${GUNICORN_WORKER_COUNT}" \
    --log-level "${LOG_LEVEL}" \
    "${CERT_ARGS[@]}" \
    "sushy_tools.emulator.main:app"
}

if [ "$#" -eq 0 ]; then
  main
else
  exec "$@"
fi
