FROM python:3.12-slim-bookworm

USER root

# Add NVIDIA CUDA repository for cuDNN
RUN apt-get update -y && apt-get install -y wget gnupg2 ca-certificates && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb && \
    apt-get update -y

# System dependencies (toolchains and C libraries)
RUN apt-get install -y \
    git make automake gcc g++ python3-dev subversion libpq-dev postgresql-server-dev-all \
    zlib1g-dev libblas-dev liblapack-dev gfortran libxml2-dev libxslt1-dev python3-cffi \
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev \
    shared-mime-info libmemcached-dev libyaml-dev \
    sudo netcat-traditional libmagic-dev libgeos-dev pkg-config libaio1 libaio-dev \
    default-libmysqlclient-dev locales locales-all postgresql-client-common \
    postgresql-client unixodbc unixodbc-dev libsqliteodbc chromium unzip \
    freetds-dev freetds-bin nim rustc redis-tools vim-tiny exempi libexempi-dev \
    ffmpeg libavutil-dev libavformat-dev libavcodec-dev libheif-dev libde265-dev \
    libcudnn8 libcudnn8-dev curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# eMudhra / emSign CA incident (disclosed 2026-10-17): the private keys of eight
# eMudhra intermediates are recoverable from their certificates. They chain to
# "emSign ECC Root CA - G3" and to "AAA Certificate Services" (Comodo/Sectigo
# cross-sign). Browsers and certifi already distrust them, but the Debian system
# store (used by OpenSSL -> aiohttp, curl, psql, git) only does so from
# ca-certificates 20250419~deb12u2 (bookworm-security, 2026-10-20). Pull that
# upgrade explicitly and, as defence in depth against a stale mirror, blocklist
# both roots ("!" prefix in /etc/ca-certificates.conf). The sed lines are no-ops
# once deb12u2 is installed and can be dropped later.
# Ref: https://emudhra.we-have-a-problem.com/
RUN apt-get update -y && apt-get install -y --only-upgrade ca-certificates && \
    sed -i -e 's#^mozilla/emSign_ECC_Root_CA_-_G3.crt#!&#' \
           -e 's#^mozilla/Comodo_AAA_Services_root.crt#!&#' /etc/ca-certificates.conf && \
    update-ca-certificates --fresh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ChromeDriver matching the installed Chromium version
RUN VER=$(curl -sf "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$(chromium --version | grep -oP '\d+' | head -1)") \
    && curl -sfL "https://storage.googleapis.com/chrome-for-testing-public/${VER}/linux64/chromedriver-linux64.zip" -o /tmp/cd.zip \
    && unzip -p /tmp/cd.zip chromedriver-linux64/chromedriver > /usr/bin/chromedriver \
    && chmod +x /usr/bin/chromedriver && rm /tmp/cd.zip

# Tell Selenium Manager (Selenium 4.6+) to use the system chromedriver,
# bypassing webdriver-manager's stale cache of v114 from the pre-CfT era.
ENV SE_CHROMEDRIVER=/usr/bin/chromedriver

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

# Copy pyproject.toml for Docker layer caching
COPY pyproject.toml Makefile ./

# Install UV using pip (no-cache so pip doesn't bloat the layer).
# pip >= 26.2.2 and uv >= 0.13.4 ship CA bundles without the compromised emSign
# roots (both carry their own trust store and ignore the system one).
RUN pip install --no-cache-dir --upgrade "pip>=26.2.2" "uv>=0.13.4"
ENV PATH="/home/troc/.local/bin:$PATH"

# Create venv, install deps, and wipe uv cache — all in one layer so the
# download cache is never committed to an image layer.
RUN make venv && make install && uv cache clean

ENV PATH="/code/.venv/bin:/home/troc/.local/bin:$PATH"

# Let's ensure gunicorn is installed
RUN /code/.venv/bin/gunicorn --version

# Copy application source code
COPY --chown=troc:troc . .

# Expose port (adjust if necessary)
EXPOSE 5000
