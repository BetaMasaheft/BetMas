# syntax=docker/dockerfile:1
# The app image: application xars layered onto the betmas-data base.
#
# This is the fast build (minutes): the base already contains eXist, registry
# dependencies, all data packages and the expanded corpus, indexed. Rebuilding
# this image never re-runs the data step — produces the release-expanded tag.
#
# App sources still come from db/apps/ in this repo; they flip to the
# standalone repos when those become canonical and the copies here freeze.
#
# Local build (base from ghcr, or --build-arg BETMAS_DATA_IMAGE=betmas-data:local):
#   docker build -f docker/app.Dockerfile -t betamasaheft:local .

ARG BETMAS_DATA_IMAGE=ghcr.io/betamasaheft/betmas-data:latest
ARG BUILDER_IMAGE=ghcr.io/eeditiones/builder:latest

FROM ${BUILDER_IMAGE} AS build

COPY db/apps/BetMasService /tmp/BetMasService
COPY db/apps/BetMasWeb /tmp/BetMasWeb
COPY db/apps/parser /tmp/parser
COPY db/apps/BetMas /tmp/BetMas
COPY db/apps/BetMasInitInstance /tmp/BetMasInitInstance

RUN mkdir /tmp/apps /tmp/stage-2

# Numbered for autodeploy's lexicographic install order. 12- is reserved for
# BetMasApi, which must follow BetMasWeb (its expath-pkg declares
# betmasweb >= 0.1 and roaster >= 1.12.1 — the latter ships in the base).
WORKDIR /tmp/BetMasService
RUN jar cfM0 /tmp/apps/10-BetMasService.xar .
WORKDIR /tmp/BetMasWeb
RUN jar cfM0 /tmp/apps/11-BetMasWeb.xar .
WORKDIR /tmp/parser
RUN jar cfM0 /tmp/apps/13-parser.xar .
WORKDIR /tmp/BetMas
RUN jar cfM0 /tmp/apps/14-BetMas.xar .

WORKDIR /tmp/BetMasInitInstance
RUN jar cfM0 /tmp/stage-2/BetMasInitInstance.xar .


FROM ${BETMAS_DATA_IMAGE}

ARG APP_COMMIT=unpinned
LABEL org.opencontainers.image.source="https://github.com/BetaMasaheft/BetMas" \
      org.opencontainers.image.description="BetaMasaheft app image: BetMasWeb + BetMasService + parser on the betmas-data base" \
      eu.betamasaheft.ref.betmas=${APP_COMMIT}

COPY --from=build /tmp/apps/*.xar /exist/autodeploy/

# boot once: installs only the new app xars — the base's packages are already
# registered, so this is minutes, not the data build
RUN [ "java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-x", "'HelloWorld!!'" ]

# stage-2: copied AFTER the boot so it autodeploys at FIRST CONTAINER START,
# where docker-run env exists — BetMasInitInstance reads APP_URL there.
# Run with: -e APP_URL=http://localhost:8080/exist/apps/BetMasWeb
COPY --from=build /tmp/stage-2/*.xar /exist/autodeploy/

# 8080 exposed by the base image
