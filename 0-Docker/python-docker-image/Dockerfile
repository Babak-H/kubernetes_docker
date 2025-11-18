# getting base image from a private repo
FROM dockerprod.artifactory.dyn.prd.aws.mycorps.net/container-base/managedbaseimages/python:3.10-stable

# ARG => Defines a build-time variable — only available during the image build process (inside the Dockerfile) => during docker build
# ENV => Defines a runtime environment variable — available inside the running container. => during docker run
ARG V_VERSION="4.8"

RUN set -eux;

ENV PG_VERSION=15
ENV PGHOME=/var/lib/pgsql
ENV PGDATA=${PGHOME}/${PG_VERSION}/data

# MicroDNF, a lightweight package manager primarily used in containerized environments, microdnf: A minimal version of dnf, designed for lightweight systems (e.g., containers)
# When working with minimal Red Hat-based images (like RHEL, CentOS Stream, or Fedora containers).
RUN microdnf install enable postgresql:${PG_VERSION} -y && microdnf install \
tar  \
gzip  \
libicu  \
perl  \
libxslt  \
jq  \
vim \
nano \
shadow-utils  \
awscli \
diffutils \
postgresql \
openssl \
bind-utils \
traceroute \
nc \
net-tools \
-y \
&& microdnf clean all

# copy pip requirements file from host machine to docker image
COPY Pipfile* .

# Install Pipenv and Install used python packages
RUN pip3 install pipenv && pipenv install --system --deploy \
    && pip3 uninstall pipenv --yes && rm -rf Pipfile*

VOLUME /var/run/postgresql

COPY ./release-artifacts/$V_VERSION/vctl /release-artifacts/vctl
COPY ./release-artifacts/$V_VERSION/release.json /release-artifacts/release.json
COPY ./release-artifacts/$V_VERSION/$V_VERSION.release /release-artifacts/$V_VERSION.release

# Install AWS root certs
COPY resources/root.crt ${PGHOME}/.postgresql/root.crt
COPY resources/kubectl /sbin/kubectl

RUN chmod +x /sbin/kubectl

COPY resources/wait.sh /

RUN chmod +x wait.sh

# chmod -R => recursive
RUN chmod -R +x /scripts

# Run all following commands (and the container process) as the user with UID 999, instead of the default root user (UID 0)
# By default, Docker containers run as the root user inside the container (UID 0)
USER 999

# USER 999
# RUN whoami => 999

EXPOSE 5432

ENTRYPOINT ["/wait.sh"]
