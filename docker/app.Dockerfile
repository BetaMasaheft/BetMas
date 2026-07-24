# syntax=docker/dockerfile:1
# The app image: application xars layered onto the betmas-data base.
#
# This is the fast build (minutes): the base already contains eXist, registry
# dependencies, all data packages and the expanded corpus, indexed. Rebuilding
# this image never re-runs the data step — produces the release-expanded tag.
#
# BetMasService/parser still come from db/apps/ (no standalone repo yet).
# BetMasApi/BetMasWeb/Dillmann/guidelinesApp are fetched from their own repos instead.
#
# Local build (base from ghcr, or --build-arg BETMAS_DATA_IMAGE=betmas-data:local):
#   docker build -f docker/app.Dockerfile -t betamasaheft:local .

ARG BETMAS_DATA_IMAGE=ghcr.io/betamasaheft/betmas-data:latest
ARG BUILDER_IMAGE=ghcr.io/eeditiones/builder:latest

# Canonical in their own repos (never mirrored into db/apps/), so fetched
# like a data.Dockerfile data package, not COPY'd from here.
ARG BETMASAPI_REF=main
ARG BETMASWEB_REF=main
ARG DILLMANN_REF=master
ARG GUIDELINESAPP_REF=master

FROM ${BUILDER_IMAGE} AS build

ARG BETMASAPI_REF
ARG BETMASWEB_REF
ARG DILLMANN_REF
ARG GUIDELINESAPP_REF

COPY db/apps/BetMasService /tmp/BetMasService
COPY db/apps/parser /tmp/parser
COPY db/apps/BetMas /tmp/BetMas
COPY db/apps/BetMasInitInstance /tmp/BetMasInitInstance

RUN mkdir /tmp/apps /tmp/stage-2

# Numbered for autodeploy's lexicographic install order. BetMasApi (12-)
# must follow BetMasWeb (11-): its expath-pkg declares betmasweb >= 0.1 and
# roaster >= 1.12.1 (the latter ships in the base).
WORKDIR /tmp/BetMasService
RUN jar cfM0 /tmp/apps/10-BetMasService.xar .

# Both ship their own ant build (same xar their own CI produces).
ADD https://github.com/BetaMasaheft/BetMasWeb.git#${BETMASWEB_REF} /tmp/BetMasWeb
WORKDIR /tmp/BetMasWeb
RUN ant && mv build/BetMasWeb-*.xar /tmp/apps/11-BetMasWeb.xar

ADD https://github.com/BetaMasaheft/BetMasApi.git#${BETMASAPI_REF} /tmp/BetMasApi
WORKDIR /tmp/BetMasApi
RUN ant && mv build/BetMasApi-*.xar /tmp/apps/12-BetMasApi.xar

WORKDIR /tmp/parser
RUN jar cfM0 /tmp/apps/13-parser.xar .
WORKDIR /tmp/BetMas
RUN jar cfM0 /tmp/apps/14-BetMas.xar .

# Dillmann shares this instance rather than its own container (#556) -
# matches prod. Unlike collatex-service/sparql-service/iipsrv-fixtures
# (separate containers, own published images), this couples Dillmann's
# release cadence to this image's rebuild. Decoupling it the same way
# would be a real win - means accepting a prod-topology diff first.
ADD https://github.com/BetaMasaheft/DillmannData/releases/latest/download/dill-data.xar /tmp/apps/15-DillmannData.xar
ADD https://github.com/BetaMasaheft/Dillmann.git#${DILLMANN_REF} /tmp/Dillmann
WORKDIR /tmp/Dillmann
RUN ant && mv build/*.xar /tmp/apps/16-Dillmann.xar

# Guidelines shares this instance too (betmas-e2e#67 - never wired into any
# container before this). Same shape as Dillmann: release-asset data +
# schema deps, then the app built from source. html-templating (its other
# declared dependency) needs no separate install - it's an eXist core
# module, already proven working in this image via BetMasWeb's own
# %templates:wrap usage.
ADD https://github.com/BetaMasaheft/Schema/releases/latest/download/betamas-schemas.xar /tmp/apps/17-Schema.xar
ADD https://github.com/BetaMasaheft/guidelines/releases/latest/download/guidelines-data.xar /tmp/apps/18-GuidelinesData.xar
ADD https://github.com/BetaMasaheft/guidelinesApp.git#${GUIDELINESAPP_REF} /tmp/guidelinesApp
WORKDIR /tmp/guidelinesApp
RUN ant && mv build/*.xar /tmp/apps/19-guidelinesApp.xar

WORKDIR /tmp/BetMasInitInstance
RUN jar cfM0 /tmp/stage-2/BetMasInitInstance.xar .


FROM ${BETMAS_DATA_IMAGE}

ARG BETMASAPI_REF
ARG BETMASWEB_REF
ARG DILLMANN_REF
ARG GUIDELINESAPP_REF
ARG APP_COMMIT=unpinned
LABEL org.opencontainers.image.source="https://github.com/BetaMasaheft/BetMas" \
      org.opencontainers.image.description="BetaMasaheft app image: BetMasWeb + BetMasService + BetMasApi + parser + Dillmann + Guidelines on the betmas-data base" \
      eu.betamasaheft.ref.betmas=${APP_COMMIT} \
      eu.betamasaheft.ref.betmasapi=${BETMASAPI_REF} \
      eu.betamasaheft.ref.betmasweb=${BETMASWEB_REF} \
      eu.betamasaheft.ref.dillmann=${DILLMANN_REF} \
      eu.betamasaheft.ref.guidelinesapp=${GUIDELINESAPP_REF}

COPY --from=build /tmp/apps/*.xar /exist/autodeploy/

# boot once: installs only the new app xars — the base's packages are already
# registered, so this is minutes, not the data build
RUN [ "java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-x", "'HelloWorld!!'" ]

# stage-2: copied AFTER the boot so it autodeploys at FIRST CONTAINER START,
# where docker-run env exists — BetMasInitInstance reads APP_URL there.
# Run with: -e APP_URL=http://localhost:8080/exist/apps/BetMasWeb
COPY --from=build /tmp/stage-2/*.xar /exist/autodeploy/

# 8080 exposed by the base image
