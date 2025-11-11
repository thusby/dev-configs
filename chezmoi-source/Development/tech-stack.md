# Tech Stack

This document serves as a unified reference for all active projects in the development environment. Different projects use different stacks optimized for their specific domains.

---

## Project Overview

| Project | Domain | Primary Language | Main Framework |
|---------|--------|------------------|----------------|
| **localfarm** | Web Platform | Python 3.12, JS | Django 5.1 + Vue.js 3.5 |
| **mcp-common** | API Integration | Python 3.11+ | FastMCP 2.0 |
| **coordinator** | Multi-Agent Systems | Python 3.10+ | FastAPI |
| **zephyr-meta** | Embedded Systems | C | Zephyr RTOS 3.7.1 |
| **openvino** | AI/ML Inference | Python 3.x | OpenVINO + Ollama |

**Repository Structure:**
```
~/Development/
├── dev-configs/         # Shared development configurations
├── projects/           # All development projects
│   ├── mcp-common/
│   ├── coordinator/
│   ├── localfarm/
│   ├── zephyr-meta/
│   └── openvino/
└── tech-stack.md       # This file
```

---

## LocalFarm (Web Platform)

### Framework & Runtime
- **Backend Framework:** Django 5.1.13 + Django REST Framework 3.15.2
- **Frontend Framework:** Vue.js 3.5.12
- **Language/Runtime:** Python 3.12, Node.js 22
- **Package Manager:** pip (backend), npm (frontend)
- **WSGI Server:** Gunicorn 23.0.0 (4 workers)
- **Build Tool:** Vite 5.4.10

### Frontend
- **JavaScript Framework:** Vue.js 3.5.12
- **State Management:** Pinia 2.2.4
- **Routing:** Vue Router 4.4.5
- **HTTP Client:** Axios 1.7.7
- **CSS Framework:** Custom (no framework)

### Database & Storage
- **Database:** PostgreSQL 16 (containerized)
- **Python Driver:** psycopg2-binary 2.9.9
- **ORM:** Django ORM
- **Caching:** Redis 7 (multi-tenant)
- **Message Queue:** Celery 5.4.0 + Celery Beat 2.7.0

### Authentication & Security
- **Authentication:** JWT (djangorestframework-simplejwt 5.5.1)
- **Two-Factor Auth:** django-otp 1.5.4 (TOTP)
- **Email Service:** Gmail API with OAuth 2.0
  - google-auth 2.35.0
  - google-api-python-client 2.149.0
- **CORS:** django-cors-headers 4.4.0
- **Security Features:**
  - Non-root Docker users
  - SSH hardening + Fail2ban
  - UFW firewall
  - Let's Encrypt SSL/TLS

### API Documentation
- **OpenAPI/Swagger:** drf-spectacular 0.27.2
- **Endpoint:** `/api/schema/swagger/`

### Testing & Quality
- **Test Framework:** Django TestCase
- **Linting/Formatting:** Python standard tools
- **Locale:** Norwegian Nynorsk (nb-no)

