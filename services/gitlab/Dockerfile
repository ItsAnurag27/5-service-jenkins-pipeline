FROM gitlab/gitlab-ce:latest
ENV GITLAB_OMNIBUS_CONFIG="external_url 'http://localhost:9088'"
EXPOSE 80 443 22
CMD ["/assets/wrapper"]
