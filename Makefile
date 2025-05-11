# Misc
DOCKER_COMP = docker compose
PROJECT_NAME = traefik-portainer-stack # Define a project name
CERT_DIR = ./traefik-data/certs
CERT_OUTPUT_DIR = ./self-signed-ssl/docker-localhost
CERT_KEY = $(CERT_DIR)/docker.localhost.key
CERT_CRT = $(CERT_DIR)/docker.localhost.crt
ENV_FILE = ./.env
ENV_DIST_FILE = ./.env.dist

.DEFAULT_GOAL = help
.PHONY        = help start down install generate-certs clean-certs check-env clean clean-all full-clean

## —— ✨🍥 Konoha's Forest Docker Stack! 🍥✨ ——————————————

##
## Installation & Setup
## ----------------------
install: check-env generate-certs start ## Install the stack: ensure .env, generate certs if missing, and start containers
	@echo "Stack installed and started."

check-env: ## Check if .env file exists and create it from .env.dist if not
ifeq (,$(wildcard $(ENV_FILE)))
	@echo "Creating .env file from $(ENV_DIST_FILE)..."
	@cp $(ENV_DIST_FILE) $(ENV_FILE)
else
	@echo ".env file already exists."
endif

##
## Certificate Management
## ------------------------
generate-certs: ## Generate SSL certificates if they don't exist
ifeq ($(strip $(wildcard $(CERT_KEY))$(wildcard $(CERT_CRT))),)
	@echo "Generating SSL certificates..."
	@mkdir -p $(CERT_DIR)
	@mkdir -p $(CERT_OUTPUT_DIR)
	@(cd ./self-signed-ssl && ./self-signed-ssl --no-interaction -c 'XX' -s 'LocalDevState' -l 'LocalDevCity' -o 'LocalDevelopment' -u 'DevTeam' -n '*.docker.localhost' -a '*.docker.localhost')
	@echo "Copying certificates to $(CERT_DIR)..."
	@cp $(CERT_OUTPUT_DIR)/docker.localhost.crt $(CERT_CRT)
	@cp $(CERT_OUTPUT_DIR)/docker.localhost.key $(CERT_KEY)
	@echo "Certificates generated and copied."
	@echo "---------------------------------------------------------------------"
	@echo "IMPORTANT: Add the CA certificate to your browser's trusted CAs:"
	@echo "CA certificate can be found at: $(CERT_OUTPUT_DIR)/CA.pem (or similar name)"
	@echo "See self-signed-ssl/README.MD for instructions."
	@echo "---------------------------------------------------------------------"
else
	@echo "SSL certificates already exist in $(CERT_DIR). Skipping generation."
endif

clean-certs: ## Remove generated SSL certificates and the output directory
	@echo "Removing SSL certificates from $(CERT_DIR)..."
	@rm -f $(CERT_KEY) $(CERT_CRT)
	@echo "Removing SSL certificate output directory $(CERT_OUTPUT_DIR)..."
	@rm -rf $(CERT_OUTPUT_DIR)
	@echo "Certificates cleaned."

##
## Docker Stack Management
## -----------------------
# The network 'traefik_proxy_network' is now created automatically by docker-compose

start: ## Start the Traefik/Portainer stack (ensures certs are generated first)
	@$(MAKE) --no-print-directory generate-certs # Ensure certs are there
	@echo "Starting Traefik/Portainer stack..."
	@$(DOCKER_COMP) --project-name $(PROJECT_NAME) --env-file $(ENV_FILE) up --detach

down: ## Stop the Traefik/Portainer stack
	@echo "Stopping Traefik/Portainer stack..."
	@$(DOCKER_COMP) --project-name $(PROJECT_NAME) --env-file $(ENV_FILE) down --remove-orphans

clean: ## Stop and remove containers, networks, and images for the stack (preserves volumes)
	@echo "Cleaning Docker stack (containers, networks, images - volumes preserved)..."
	@$(DOCKER_COMP) --project-name $(PROJECT_NAME) --env-file $(ENV_FILE) down --remove-orphans --rmi all
	@echo "Docker stack cleaned (volumes preserved)."

clean-all: ## Stop and remove ALL Docker resources: containers, networks, images, AND VOLUMES (destructive, WILL DELETE DATA, asks for confirmation)
	@echo ""
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!! WARNING: This will permanently delete all Docker images AND VOLUMES for this project. !!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@read -r -p "Are you sure you want to delete all images AND volumes? (y/N) " response; \
	echo; \
	if [[ "$$response" =~ ^[Yy]$$ ]]; then \
		echo "Proceeding with deep clean (images AND volumes will be deleted)..."; \
		$(DOCKER_COMP) --project-name $(PROJECT_NAME) --env-file $(ENV_FILE) down --remove-orphans --volumes --rmi all; \
		echo "All Docker resources (including volumes and images) have been removed."; \
	else \
		echo "Aborted. No volumes or images were deleted."; \
		exit 1; \
	fi

full-clean: clean-all clean-certs ## Stop the stack, remove ALL Docker resources (incl. VOLUMES after prompt), and remove certificates
	@echo "Full clean process complete. Certificates removed. Docker resources potentially removed if confirmed."

help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'