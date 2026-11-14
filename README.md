<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/texturecraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.texturecraft.png" width="128" height="128" alt="TextureCraft icon">
</p>

<h1 align="center">TextureCraft Web — Docker Image</h1>
<p align="center">
  Community-maintained Docker packaging for the browser version of
  <a href="https://github.com/storytold/texturecraft">TextureCraft</a>.<br>
  Automated WebAssembly builds and GHCR publication.
</p>
<p align="center">
  <a href="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml"><img src="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build"></a>
  <a href="https://github.com/MikaPST/texturecraft-web/releases/latest"><img src="https://img.shields.io/github/v/release/MikaPST/texturecraft-web?label=Release&logo=github&color=blue" alt="Release"></a>
  <a href="https://github.com/MikaPST/texturecraft-web/pkgs/container/texturecraft-web"><img src="https://ghcr-badge.egpl.dev/mikapst/texturecraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR"></a>
  <a href="docker-compose.yml"><img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose"></a>
</p>

---

## Why this repository?

The official TextureCraft project offers a Rust-based 3D texture painting application that also runs in a browser. This repository packages its **official WebAssembly web build** as a static site served by NGINX.

The goals are to:

- Compile TextureCraft Web from a specific official upstream release.
- Publish ready-to-run `linux/amd64` and `linux/arm64` Docker images to GHCR.
- Create a matching GitHub Release **only after the image is successfully published**.
- Check for new official releases daily and allow manual or forced rebuilds.
- Keep the Dockerfile, NGINX configuration and build workflow version-controlled in this repository.
- Provide Docker Compose and a separately maintained Unraid Community Applications template.

This is an independent packaging and distribution project, not an upstream fork.

## How it works

TextureCraft Web runs in the browser using WebAssembly. The container only serves static assets; it is **not** a remote desktop, rendering server, or file-storage backend.

- **3D texture painting:** use TextureCraft's browser UI to work with models, materials and textures.
- **WebAssembly:** the Rust application executes locally in the browser.
- **GPU acceleration:** WebGPU where supported, with an upstream WebGL2 fallback.
- **Self-hosted:** access the app from a LAN or through a secure HTTPS reverse proxy.

WebGPU requires a secure browser context (`https://` or `http://localhost`). On ordinary HTTP network addresses, browser GPU capabilities may be limited.

## Repository structure

```text
texturecraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Defines the lightweight NGINX runtime image |
| `nginx.conf` | Serves WebAssembly with the correct MIME type, caching and compression |
| `.dockerignore` | Restricts the Docker context to compiled assets and required files |
| `docker-compose.yml` | Simple self-hosted deployment |
| `.github/workflows/publish-image.yml` | Upstream release detection, Rust/Trunk build, GHCR publication and GitHub Release |
| `README.md` | Usage and maintenance documentation |

### Docker build architecture

1. GitHub Actions resolves the latest official release (or the requested `upstream_tag`).
2. It checks out `storytold/texturecraft` at that **exact release tag** and optionally checks out `storytold/craft-fonts`.
3. Rust with `wasm32-unknown-unknown` and Trunk compiles `apps/texturecraft-web` using `trunk build --release`.
4. The build output comes from `dist/web` as specified by the upstream `Trunk.toml`.
5. The workflow creates a temporary `docker-context/` containing `site/`, `legal/`, and copies the **versioned** `Dockerfile`, `nginx.conf`, and `.dockerignore` from this repository.
6. Docker Buildx builds and publishes the NGINX runtime image for AMD64 and ARM64. No Rust compilation is repeated per architecture.

**Important:** The `site/` and `legal/` directories are generated during GitHub Actions. They are **not** committed to this repository.

## Docker image

The image is published at:

```text
ghcr.io/mikapst/texturecraft-web:latest
```

You can pin a specific upstream release, for example `ghcr.io/mikapst/texturecraft-web:v0.6.0`, when that tag has been successfully published by this repository.

### Option 1 — Docker Compose (recommended)

The root `docker-compose.yml` contains:

```yaml
services:
  texturecraft-web:
    image: ghcr.io/mikapst/texturecraft-web:latest
    container_name: texturecraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start it with:

