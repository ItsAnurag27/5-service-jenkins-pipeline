FROM httpd:2.4-alpine

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Apache HTTP Server Service"

# Copy custom HTML
COPY html/httpd /usr/local/apache2/htdocs

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["httpd-foreground"]
