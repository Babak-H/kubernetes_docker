# Shared Python base image with consistent locale and runtime settings.
# Stage 1 => here just set the environment variables
FROM dockerprod.artifactory.dyn.prd.aws.mycorps.net/container-base/baseimages/python:3.10.7-stable AS base

# set environment variables
# LANG=C.UTF-8 => Sets the default locale to UTF-8 so Python and shell tools handle Unicode text correctly.
# LC_ALL=C.UTF-8 => Forces all locale categories to use UTF-8, overriding other locale settings.
# PYTHONDONTWRITEBYTECODE=1 => Prevents Python from creating .pyc cache files inside the container.
# PYTHONFAULTHANDLER=1 => Makes Python print useful traceback details for crashes like segmentation faults.
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1

# define common runtime config once, then use it in both the dependency-build stage and the final runtime stage.
# creates a reusable stage named base that contains the original Python image plus those environment settings.

# Stage 2 => install all the reuqired packages and copy needed certs
# Build a project-local virtual environment from locked Python dependencies.
FROM base AS python-deps

WORKDIR /build

# Configure pip to use the internal package index and trusted corporate CA bundle.
COPY Standard_CA_Roots.pem /usr/local/share/Standard_CA_Roots.pem

# PIP_CERT => Tells pip to trust this corporate CA certificate file when connecting to internal HTTPS package repositories
# PIPENV_VENV_IN_PROJECT=1 => Tells Pipenv to create the virtual environment inside the project directory as .venv instead of using a global cache location.
ENV PIP_CERT=/usr/local/share/Standard_CA_Roots.pem \
    PIPENV_VENV_IN_PROJECT=1

RUN set -eux; \
    pip config set global.index-url https://artifactory.prd.aws.mycorps.net/artifactory/api/pypi/pypidev/simple/; \
    pip config set global.trusted-host artifactory.prd.aws.mycorps.net; \
    pip install --no-cache-dir pipenv

# Copy dependency manifests before application code so dependency layers can be cached.
COPY Pipfile Pipfile.lock ./

# /build/.venv => Temporary virtual environment created in the python-deps build stage, Pipenv installs Python packages there because PIPENV_VENV_IN_PROJECT=1
# Exists only during the dependency build stage.
# Install only locked runtime dependencies into /build/.venv.
RUN set -eux; \
    pipenv install --deploy; \
    pip uninstall pipenv --yes; \
    rm -rf /root/.cache/pip /root/.cache/pipenv

# Stage 3 => in this stage run the executable app 
# Final runtime image: copy the virtual environment and application only.
FROM base AS runtime

# /opt/venv => Final virtual environment location in the runtime image, The Dockerfile copies /build/.venv into /opt/venv
# In short: /build/.venv is where dependencies are built; /opt/venv is where those dependencies live in the final container.
ENV PATH="/opt/venv/bin:${PATH}"

WORKDIR /opt/app/sotra

# Copy the prepared virtual environment from the dependency build stage.
COPY --from=python-deps /build/.venv /opt/venv

# Copy application source after dependencies to avoid reinstalling packages on source-only changes.
COPY . /opt/app/sotra

# Set ownership and restrictive executable/read permissions for the runtime user.
RUN set -eux; \
    chown -R 999:999 /opt/app /opt/venv; \
    chmod -R u=rwX,g=rX,o=rX /opt/app /opt/venv

# Run as a non-root user.
USER 999

ENTRYPOINT ["python3", "/opt/app/sotra/sotra.py"]



