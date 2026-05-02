# Use the approved Python base image from the private container registry.
FROM dockerprod.artifactory.dyn.prd.aws.mycorps.net/container-base/managedbaseimages/python:3.10-stable

# Build-time release version used to select the matching release artifact files.
ARG V_VERSION="4.8"

# PostgreSQL runtime paths expected by PostgreSQL tools and the entrypoint script.
ENV PG_VERSION=15
ENV PGHOME=/var/lib/pgsql
# this is the actual address where postgres data lives
ENV PGDATA=${PGHOME}/${PG_VERSION}/data

# Enable the PostgreSQL module stream before installing the runtime tools.
# Keep package installation in one layer and clean package metadata for a smaller image.
RUN set -eux; \
    microdnf module enable "postgresql:${PG_VERSION}" -y; \
    microdnf install -y \
        awscli \
        bind-utils \
        diffutils \
        gzip \
        jq \
        libicu \
        libxslt \
        nano \
        nc \
        net-tools \
        openssl \
        perl \
        postgresql \
        shadow-utils \
        tar \
        traceroute \
        vim; \
    microdnf clean all; \
    rm -rf /var/cache/yum /var/cache/dnf

WORKDIR /app

# Copy only dependency manifests first so dependency installation can use Docker layer cache.
COPY Pipfile* ./

# Install Python dependencies into the system environment, then remove build-only tooling.
RUN set -eux; \
    pip3 install --no-cache-dir pipenv; \
    pipenv install --system --deploy; \
    pip3 uninstall pipenv --yes; \
    rm -rf Pipfile* /root/.cache/pip /root/.cache/pipenv

# tells Docker that /var/run/postgresql is runtime-managed storage, not just normal image filesystem content.
# Docker creates an anonymous volume for that directory when the container runs, Files written there at runtime are kept outside the image’s writable container layer.
# The directory can be shared with another container if you mount the same volume into both containers.
# Data in that path is not baked into the image and is not controlled by later image layers.
# Preserve the PostgreSQL socket directory as a runtime volume.
VOLUME /var/run/postgresql

# Copy release artifacts selected by V_VERSION.
COPY ./release-artifacts/$V_VERSION/vctl /release-artifacts/vctl
COPY ./release-artifacts/$V_VERSION/release.json /release-artifacts/release.json
COPY ./release-artifacts/$V_VERSION/$V_VERSION.release /release-artifacts/$V_VERSION.release

# Install PostgreSQL TLS trust material and kubectl used by runtime scripts.
COPY resources/root.crt ${PGHOME}/.postgresql/root.crt
COPY resources/kubectl /sbin/kubectl

COPY resources/wait.sh /

# Ensure runtime helper scripts are executable.
RUN set -eux; \
    chmod +x /sbin/kubectl /wait.sh; \
    chmod -R +x /scripts

# Run the container as the non-root PostgreSQL user provided by the base image.
USER 999

EXPOSE 5432

ENTRYPOINT ["/wait.sh"]
