---
name: lab
description: Manage the Docker-based vulnerable practice lab targets
argument-hint: "[start|stop|status]"
---

# Lab Environment

Manage the Docker-based vulnerable practice targets for safe pentesting exercises.

## Operations

- `make lab-up` -- Start all vulnerable lab containers in detached mode
- `make lab-down` -- Stop and remove all lab containers
- `make lab-status` -- Show running status of lab containers

## Lab Targets

| Service | URL | Credentials |
|---------|-----|-------------|
| DVWA | http://localhost:8080 | admin / password |
| Juice Shop | http://localhost:3030 | (register an account) |
| WebGoat | http://localhost:8888/WebGoat | (register an account) |
| VulnerableApp | http://localhost:8180/VulnerableApp | -- |

## Prerequisites

- Docker must be installed and the Docker daemon must be running
- Uses docker compose v2 with `labs/docker-compose.yml`
- First startup pulls images automatically (may take a few minutes)

## Usage Notes

- Always use `make lab-*` targets rather than running docker compose directly
- Containers restart automatically unless explicitly stopped with `make lab-down`
- DVWA requires first-login database setup -- click "Create / Reset Database" on the setup page
- WebGoat listens on port 8888 (mapped from container port 8080) and also exposes port 9090
