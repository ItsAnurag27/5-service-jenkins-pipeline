FROM alpine:latest
RUN apk add --no-cache nginx
COPY html/alpine /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
