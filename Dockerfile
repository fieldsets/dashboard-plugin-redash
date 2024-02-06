FROM node:16-bullseye-slim as frontend-builder

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    git-core && \
  apt-get clean


RUN npm install --global --force yarn@1.22.19

# Controls whether to build the frontend assets
ARG skip_frontend_build

ENV CYPRESS_INSTALL_BINARY=0
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1

RUN useradd -m -d /frontend redash
USER redash

WORKDIR /frontend
COPY --chown=redash ./src/redash/package.json ./src/redash/yarn.lock ./src/redash/.yarnrc /frontend/
COPY --chown=redash ./src/redash/viz-lib /frontend/viz-lib

# Controls whether to instrument code for coverage information
ARG code_coverage
ENV BABEL_ENV=${code_coverage:+test}


RUN if [ "x$skip_frontend_build" = "x" ] ; then yarn --frozen-lockfile --network-concurrency 1; fi
#RUN if [ "x$skip_frontend_build" = "x" ] ; then yarn --network-concurrency 1; fi

COPY --chown=redash ./src/redash/client /frontend/client
COPY --chown=redash ./src/redash/webpack.config.js /frontend/
RUN if [ "x$skip_frontend_build" = "x" ] ; then yarn build; else mkdir -p /frontend/client/dist && touch /frontend/client/dist/multi_org.html && touch /frontend/client/dist/index.html; fi

FROM python:3.8-slim-bullseye

EXPOSE 5000

# Controls whether to install extra dependencies needed for all data sources.
ARG skip_ds_deps
# Controls whether to install dev dependencies.
ARG skip_dev_deps

RUN useradd --create-home redash

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    pkg-config \
    curl \
    gnupg \
    build-essential \
    pwgen \
    libffi-dev \
    sudo \
    git-core \
    # Kerberos, needed for MS SQL Python driver to compile on arm64
    libkrb5-dev \
    # Postgres client
    libpq-dev \
    postgresql-client \
    # ODBC support:
    unixodbc \
    g++ \
    unixodbc-dev \
    # for SAML
    xmlsec1 \
    cmake \
    # Additional packages required for data sources:
    libssl-dev \
    default-libmysqlclient-dev \
    freetds-dev \
    libsasl2-dev \
    unzip \
    libedit-dev \
    libsasl2-modules-gssapi-mit && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ARG TARGETPLATFORM
ARG databricks_odbc_driver_url=https://databricks-bi-artifacts.s3.us-east-2.amazonaws.com/simbaspark-drivers/odbc/2.6.26/SimbaSparkODBC-2.6.26.1045-Debian-64bit.zip
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install  -y --no-install-recommends msodbcsql17 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl "$databricks_odbc_driver_url" --location --output /tmp/simba_odbc.zip \
    && chmod 600 /tmp/simba_odbc.zip \
    && unzip /tmp/simba_odbc.zip -d /tmp/simba \
    && dpkg -i /tmp/simba*/*.deb \
    && printf "[Simba]\nDriver = /opt/simba/spark/lib/64/libsparkodbc_sb64.so" >> /etc/odbcinst.ini \
    && rm /tmp/simba_odbc.zip \
    && rm -rf /tmp/simba; fi

WORKDIR /app

ENV POETRY_VERSION=1.6.1
ENV POETRY_HOME=/etc/poetry
ENV POETRY_VIRTUALENVS_CREATE=false
RUN curl -sSL https://install.python-poetry.org | python3 -

COPY ./src/redash/pyproject.toml ./src/redash/poetry.lock ./

ARG POETRY_OPTIONS="--no-root --no-interaction --no-ansi"
# for LDAP authentication, install with `ldap3` group
# disabled by default due to GPL license conflict
ARG install_groups="main,all_ds,dev,ldap3"
RUN /etc/poetry/bin/poetry install --only $install_groups $POETRY_OPTIONS

COPY --chown=redash ./src/redash/ /app/
COPY --chown=redash ./entrypoint.sh /docker-entrypoint.sh
COPY --chown=redash ./init/ /docker-entrypoint-init.d/

COPY --from=frontend-builder --chown=redash /frontend/client/dist /app/client/dist
RUN mkdir /data/
RUN chown redash /data
RUN chown redash /app
RUN chown redash /etc/environment
USER redash

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["server"]