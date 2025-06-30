# FlowCore - Base Image for Navigator Applications

## General Description

FlowCore is a base Docker image specifically designed to build and run applications in the Navigator ecosystem. This image provides a complete and optimized environment for the development and deployment of applications such as:

- **navigator-api**: Main API of the Navigator system
- **dataintegrator**: Scheduler for data integration
- **dataintegrator-worker**: Workers for data processing

## Main Features

### 🐍 Python Environment
- **Version**: Python 3.11.9
- **Base**: Debian Bookworm (slim)
- **Package Management**: Updated pip with setuptools and sdist

### 🌍 Multi-language Support
The image includes complete support for multiple languages:
- English (en_US.UTF-8)
- Spanish (es_ES.UTF-8)
- Simplified Chinese (zh_CN.UTF-8)
- Traditional Chinese (zh_TW.UTF-8)
- French (fr.UTF-8)
- German (de.UTF-8)
- Turkish (tr.UTF-8)
- Japanese (ja.UTF-8)
- Korean (ko.UTF-8)

### 🛠️ Development Tools
- **Compilers**: gcc, g++, make, automake
- **Languages**: Python, Nim, Rust
- **Databases**: PostgreSQL, MySQL, SQLite, FreeTDS
- **Tools**: git, vim-tiny, redis-tools, chromium-driver

### 📚 System Libraries
- **Mathematics**: BLAS, LAPACK, gfortran
- **Graphics**: Cairo, Pango, GDK-Pixbuf
- **Development**: libffi, libxml2, libxslt, libyaml
- **Geography**: libgeos
- **Others**: libmemcached, libmagic, exempi

## Container Structure

### User and Permissions
- **User**: `troc` (non-root)
- **Group**: `troc`
- **Permissions**: Sudo without password
- **Working directory**: `/code`

### Environment Variables
```bash
SITE_ROOT=/code
PATH=/code/venv/bin:/home/troc/.local/bin:$PATH
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
```

### Main Directories
- `/code`: Main application directory
- `/home/troc/.ssh`: User SSH keys
- `/home/ubuntu/symbits`: Symbols directory
- `/var/log/troc/`: Application logs

## Installed Dependencies

### Navigator Core Packages
```bash
# Core packages
python-datamodel
asyncdb[default]
navconfig[default]
async-notify[all]
navigator-api[locale,uvloop]

# Navigation components
navigator-session
navigator-auth
querysource
gunicorn
```

### Package Features
- **python-datamodel**: Data modeling
- **asyncdb**: Asynchronous database
- **navconfig**: System configuration
- **async-notify**: Notification system
- **navigator-api**: Main API with multi-language support
- **navigator-session**: Session management
- **navigator-auth**: Authentication
- **querysource**: Query sources
- **gunicorn**: WSGI server

## Image Usage

### Building
```bash
docker build -t flowcore .
```

### Running
```bash
docker run -p 5000:5000 flowcore
```

### Development
```bash
# Mount local code
docker run -v $(pwd):/code -p 5000:5000 flowcore

# Interactive access
docker run -it flowcore bash
```

## Network Configuration

- **Exposed port**: 5000
- **Protocol**: HTTP/HTTPS
- **Server**: Gunicorn (WSGI)

## Use Cases

### 1. Navigator API
```dockerfile
FROM flowcore
COPY . /code/
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

### 2. DataIntegrator Scheduler
```dockerfile
FROM flowcore
COPY . /code/
CMD ["python", "scheduler.py"]
```

### 3. DataIntegrator Worker
```dockerfile
FROM flowcore
COPY . /code/
CMD ["python", "worker.py"]
```

## Security Optimizations

- Non-root user (`troc`)
- Minimum necessary permissions
- Package cache cleanup
- Isolated environment

## Maintenance

### Dependency Updates
```bash
# Update system packages
apt-get update && apt-get upgrade

# Update Python packages
pip install --upgrade -r requirements.txt
```

### Cleanup
```bash
# Clean apt cache
apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean pip cache
pip cache purge
```

## Troubleshooting

### Common Issues

1. **Locale errors**: Verify that locales are generated
2. **Permissions**: Ensure user `troc` has adequate permissions
3. **Port occupied**: Verify that port 5000 is available
4. **Missing dependencies**: Run `make install` to reinstall

### Logs
Logs are stored in `/var/log/troc/` and can be accessed by user `troc`.

## Contributing

To contribute to this base image:

1. Modify the `Dockerfile` according to needs
2. Update the `Makefile` with new dependencies
3. Test the image with target applications
4. Document changes in this file

---

**Version**: 1.0  
**Last updated**: 2024  
**Maintainer**: Navigator Team
