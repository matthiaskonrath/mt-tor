FROM alpine:latest

LABEL maintainer="Matthias Konrath" \
    description="Mikrotik tor Container"

### Download software
RUN apk update && apk add tor nano

### Change config to allow all connections to the tor server
RUN echo "SOCKSPort 0.0.0.0:9050" >> /etc/tor/torrc


ENTRYPOINT ["/usr/bin/tor"]
