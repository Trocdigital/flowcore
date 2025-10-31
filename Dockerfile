FROM python:3.11-slim-bookworm AS builder

USER root

# Add NVIDIA CUDA repository for cuDNN (only in builder stage)
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
    postgresql-client unixodbc unixodbc-dev libsqliteodbc chromium-driver \
    freetds-dev freetds-bin nim rustc redis-tools vim-tiny exempi libexempi-dev \
    ffmpeg libavutil-dev libavformat-dev libavcodec-dev libcudnn8 libcudnn8-dev

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

# Copy pyproject.toml for Docker layer caching
COPY pyproject.toml Makefile ./

# Install UV using pip and add to PATH
RUN pip install uv
RUN make install-uv
ENV PATH="/home/troc/.local/bin:$PATH"
RUN make venv

# Install dependencies including production extras (gunicorn, uvicorn)
RUN make install

ENV PATH="/code/.venv/bin:/home/troc/.local/bin:$PATH"

# Let's ensure gunicorn is installed
RUN /code/.venv/bin/gunicorn --version

# Copy application source code
COPY --chown=troc:troc . .

# ============================================
# Runtime Stage (lightweight final image)
# ============================================
# This multi-stage build optimizes the final image size by:
# 1. Builder stage: Installs NVIDIA CUDA repos, cuDNN dev libraries, and all build tools
#    needed to compile Python dependencies (gcc, g++, development headers, etc.)
# 2. Runtime stage: Creates a clean image with only runtime libraries (libcudnn8 without -dev)
#    and copies the built artifacts from the builder stage
# Result: Final image contains cuDNN support without heavy compilation tools,
#         significantly reducing image size while maintaining GPU acceleration capabilities
FROM python:3.11-slim-bookworm AS runtime

USER root

# Add NVIDIA CUDA repository for runtime cuDNN libraries only
RUN apt-get update -y && apt-get install -y wget gnupg2 ca-certificates && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb && \
    apt-get update -y

# Install only runtime dependencies (no -dev packages, no build tools)
RUN apt-get install -y \
    libpq5 postgresql-client \
    libxml2 libxslt1.1 \
    libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi8 \
    libmemcached11 libyaml-0-2 \
    netcat-traditional libmagic1 libgeos-c1v5 libaio1 \
    libmariadb3 locales locales-all \
    unixodbc libsqliteodbc \
    freetds-bin redis-tools vim-tiny libexempi8 \
    ffmpeg libcudnn8 \
    sudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Locales setup
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    for lang in en_US.UTF-8 es_ES.UTF-8 zh_CN.UTF-8 zh_TW.UTF-8 fr.UTF-8 de.UTF-8 tr.UTF-8 ja.UTF-8 ko.UTF-8 pt_BR.UTF-8 pt_PT.UTF-8; do locale-gen $lang; done && \
    update-locale

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

# Create user 'troc'
RUN useradd --create-home --user-group troc && \
    mkdir -p /home/troc/.ssh && \
    chmod -R 770 /home/troc && \
    chown -R troc:troc /home/troc && \
    adduser troc sudo && \
    echo "troc ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup directories
RUN mkdir -p /code /home/ubuntu/symbits /var/log/troc/ && \
    chown troc:troc /code /home/ubuntu/symbits /var/log/troc/

# Copy from builder stage
COPY --from=builder --chown=troc:troc /code /code
COPY --from=builder --chown=troc:troc /home/troc/.local /home/troc/.local

USER troc
WORKDIR /code

ENV SITE_ROOT=/code
ENV PATH="/code/.venv/bin:/home/troc/.local/bin:$PATH"

# Expose port (adjust if necessary)
EXPOSE 5000
