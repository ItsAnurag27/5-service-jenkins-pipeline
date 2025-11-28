FROM caddy:2-alpine

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Caddy Web Server Service"

# Copy custom HTML
COPY html/caddy /usr/share/caddy

# Create Caddyfile
RUN echo ':80 {root * /usr/share/caddy\nfile_server\n}' > /etc/caddy/Caddyfile

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
