FROM python:3.10.13-slim-bookworm as builder
RUN apt-get -y update && apt-get -y update && apt-get -y install sudo netcat-traditional  libgeos-dev pkg-config  git  libaio1 libaio-dev default-libmysqlclient-dev locales locales-all make automake gcc g++ subversion libpq-dev postgresql-client-common postgresql-client unixodbc unixodbc-dev libsqliteodbc \
    zlib1g-dev libblas-dev chromium-driver liblapack-dev freetds-dev freetds-bin gfortran libxml2-dev libxslt1-dev python3-cffi libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info libmariadb-dev libmemcached-dev nim rustc redis-tools 
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install -U pip && pip install -U wheel==0.42.0 asyncdb[all] navconfig[all] navigator-session navigator-auth navigator-api[locale] async-notify[all] aiosftp qworker querysource flowtask

