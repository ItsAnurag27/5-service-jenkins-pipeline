FROM traefik:latest

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Traefik Reverse Proxy and Load Balancer"

# Expose ports
EXPOSE 80 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/ping || exit 1

# Default command configured in docker-compose
ENTRYPOINT ["/entrypoint.sh"]
