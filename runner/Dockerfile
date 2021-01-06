FROM adoptopenjdk/openjdk11:alpine-jre

WORKDIR /home/container

RUN apk add --no-cache bash jq curl && adduser -D -h /home/container container

USER container
ENV  USER=container HOME=/home/container

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
