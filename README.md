<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/texturecraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.texturecraft.png" width="128" height="128" alt="TextureCraft application icon">
</p>

<h1 align="center">TextureCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/texturecraft">TextureCraft</a>,
  bringing its Rust and WebAssembly-based 3D texture painting application to a self-hosted web interface.
  <br>
  Automated builds and image publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish TextureCraft Web">
  </a>
  <a href="https://github.com/MikaPST/texturecraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/texturecraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/texturecraft-web/pkgs/container/texturecraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/texturecraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The official TextureCraft project provides a Rust-based 3D texture painting application with a WebAssembly version that runs in a browser. This repository builds the official upstream web application and packages its generated static files into a lightweight NGINX Docker image for straightforward self-hosting.

The goals are to:

- Build TextureCraft Web from a specific official upstream release.
- Publish ready-to-run Docker images to GHCR for `linux/amd64` and `linux/arm64`.
- Automatically detect and package new official TextureCraft releases.
- Publish a matching GitHub Release **only after the Docker image is successfully pushed**.
- Include the shared font resources from [storytold/craft-fonts](https://github.com/storytold/craft-fonts) during compilation.
- Offer Docker Compose and Unraid Community Applications deployment options.
- Keep the `Dockerfile`, `nginx.conf`, `.dockerignore`, and GitHub Actions workflow version-controlled in this repository.

This is an independent packaging and distribution project, not a fork intended to develop a separate texture editor.

## How it works

TextureCraft Web runs directly in the browser using WebAssembly. The Docker container serves static application assets; it is **not** a remote desktop, rendering server, or file-storage backend.

- **3D texture painting:** work with models, materials, and textures through the browser interface.
- **WebAssembly:** the Rust application executes locally in the user's browser.
- **GPU acceleration:** WebGPU where supported, with an upstream WebGL2 fallback; available features depend on the browser and hardware.
- **Self-hosted:** access the editor on your LAN or behind a secure HTTPS reverse proxy.
- **Shared fonts:** the web build uses font resources provided by the upstream `craft-fonts` repository.

WebGPU typically requires a secure browser context (`https://` or `http://localhost`). Access over an ordinary HTTP network address may limit browser GPU capabilities.

The container does not provide a database or server-side project storage. Keep your own copies of important project and exported files.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/texturecraft-web:latest
```

Official upstream releases are also published with matching version tags when successfully packaged. For example:

```text
ghcr.io/mikapst/texturecraft-web:v0.6.0
```

Use a versioned tag when you want to stay on a specific upstream release. The `latest` tag is mutable.

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is provided at the root of this repository:

```yaml
services:
  texturecraft-web:
    image: ghcr.io/mikapst/texturecraft-web:latest
    container_name: texturecraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application:

```bash
docker compose up -d
```

Open the application in your browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with your server's IP address or hostname. If Docker runs on your computer, use `http://localhost:8080`.

#### Useful Compose commands

```bash
# View container logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent application volume is required for the default configuration. To change the host port, edit the left-hand side of `8080:8080`; for example, `8081:8080` exposes the application on host port `8081`.

### Option 2 — Run directly with Docker

If you prefer not to use Docker Compose:

```bash
docker pull ghcr.io/mikapst/texturecraft-web:latest

docker run -d \
  --name texturecraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/texturecraft-web:latest
```

Open `http://YOUR_SERVER_IP:8080`, or `http://localhost:8080` on the Docker host.

### Network access and reverse proxies

NGINX listens on port `8080`. For remote access, use a reverse proxy such as Traefik to terminate HTTPS and forward traffic to the container.

The NGINX configuration serves `.wasm` files as `application/wasm`, enables gzip compression, prevents stale `index.html` caching, and caches hashed static assets. A `/health` endpoint is available for container health checks.

WebGPU typically requires HTTPS except on localhost. Do not expose an unprotected HTTP service directly to the public Internet.

## Repository structure

This repository maintains its own Docker packaging configuration while retrieving official TextureCraft sources during automated builds.

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
| `Dockerfile` | Defines the lightweight NGINX runtime image. |
| `nginx.conf` | Configures WebAssembly MIME types, compression, caching, and the health endpoint. |
| `.dockerignore` | Restricts the Docker build context to compiled assets and required packaging files. |
| `docker-compose.yml` | Provides a ready-to-use deployment configuration. |
| `.github/workflows/publish-image.yml` | Automates upstream release detection, Rust/Trunk compilation, multi-platform GHCR publication, and GitHub Releases. |
| `README.md` | Documents the project, build architecture, and deployment options. |

### Docker build architecture

Unlike PhotoCraft's multi-stage Dockerfile approach, TextureCraft compiles its WebAssembly application **in GitHub Actions before Docker packaging**.

The build process follows these steps:

1. GitHub Actions resolves the latest official TextureCraft release, or a requested `upstream_tag`.
2. It checks out `storytold/texturecraft` at that exact release tag and checks out `storytold/craft-fonts` from its `main` branch.
3. Rust, the `wasm32-unknown-unknown` target, and Trunk compile `apps/texturecraft-web` using `trunk build --release`, with `CRAFT_FONTS_DIR` pointing to the fonts checkout.
4. The workflow validates the generated `dist/web` output, including `index.html` and WebAssembly assets.
5. It assembles a temporary `docker-context/` containing `site/`, `legal/`, and the version-controlled `Dockerfile`, `nginx.conf`, and `.dockerignore` from this repository.
6. Docker Buildx packages the compiled site into an NGINX runtime image for `linux/amd64` and `linux/arm64`, without repeating the Rust compilation per architecture.
7. The workflow pushes the image tags to GHCR and **only then** creates or updates the matching GitHub Release.

The `docker-context/`, `site/`, and `legal/` build directories are generated during GitHub Actions and are **not** committed to this repository.

The runtime container serves static files through NGINX on port `8080`. It requires no Rust toolchain, database, persistent application volume, remote desktop, or GPU passthrough.

> [!NOTE]
> TextureCraft is under active development. Future upstream releases may change Rust, Trunk, fonts, or application paths and require packaging updates.

## Automated builds

GitHub Actions checks the official [TextureCraft releases](https://github.com/storytold/texturecraft/releases) and builds the selected upstream release.

| Trigger | Behaviour |
|---|---|
| Daily schedule (`03:47 UTC`) | Checks for the latest official TextureCraft release and skips it when already packaged. |
| Manual workflow dispatch | Builds the latest official release or a specified `upstream_tag`. |
| Force rebuild | Rebuilds an existing version with `force_rebuild: true`. |
| Packaging changes on `main` | Rebuilds the latest upstream release when the workflow, `Dockerfile`, `nginx.conf`, `.dockerignore`, `docker-compose.yml`, or `README.md` changes. |

### Published tags

Each successful build publishes these GHCR tags:

- `latest` — the most recently successfully packaged upstream release.
- `<upstream-version>` — the exact upstream release tag, for example `v0.6.0`.
- `upstream-<commit>` — the first 12 characters of the official TextureCraft source commit.

The image supports both `linux/amd64` and `linux/arm64`. The WebAssembly site is compiled once, then packaged for both architectures.

The upstream TextureCraft source is checked out at the selected release tag. The `craft-fonts` checkout follows its independent `main` branch, so a later rebuild of the same TextureCraft version may use different font assets.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/texturecraft-web/releases) matching the official upstream release tag.

Each release includes:

- A link to the official TextureCraft release and its publication date.
- Official upstream release notes.
- Published Docker image tags.
- Supported architectures (`linux/amd64` and `linux/arm64`).
- The published Docker image digest.
- A notice that the image is independently maintained community packaging.

The release uses the same upstream version tag as the Docker image. The Release badge at the top of this README reflects the latest published GitHub Release.

Scheduled and ordinary manual runs skip versions already released in this repository. To rebuild an existing version, open **Actions → Build and publish TextureCraft Web → Run workflow** and enable `force_rebuild`. Changes to the monitored files on `main` also trigger a rebuild.

> [!IMPORTANT]
> GitHub Releases are created or updated **only after** the multi-platform image has been successfully pushed to GHCR.
>
> The `latest` tag is mutable. Pin a versioned image tag for stable deployments, noting that a forced rebuild may also replace the image behind an existing version tag.

> [!NOTE]
> The current workflow checks out `craft-fonts` from `main`, but does **not** record its exact commit in the GitHub Release notes. The upstream TextureCraft source is identified by its 12-character commit-based Docker tag.

## Unraid Community Applications

TextureCraft Web can be deployed on Unraid using the separately maintained [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps) template.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **TextureCraft Web template:** [texturecraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/texturecraft-web.xml)
- **Container image:** `ghcr.io/mikapst/texturecraft-web:latest`
- **Container port:** `8080`

The Unraid XML template is maintained separately from this Docker packaging repository.

## Upstream project

TextureCraft is an open-source 3D texture painting application developed by the ArtCraft team and contributors.

- **Source code:** [storytold/texturecraft](https://github.com/storytold/texturecraft)
- **Official website:** [getartcraft.com/apps/texturecraft](https://getartcraft.com/apps/texturecraft)
- **Official web hosting guide:** [packaging/web/README.md](https://github.com/storytold/texturecraft/blob/main/packaging/web/README.md)
- **Official releases:** [TextureCraft releases](https://github.com/storytold/texturecraft/releases)
- **Shared fonts:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)

This repository builds the official browser application from source, but its Docker image and GitHub Releases are **not** official TextureCraft distributions.

## License and attribution

TextureCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. Copyright belongs to the ArtCraft team and contributors.

The workflow preserves upstream `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE`, and `ATTRIBUTION.md` in the image's `/legal/` directory, along with available bundled-font license notices.

- [Upstream MIT License](https://github.com/storytold/texturecraft/blob/main/LICENSE-MIT)
- [Upstream Apache License 2.0](https://github.com/storytold/texturecraft/blob/main/LICENSE-APACHE)
- [Upstream NOTICE](https://github.com/storytold/texturecraft/blob/main/NOTICE)
- [Upstream asset attributions](https://github.com/storytold/texturecraft/blob/main/ATTRIBUTION.md)

The upstream application's licenses do not automatically determine the license of this repository's independent packaging files. Refer to any separately provided packaging license for their terms.

TextureCraft names, artwork, and ArtCraft branding remain subject to the rights of their respective owners.

## Disclaimer

TextureCraft is under active development. Features, browser compatibility, GPU support, and behaviour may change between builds. Test updates and keep independent copies of important projects and exported files.

This repository is independently maintained and is not affiliated with, sponsored by, or endorsed by the official TextureCraft or ArtCraft maintainers.
