FROM python:3.11-slim-bookworm AS builder

USER root

# System dependencies (toolchains and C libraries)
RUN apt-get update -y && apt-get install -y \
    git make automake gcc g++ python3-dev subversion libpq-dev postgresql-server-dev-all \
    zlib1g-dev libblas-dev liblapack-dev gfortran libxml2-dev libxslt1-dev python3-cffi \
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev \
    shared-mime-info libmemcached-dev libyaml-dev \
    sudo netcat-traditional libmagic-dev libgeos-dev pkg-config libaio1 libaio-dev \
    default-libmysqlclient-dev locales locales-all postgresql-client-common \
    postgresql-client unixodbc unixodbc-dev libsqliteodbc chromium-driver \
    freetds-dev freetds-bin nim rustc redis-tools vim-tiny exempi libexempi-dev

# Locales setup
# Set the locale to en_US.UTF-8 and other languages
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
RUN for lang in en_US.UTF-8 es_ES.UTF-8 zh_CN.UTF-8 zh_TW.UTF-8 fr.UTF-8 de.UTF-8 tr.UTF-8 ja.UTF-8 ko.UTF-8 pt_BR.UTF-8 pt_PT.UTF-8; do locale-gen $lang; done
RUN update-locale

# Set environment variables for the locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV LANG_ZH_CN=zh_CN.UTF-8
ENV LANG_ZH_TW=zh_TW.UTF-8
ENV LANG_KO=ko.UTF-8
ENV LANG_JA=ja.UTF-8
ENV LANG_TR=tr.UTF-8
ENV LANG_ES=es_ES.UTF-8
ENV LANG_DE=de.UTF-8
ENV LANG_FR=fr.UTF-8
ENV LANG_PT_BR=pt_BR.UTF-8
ENV LANG_PT_PT=pt_PT.UTF-8

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a user 'troc', create necessary directories and set permissions
RUN useradd --create-home --user-group troc
RUN mkdir -p /home/troc/.ssh
RUN chmod -R 770 /home/troc
RUN chown -R troc:troc /home/troc

# Add troc user to sudo
RUN adduser troc sudo
RUN echo "troc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set the working directory to /code
RUN mkdir -p /code
COPY Makefile /code/
RUN chown -R troc:troc /code
RUN mkdir -p /home/ubuntu/symbits /var/log/troc/
RUN chown troc:troc /code /home/ubuntu/symbits /var/log/troc/

# Change user and set working directory
USER troc
WORKDIR /code

# Set Site Root Variable
ENV SITE_ROOT=/code

# Copy pyproject.toml and uv.lock for Docker layer caching
COPY pyproject.toml uv.lock Makefile ./

# Install UV using pip and add to PATH
RUN make install-uv
ENV PATH="/home/troc/.local/bin:$PATH"

# Install dependencies including production extras (gunicorn, uvicorn)
RUN make install

# Copy application source code
COPY --chown=troc:troc . .

# Expose port (adjust if necessary)
EXPOSE 5000
