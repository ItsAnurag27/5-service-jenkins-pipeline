FROM python:3.11-alpine

LABEL maintainer="Anurag <anurag@example.com>"
LABEL description="Python Application Service"

WORKDIR /app

# Copy app files
COPY app /app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Run Python HTTP server
CMD ["python", "-m", "http.server", "3000"]
