FROM nginx:1.27-alpine
LABEL org.opencontainers.image.source="https://github.com/MikaPST/texturecraft-web" \
      org.opencontainers.image.description="Community-maintained TextureCraft Web container"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/legal/
RUN test -f /usr/share/nginx/html/index.html \
 && find /usr/share/nginx/html -maxdepth 1 -name '*.wasm' | grep -q .
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
 CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