### Deployment & Infrastructure
- **Containerization:** Docker + Docker Compose
- **Orchestration:** Ansible 2.16+
- **Reverse Proxy:** Traefik 2.11 (with Let's Encrypt DNS-01)
- **Monitoring:** Prometheus + Grafana + Loki
- **Alerting:** Alertmanager → Slack
- **Log Aggregation:** Loki + Promtail
- **CI/CD:** Ansible Playbooks (ansible-pull client)
- **Hosting:** Self-hosted (api.localfarm.no, localfarm.no)

### Infrastructure Layers
1. **Base:** Traefik, Redis, Security (SSH/UFW/Fail2ban)
2. **Monitoring:** Prometheus, Grafana, Loki, Alertmanager
3. **Application:** Django backend, Vue frontend, Celery workers

---

## MCP-Common (Model Context Protocol Integration)

### Framework & Runtime
- **Framework:** FastMCP 2.0 (v2.13.0)
- **Language/Runtime:** Python 3.11+
- **Package Manager:** uv (fast Python package manager)
- **Architecture:** Async/await with asyncio

### API Integration & Networking
- **HTTP Client:** httpx (≥0.28.0) with built-in resilience
- **Web Framework:** FastAPI (≥0.110.0)
- **Server:** uvicorn (≥0.30.0)
- **Async HTTP:** aiohttp (≥3.9.0)
- **Streaming:** sse-starlette (≥2.0.0)
- **Protocol:** JSON-RPC 2.0 (jsonrpc-base ≥2.2.0)

### Data Validation & Configuration
- **Validation:** Pydantic (≥2.0.0)
- **Settings:** pydantic-settings (≥2.0.0)
- **Secrets:** Environment-based configuration

### Integrated Services (Monorepo)
1. **mcp-tana** - Tana Input API (9 tools, 37 tests)
2. **mcp-gmail** - Gmail API (9 tools, 31 tests)
3. **mcp-readwise** - Readwise API (17 tools, 27 tests)

### Testing & Quality
- **Test Framework:** pytest (≥7-8.0.0)
- **Async Testing:** pytest-asyncio (≥0.21-0.23.0)
- **HTTP Mocking:** pytest-httpx (≥0.22.0)
- **Coverage:** pytest-cov (≥4.0-4.1.0)
- **Linting:** ruff (≥0.1-0.3.0)
- **Type Checking:** mypy (≥1.0-1.9.0)
- **Formatting:** black (≥24.0.0)

### Key Features
- Smart retry logic with exponential backoff
- Rate limiting (token bucket + adaptive)
- Exception hierarchy with actionable hints
- Async HTTP client (MCPHTTPClient)

---

## Coordinator (Multi-Agent Systems)

### Framework & Runtime
- **Framework:** FastAPI (≥0.110.0)
- **Language/Runtime:** Python 3.10+
- **Package Manager:** pip/setuptools
- **Server:** uvicorn[standard] (≥0.30.0)

### Protocols & Communication
- **Primary Protocols:** A2A (Agent2Agent) + MCP (Model Context Protocol)
- **RPC:** JSON-RPC 2.0 (jsonrpc-base ≥2.2.0)
- **Transport:** HTTP/HTTPS, stdio, SSE, WebSocket
- **Streaming:** Server-Sent Events (SSE)
- **Optional:** gRPC (≥1.60.0)

### Networking
- **HTTP Client:** httpx (≥0.27.0)
- **Async HTTP:** aiohttp (≥3.9.0)
- **Form Data:** python-multipart (≥0.0.9)

### Data Validation
- **Validation:** Pydantic (≥2.0.0)

### Testing & Quality
- **Test Framework:** pytest (≥8.0.0)
- **Async Testing:** pytest-asyncio (≥0.23.0)
- **Coverage:** pytest-cov (≥4.1.0)
- **Formatting:** black (≥24.0.0)
- **Linting:** ruff (≥0.3.0)
- **Type Checking:** mypy (≥1.9.0)

### Architecture
- Layered design: Application → Agent Framework → Protocol Adapters → Core Messaging → Transport → Security
- Agent discovery via Agent Cards (`.well-known/agent-card.json`)
- Task-based asynchronous workflows
- Protocol bridging (A2A ↔ MCP)
- Multi-transport support

### Use Cases
- Multi-agent collaboration (3-10 agents)
- LLM integration as agents
- API orchestration
- Tool access through MCP

---

## Zephyr-Meta (Embedded Systems)

### Framework & Runtime
- **RTOS:** Zephyr RTOS v3.7.1 (LTS)
- **Language:** C (embedded systems)
- **Build System:** CMake + west (Zephyr meta-tool)
- **DevContainer:** zephyrprojectrtos/ci:v0.26.13

### Code Standards
- **Formatting:** .clang-format (Zephyr RTOS style)
- **Editor Config:** .editorconfig for consistency

### Development Tools
- **Version Control:** Git with submodules
- **IDE:** VS Code with DevContainer
- **Container Runtime:** Docker

### Supported Hardware
- Arduino Nano 33 IoT (SAMD21 ARM Cortex-M0+)
- nRF52840 DK (ARM Cortex-M4)
- Raspberry Pi Pico (RP2040 ARM Cortex-M0+)
- ESP32 DevKit
- STM32 Nucleo F401RE

### Common Library (lib/common/)
- **gpio_helpers.c/h** - GPIO utilities (LED/button control)
- **error_handling.c/h** - Error macros (`ZH_CHECK_RET`, `ZH_CHECK_GOTO`)
- Naming convention: `zh_` prefix

### Build & Deploy Scripts
- `new-project.sh` - Generate board projects
- `build-all.sh` - Build all boards
- `flash-board.sh` - Flash firmware
- `update-zephyr-version.sh` - Upgrade Zephyr

### Architecture
- Git submodules for board-specific projects
- west.yml workspace coordination
- DevContainer for isolated development

---

## OpenVINO (AI/ML Inference)

### Framework & Runtime
- **Primary Framework:** OpenVINO (top-level API)
- **LLM Inference:** Ollama
- **Language:** Python 3.x
- **DevContainer:** openvino/ubuntu24_dev (Ubuntu 24.04)

### Hardware Acceleration
- **Intel Arc A750** - GPU inference via Level Zero API
  - Device: `/dev/dri/renderD128`
  - User groups: render (GID 992), video (GID 44)
- **NVIDIA RTX 4060 Ti** - Generative AI and LLM workloads

### Dependencies
- **numpy** - Array operations
- **openvino** - Inference runtime with opset12 support
- **Ollama API** - HTTP client for LLM access
  - Endpoint: `http://localhost:11434`
  - Default model: `codestral:latest`
  - Streaming support for TTFT measurements

### Development Environment
- **IDE:** VS Code with Remote-Containers
- **Networking:** `--network=host` for Ollama connectivity
- **GPU Access:** Level Zero for Intel Arc

### Testing Scripts
- **main.py** - OpenVINO GPU inference test (multiply model)
- **ollama_test.py** - LLM performance evaluation
- **git_sync.sh** - Git synchronization for Docker

### Configuration
- Git config disables `filemode` and `trustctime` tracking
- Ollama service listens on `0.0.0.0` (OLLAMA_HOST env var)

---

## Cross-Project Technology Summary

### Programming Languages
- **Python:** localfarm (3.12), mcp-common (3.11+), coordinator (3.10+), openvino (3.x)
- **C:** zephyr-meta (embedded systems)
- **JavaScript:** localfarm frontend (Node.js 22)

### Common Patterns Across Python Projects
- **Data Validation:** Pydantic (used in localfarm, mcp-common, coordinator)
- **Async/Await:** Extensive use in mcp-common and coordinator
- **Testing:** pytest standard across all Python projects
- **Type Safety:** Full type hints with mypy
- **Code Quality:** black, ruff, isort for formatting/linting

### Containerization
- **Docker:** Used in localfarm, openvino
- **Docker Compose:** localfarm orchestration
- **DevContainers:** zephyr-meta, openvino

### Infrastructure & Deployment
- **IaC:** Ansible (localfarm)
- **Reverse Proxy:** Traefik with Let's Encrypt (localfarm)
- **Monitoring:** Prometheus + Grafana + Loki (localfarm)
- **Package Management:** uv (mcp-common), npm (localfarm frontend), west (zephyr-meta)

### Development Configuration
- **Shared Standards:** ~/Development/dev-configs
  - Python: ruff, mypy, pytest, black configs
  - C/C++: clang-format, editorconfig
  - Git: .gitignore templates
- **Usage:** Projects import via `../../dev-configs/python/pyproject-base.toml`

---

## Platform Consistency

All projects use consistent paths across platforms:
- **Mac:** `~/Development` ✓
- **Linux:** `~/Development` ✓

Configuration management:
- **dotfiles:** Personal system configuration + secrets (git-crypt)
- **chezmoi:** Cross-platform configuration synchronization
- **dev-configs:** Shared team/project standards (GitHub: thusby/dev-configs)

---

## Author
**Terje Husby** - All projects are part of a cohesive personal technology ecosystem.

**Last Updated:** 2025-11-10
