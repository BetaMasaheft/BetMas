FROM ubuntu:latest AS build

COPY . /tmp/counter-app
RUN apt update && apt install -y zip
WORKDIR /tmp/counter-app
RUN mkdir -p /tmp/assets && zip -0r /tmp/assets/counter-app.xar .

FROM duncdrum/existdb:6.2.0

COPY --from=build /tmp/assets /exist/autodeploy
