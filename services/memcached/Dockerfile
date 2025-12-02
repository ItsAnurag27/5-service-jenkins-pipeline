FROM nginx:alpine

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Memcached Service with Dashboard"

# Copy custom HTML for dashboard
COPY html/memcached /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
