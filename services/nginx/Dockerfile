FROM nginx:alpine

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Nginx Web Server Service"

# Copy custom HTML
COPY html/nginx /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
