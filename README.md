<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/texturecraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.texturecraft.png" alt="TextureCraft icon" width="128">
</p>

<h1 align="center">TextureCraft Web</h1>

<p align="center">
  A self-hosted WebAssembly build of <a href="https://github.com/storytold/texturecraft">TextureCraft</a>, the open-source 3D texture painting application written in Rust.
</p>

<p align="center">
  <a href="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml"><img src="https://github.com/MikaPST/texturecraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish"></a>
  <a href="https://img.shields.io/badge/GHCR-texturecraft--web-blue?logo=docker"><img src="https://img.shields.io/badge/GHCR-texturecraft--web-blue?logo=docker" alt="GHCR"></a>
</p>

## Why this repository?

This repository packages the official TextureCraft browser application as a Docker image, making it straightforward to deploy on Unraid or another Docker-compatible host.

The application is built directly from the upstream `storytold/texturecraft` source. This repository only adds the container packaging and static web server; it does not fork or modify the application.

## How it works

- GitHub Actions checks out the latest upstream `main` branch and the shared `storytold/craft-fonts` repository.
- Rust 1.95 and the `wasm32-unknown-unknown` target are installed.
- Trunk builds the official web application.
- The generated static site is packaged into a lightweight NGINX image.
- The image is published for `linux/amd64` and `linux/arm64` to GitHub Container Registry.

TextureCraft runs in the browser through eframe and WebAssembly. Its renderer uses WebGPU where available, with a WebGL2 fallback. The browser version uses browser file selection for opening files and downloads for exported files; it does not expose the desktop app's local control server.

## Docker image

```bash
docker pull ghcr.io/mikapst/texturecraft-web:latest
```

| Setting | Value |
| --- | --- |
| Image | `ghcr.io/mikapst/texturecraft-web:latest` |
| Container port | `8080` |
| Architectures | `linux/amd64`, `linux/arm64` |
| Web server | NGINX |

### Docker Compose

```yaml
services:
  texturecraft-web:
    image: ghcr.io/mikapst/texturecraft-web:latest
    container_name: texturecraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

## Automated builds

The GitHub Actions workflow publishes the container image:

- On changes to this repository's README, Compose file or workflow.
- On manual dispatch.
- On a weekly schedule, to pick up upstream changes.

Published tags:

- `latest` — most recent successful build.
- `upstream-<commit>` — the upstream commit used for the build.

## Build pipeline

1. Checkout `storytold/texturecraft` (`main`) and `storytold/craft-fonts`.
2. Install Rust 1.95, the `wasm32-unknown-unknown` target and Trunk.
3. Set `CRAFT_FONTS_DIR` to the shared font repository and run `trunk build --release` from `apps/texturecraft-web`.
4. Verify that the generated site contains `index.html` and at least one WebAssembly module.
5. Create a temporary Docker build context with the generated static site and an NGINX configuration.
6. Build and push a multi-platform image to GHCR.

The upstream `Trunk.toml` sets the output directory to `upstream/dist/web`, uses relative asset URLs and enables content-hashed filenames. NGINX serves the entry page without caching and gives hashed assets long-lived immutable caching.

## Unraid Community Applications

This image can be used as the basis for an Unraid Community Applications template. Configure the container port as `8080` and map it to a host port of your choice.

## Upstream project and attribution

- **Project:** [TextureCraft](https://getartcraft.com/apps/texturecraft)
- **Source code:** [storytold/texturecraft](https://github.com/storytold/texturecraft)
- **Shared fonts:** [storytold/craft-fonts](https://github.com/storytold/craft-fonts)
- **Publisher:** ArtCraft Team and contributors
- **License:** TextureCraft is dual-licensed under [MIT](https://github.com/storytold/texturecraft/blob/main/LICENSE-MIT) or [Apache-2.0](https://github.com/storytold/texturecraft/blob/main/LICENSE-APACHE), at your option. Bundled assets and fonts retain their own licenses; consult upstream `NOTICE` and `ATTRIBUTION.md`.

This repository is an independent container packaging project. It is not affiliated with or endorsed by the upstream maintainers.

## License / Disclaimer

The packaging files in this repository are provided under the MIT License. TextureCraft and its bundled assets remain subject to their respective upstream licenses and notices.

TextureCraft is under active development. Consult the [official project page](https://getartcraft.com/apps/texturecraft), [upstream README](https://github.com/storytold/texturecraft#readme) and [release notes](https://github.com/storytold/texturecraft/releases) for current status and limitations.
