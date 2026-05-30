FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-jre-headless \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8
ENV TZ=Asia/Tokyo

# Pre-built narou gem (built on host after PRs applied)
COPY narou-*.gem /tmp/
RUN gem install --no-document /tmp/narou-*.gem \
    && rm /tmp/narou-*.gem

# AozoraEpub3 (from local NarouTranslator copy)
COPY AozoroEpub3/ /opt/AozoraEpub3/

# Docker entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create novel data directory
RUN mkdir -p /novel

WORKDIR /novel
EXPOSE 33000 33001

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["narou", "web", "-b", "127.0.0.1", "-p", "33000", "-n"]