```bash
docker compose up -d
```

Then open `http://YOUR_SERVER_IP:8080`, or `http://localhost:8080` on the Docker host.

#### Useful Compose commands

```bash
docker compose logs -f
docker compose pull
docker compose up -d
docker compose down
```

The container needs no `.env` file or mounted volume for basic use. To change the host port, edit the left side of `8080:8080`, for example `8081:8080`.

### Option 2 — Run directly with Docker

```bash
docker pull ghcr.io/mikapst/texturecraft-web:latest

docker run -d \
  --name texturecraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/texturecraft-web:latest
```

### Network access and reverse proxies

NGINX listens on port `8080`. For external access, use HTTPS through a reverse proxy such as Traefik. WebGPU typically needs HTTPS except for localhost.

The server serves `.wasm` as `application/wasm`, enables gzip, prevents stale `index.html` caching and caches hashed static assets. A `/health` endpoint is provided for container health checks.

Do not expose an unprotected HTTP service to the public Internet.

## Automated builds

| Trigger | Behaviour |
|---|---|
| Daily schedule (03:17 UTC) | Checks the latest official upstream release and skips it when already packaged |
| Manual workflow dispatch | Builds the latest official release or the specified `upstream_tag` |
| Force rebuild | Rebuilds an existing version with `force_rebuild: true` |
| Packaging changes on `main` | Rebuilds the current official upstream release using the updated packaging |

### Published tags

- `latest` — most recently published Docker image.
- `vX.Y.Z` — official upstream release tag.
- `upstream-<commit>` — first 12 characters of the official upstream source commit.

The image supports `linux/amd64` and `linux/arm64`. GitHub Actions builds the WASM site once, then packages the same static output for both architectures.

### GitHub Releases

After GHCR push succeeds, the workflow creates or updates the matching [TextureCraft Web release](https://github.com/MikaPST/texturecraft-web/releases). The release includes upstream notes, source reference, image tags and digest.

> [!IMPORTANT]
> A GitHub Release is only published after a successful Docker push. `latest` is mutable; use a version tag for reproducible deployments. The separately checked-out `craft-fonts` repository follows its `main` branch.

## Unraid Community Applications

The image is intended for the maintainer's [Unraid Community Applications repository](https://github.com/MikaPST/unraid-community-apps).

- **Template:** [texturecraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/texturecraft-web.xml)
- **Container image:** `ghcr.io/mikapst/texturecraft-web:latest`
- **Web port:** `8080`

The Unraid XML template is maintained separately from this repository.

## Upstream project

TextureCraft is developed by the ArtCraft team and contributors.

- **Source code:** [storytold/texturecraft](https://github.com/storytold/texturecraft)
- **Official website:** [TextureCraft](https://getartcraft.com/apps/texturecraft)
- **Official releases:** [GitHub releases](https://github.com/storytold/texturecraft/releases)
- **Official web hosting guidance:** [packaging/web/README.md](https://github.com/storytold/texturecraft/blob/main/packaging/web/README.md)

This repository builds the official browser application from source but is not an official TextureCraft distribution.

## License and attribution

The upstream application is dual-licensed under **MIT or Apache-2.0**. The workflow copies the upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE` and `ATTRIBUTION.md` files into the image's `/legal/` directory, together with available bundled-font license notices.

Upstream application licenses do not automatically license this repository's independent packaging files. Refer to any packaging license separately. TextureCraft and ArtCraft names and branding remain with their respective owners.

## Disclaimer

TextureCraft is under active development; compatibility and features may change. This independent community packaging is not affiliated with or endorsed by the official project maintainers.
