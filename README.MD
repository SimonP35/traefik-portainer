# Traefik & Portainer Docker Stack

This project sets up a local development environment featuring:
*   **Traefik**:
    *   Manages traffic routing based on `*.docker.localhost` domain names.
    *   Handles SSL termination for HTTPS using self-signed certificates.
    *   Accessible at: `https://traefik.docker.localhost/`
*   **Portainer**:
    *   Provides a UI to manage Docker containers (start, stop, logs, exec, etc.).
    *   Accessible at: `https://portainer.docker.localhost/`

## Prerequisites

*   **Docker** and **Docker Compose** must be installed.
*   **Make**: This project uses `make` commands. To install `make` on Debian/Ubuntu:
    ```shell
    sudo apt-get update && sudo apt-get install make
    ```

## Setup & Installation

1.  **Environment Variables**:
    If the `.env` file does not exist, it will be automatically created from `.env.dist` when you run `make install` or `make check-env`. You can customize Traefik and Portainer versions in the `.env` file if needed.

2.  **Install the Stack**:
    This command will:
    *   Ensure the `.env` file exists.
    *   Generate self-signed SSL certificates if they don't exist in `./traefik-data/certs/`.
    *   Start the Traefik and Portainer containers.
    ```shell
    make install
    ```

## Trusting the Self-Signed CA Certificate

For your browser to trust the `*.docker.localhost` SSL certificates served by Traefik, you need to import the local Certificate Authority (CA) certificate into your browser's (or system's) trust store.

1.  **Locate the CA certificate**: After running `make install` (or `make generate-certs`), the CA certificate will be available at:
    `./self-signed-ssl/docker-localhost/CA.pem`
    *(The script `self-signed-ssl/self-signed-ssl` generates this CA. The `CA.key` is its private key and should be kept secure. The `CA.pem` is the public certificate of your local CA).*

2.  **Import into your Browser**:
    The steps vary by browser. For **Google Chrome/Chromium**:
    *   Go to Settings -> Privacy and security -> Security.
    *   Scroll down to "Manage certificates".
    *   Go to the "Authorities" tab.
    *   Click "Import...".
    *   Select the `CA.pem` file (you might need to change the file type filter to "All Files" or "PEM certificates").
    *   Check "Trust this certificate for identifying websites."
    *   Click "OK".
    *   Restart your browser completely.

    You should now be able to access `https://traefik.docker.localhost/` and `https://portainer.docker.localhost/` without SSL warnings.

## Available `make` Commands

*   `make help`: Displays all available commands.
*   `make install`: Ensures `.env` exists, generates SSL certificates if needed, and starts the stack.
*   `make start`: Starts the Traefik/Portainer stack (ensures certificates are generated first).
*   `make down`: Stops and removes the containers and default networks.
*   `make check-env`: Creates `.env` from `.env.dist` if it doesn't exist.
*   `make generate-certs`: Generates SSL certificates if they are missing from `./traefik-data/certs/`.
*   `make clean-certs`: Removes generated SSL certificates from `./traefik-data/certs/` and the `./self-signed-ssl/docker-localhost/` output directory.
*   `make clean`: Stops and removes containers, networks, and images (preserves Docker volumes).
*   `make clean-all`: **DESTRUCTIVE**. Stops and removes ALL Docker resources: containers, networks, images, AND **VOLUMES**. **Asks for confirmation before deleting volumes.**
*   `make full-clean`: Runs `clean-all` (with confirmation) and then `clean-certs`.

## Docker Network

A Docker user-defined network named `traefik_proxy_network` (as defined in `docker-compose.yml`) is automatically created when you start the stack. Your other local development projects should connect to this network to be discoverable by Traefik.

## SSL Certificate Details

The self-signed certificates are generated for `*.docker.localhost` and are valid for 10 years by default (configurable in the `self-signed-ssl/self-signed-ssl` script).
The generation process creates several files in `./self-signed-ssl/docker-localhost/`:
*   `CA.key`: Private key for your local CA (Keep Secure!).
*   `CA.pem`: Public certificate for your local CA (Import this into browsers).
*   `CA.srl`: Serial number file for the CA.
*   `docker.localhost.crt`: Server certificate for `*.docker.localhost`.
*   `docker.localhost.csr`: Certificate Signing Request (intermediate file).
*   `docker.localhost.key`: Server private key for `*.docker.localhost`.

Only `docker.localhost.crt` and `docker.localhost.key` are copied to `./traefik-data/certs/` for Traefik to use.
