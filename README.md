<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/texturecraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.texturecraft.png" width="128" height="128" alt="TextureCraft application icon">
</p>

<h1 align="center">TextureCraft Web — Docker Image</h1>

<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/texturecraft">TextureCraft</a>,
  providing its browser-based application through a self-hosted web interface.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish TextureCraft Web">
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

The official TextureCraft project provides a browser-based version of its 3D texture painting application. This repository packages the web application into a Docker image to simplify self-hosting.

The goals are to:

- Build the TextureCraft Web Web application from the upstream source code.
- Publish a ready-to-run Docker image to GHCR.
- Automatically rebuild the image every week to incorporate upstream changes.
- Provide a convenient deployment option for Unraid Community Applications.
- Offer a simple Docker Compose configuration for users who prefer managing containers with Compose.
- Keep the packaging and deployment configuration separate from the upstream TextureCraft project.

This is a packaging and distribution project, not a fork intended to develop a separate application.

## How it works

TextureCraft Web runs in the user's browser using WebAssembly.

TextureCraft Web runs in the user's browser using WebAssembly. The Docker container serves the generated static web application through NGINX; it does not provide a remote Linux desktop.

- **Browser-based interface:** access the texture painting application through a web browser.
- **WebAssembly application:** the application runs in the browser rather than in a remote desktop session.
- **Web graphics:** the upstream web build uses the browser graphics capabilities supported by the application.
- **Self-hosted:** run the application on your own server and access it over your local network or through a properly configured reverse proxy.

The container serves the application files rather than acting as an application backend or document-storage service, unless explicitly provided by the upstream web application.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/texturecraft-web:latest
```

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is provided at the root of this repository. It is the simplest way to start and maintain TextureCraft Web with Docker Compose.

```yaml
services:
  texturecraft-web:
    image: ghcr.io/mikapst/texturecraft-web:latest
    container_name: texturecraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application with:

```bash
docker compose up -d
```

Open the application in your browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. If Docker is running on your own computer, you can use `http://localhost:8080`.

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

No `.env` file or persistent volume is required for this basic setup. The host port is configured in `docker-compose.yml`; by default, port `8080` on the host is mapped to port `8080` in the container. To use a different host port, change the left-hand side of the mapping. For example, `8081:8080` exposes the application on host port `8081`.

### Option 2 — Run directly with Docker

If you prefer not to use Docker Compose, you can run the container directly:

```bash
docker pull ghcr.io/mikapst/texturecraft-web:latest

docker run -d \
  --name texturecraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/texturecraft-web:latest
```

Open the application at:

```text
http://YOUR_SERVER_IP:8080
```

Optional CPU and memory limits can be added to the `docker run` command if needed, for example `--cpus=2 --memory=2g`. These limits are not included in the default Compose file.

### Network access and reverse proxies

The container listens for HTTP traffic on port `8080`. For external access, use a reverse proxy such as Traefik to terminate HTTPS and forward requests to the container over HTTP.

Do not expose an unencrypted HTTP port directly to the public Internet. Restrict access to your intended network or protect external access with HTTPS and appropriate access controls.

## Automated builds

GitHub Actions builds and publishes the image automatically.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Rebuilds from the upstream `main` branch |
| Manual workflow dispatch | Allows a build to be triggered manually |
| Changes to this repository's README, Compose file or workflow | Triggers a new build |

Each successful build publishes:

- `latest` — the most recently published image.
- `upstream-<commit>` — identifies the upstream commit used for the build.

The build targets `linux/amd64` and `linux/arm64`. Actual compatibility depends on the upstream build and the target platform.

> [!IMPORTANT]
> A weekly build does not guarantee that upstream changes are compatible or stable. TextureCraft is under active development. Test new images before relying on them for important work.

The `latest` tag is mutable and may point to a newer image after a successful build.

## Unraid Community Applications

This image is intended to be distributed through the maintainer's existing Unraid Community Applications repository.

The Unraid template will reference the published GHCR image and provide configuration for the web port and resource limits.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)

This repository contains the image build, publication workflow and Docker Compose configuration. The Unraid Community Applications template is maintained separately.

## Upstream project

TextureCraft is an open-source project developed by the ArtCraft Team and its contributors.

- **Source code:** [texturecraft](https://github.com/storytold/texturecraft)
- **Official website:** [ TextureCraft ](https://getartcraft.com/apps/texturecraft)
- **Official releases:** [TextureCraft releases](https://github.com/storytold/texturecraft/releases)

This repository builds a browser-based version of the upstream application and packages its generated static web files into a Docker image. It is an independent community-maintained packaging project.

## License and attribution

TextureCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option, according to the upstream project. Copyright belongs to the ArtCraft Team and TextureCraft contributors.

The upstream project includes license and attribution information for the application and bundled third-party assets. These notices and the applicable license files must be preserved when redistributing the application.

The licenses for the upstream application do not automatically determine the license of the packaging files maintained in this repository. Refer to the repository's own `LICENSE` file for the terms applicable to those files.

The TextureCraft name, ArtCraft branding and logos remain subject to their respective trademark and usage terms. This repository is an independent community-maintained packaging project and is **not an official TextureCraft release** and is not affiliated with or endorsed by the TextureCraft or ArtCraft maintainers.

## Disclaimer

TextureCraft is under active development. Features, compatibility and behaviour may change between builds. Use the application and its generated files at your own discretion.
