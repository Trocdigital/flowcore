FROM python:3.10.13-slim-bookworm as builder

USER root

# Install necessary packages
RUN apt-get update -y && apt-get install -y \
    git make automake gcc g++ python3-dev subversion libpq-dev postgresql-server-dev-all \
    zlib1g-dev libblas-dev liblapack-dev gfortran libxml2-dev libxslt1-dev python3-cffi \
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev \
    shared-mime-info libmemcached-dev zlib1g-dev build-essential libffi-dev libyaml-dev \
    sudo netcat-traditional libmagic-dev libgeos-dev pkg-config  git  libaio1 libaio-dev \
    default-libmysqlclient-dev locales locales-all make automake gcc g++ subversion libpq-dev \
    postgresql-client-common postgresql-client unixodbc unixodbc-dev libsqliteodbc \
    zlib1g-dev libblas-dev chromium-driver liblapack-dev freetds-dev freetds-bin gfortran \
    libxml2-dev libxslt1-dev python3-cffi libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
    libgdk-pixbuf2.0-0 libffi-dev shared-mime-info libmariadb-dev libmemcached-dev \
    nim rustc redis-tools

# Install locales package
RUN apt-get update && apt-get install -y locales

# Set the locale to en_US.UTF-8
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8

# Set environment variables for the locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Clean up
RUN apt-get update -y && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory to /code
WORKDIR /code

# Set Site Root Variable
ENV SITE_ROOT=/code

# Environment:
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install and upgrade pip
RUN python3 -m pip install --upgrade pip sdist setuptools wheel==0.42.0

# Copy the requirements to the working directory
COPY Makefile /code/

# Execute 'make install' to install all requirements
RUN make install
