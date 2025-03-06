FROM dockerprod.artifactory.dyn.prd.aws.mycorps.net/container-base/baseimages/python:3.10.7-stable AS base
# Setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

FROM base AS python-deps

RUN pip config set global.index-url https://artifactory.prd.aws.mycorps.net/artifactory/api/pypi/pypidev/simple/
RUN pip config set global.trusted-host https://artifactory.prd.aws.mycorps.net/artifactory/api/pypi/pypidev/simple/

RUN pip install pipenv

COPY Pipfile .
COPY Pipfile.lock .
COPY Standard_CA_Roots.pem /usr/local/share/

ENV PIP_CERT=/usr/local/share/Standard_CA_Roots.pem
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --dev --deploy

FROM base AS runtime

# Copy virtual env from python-deps stage
COPY --from=python-deps /.venv /.venv
ENV PATH="/.venv/bin:$PATH"

RUN mkdir -p /opt/app/

COPY . /opt/app/sotra
RUN chown -R corpsnobody /opt/app/
RUN chmod -R 755 /opt/app/
USER 999
WORKDIR ./opt/app/sotra
