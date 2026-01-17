ARG BASE_IMAGE=docker.io/library/fedora:latest

FROM ${BASE_IMAGE}

ARG SUSHY_TOOLS_VERSION="2.2.0"

RUN dnf upgrade -y && \
    dnf install -y python3 python3-pip openssh-clients openssl \
      python3-devel libvirt-devel libvirt-client gcc && \
    python3 -m venv /opt/vbmc && \
    /opt/vbmc/bin/pip install --no-cache-dir \
      -U pip gunicorn sushy-tools==${SUSHY_TOOLS_VERSION} && \
    dnf remove -y python3-devel libvirt-devel libvirt-client gcc && \
    dnf clean all && \
    rm -rf /var/cache/yum /var/cache/dnf

RUN mkdir -p /sushy-tools/.ssh && touch /sushy-tools/.ssh/config && \
    echo "IdentityFile /sushy-tools/.ssh/id_rsa" >> /sushy-tools/.ssh/config && \
    echo "PubKeyAuthentication yes" >> /sushy-tools/.ssh/config && \
    echo "StrictHostKeyChecking no" >> /sushy-tools/.ssh/config

COPY entrypoint.sh /

USER 1001

ENTRYPOINT ["/entrypoint.sh"]
