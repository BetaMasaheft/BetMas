# syntax=docker/dockerfile:1
# betmas-data: the shared data base image.
#
# eXist + registry dependencies + all data packages + the expanded corpus,
# autodeployed and indexed during the build so containers start in seconds.
# App images layer their xars on top of this (FROM betmas-data); this image
# contains no application code and rebuilds on data-snapshot cadence, not on
# app pushes.
#
# Registry dependency versions are pinned HERE and nowhere else.
#
# Data repo refs default to branch names for local builds; the build workflow
# resolves them to commit SHAs for cache correctness and records them as OCI
# labels (docker inspect answers "which data is in this image?").
#
# Local build (needs a token that can read BetaMasaheft/expanded):
#   printf '%s' "$GITHUB_TOKEN" > /tmp/gh_token
#   docker build -f docker/data.Dockerfile --secret id=github_token,src=/tmp/gh_token -t betmas-data:local .

ARG EXISTDB_VERSION=release
ARG BUILDER_IMAGE=ghcr.io/eeditiones/builder:latest

# global defaults — stages redeclare bare ARGs to inherit these
ARG WORKS_REF=master
ARG MANUSCRIPTS_REF=master
ARG AUTHORITY_FILES_REF=master
ARG PERSONS_REF=master
ARG PLACES_REF=master
ARG INSTITUTIONS_REF=master
ARG NARRATIVE_REF=master
ARG STUDIES_REF=master
ARG CORPORA_REF=main
ARG EXPANDED_REF=main

# builder ships JDK (jar doubles as zip), git, curl, ant — no apt needed
FROM ${BUILDER_IMAGE} AS build

ARG WORKS_REF
ARG MANUSCRIPTS_REF
ARG AUTHORITY_FILES_REF
ARG PERSONS_REF
ARG PLACES_REF
ARG INSTITUTIONS_REF
ARG NARRATIVE_REF
ARG STUDIES_REF
ARG CORPORA_REF
ARG EXPANDED_REF

RUN mkdir /tmp/dependencies

# -- registry dependencies (versions pinned here and nowhere else) --
# autodeploy installs in lexicographic filename order (digits < uppercase <
# lowercase): number every dependency explicitly so libraries install before
# anything that declares them. Data packages follow by name; app xars come in
# the app image on top of an already-installed base.
ARG CRYPTO_VERSION=6.0.1
ARG SHARED_VERSION=0.9.1
ARG MONEX_VERSION=4.2.4
ARG ROASTER_VERSION=1.12.1
ARG TUTTLE_VERSION=2.1.0
ARG PUBLIC_REPO=https://exist-db.org/exist/apps/public-repo/public
ADD ${PUBLIC_REPO}/expath-crypto-module-${CRYPTO_VERSION}.xar /tmp/dependencies/00-expath-crypto.xar
ADD ${PUBLIC_REPO}/shared-resources-${SHARED_VERSION}.xar /tmp/dependencies/01-shared-resources.xar
ADD ${PUBLIC_REPO}/monex-${MONEX_VERSION}.xar /tmp/dependencies/02-monex.xar
ADD ${PUBLIC_REPO}/roaster-${ROASTER_VERSION}.xar /tmp/dependencies/03-roaster.xar
ADD ${PUBLIC_REPO}/tuttle-${TUTTLE_VERSION}.xar /tmp/dependencies/04-tuttle.xar

# -- lists: data-adjacent (editors, canonical taxonomy) read by apps and expansion --
COPY db/apps/lists /tmp/lists
WORKDIR /tmp/lists
RUN jar cfM0 /tmp/dependencies/lists.xar .

# -- data packages --
ADD https://github.com/BetaMasaheft/Works.git#${WORKS_REF} /tmp/Works
WORKDIR /tmp/Works
RUN jar cfM0 /tmp/dependencies/Works.xar .

ADD https://github.com/BetaMasaheft/Manuscripts.git#${MANUSCRIPTS_REF} /tmp/Manuscripts
WORKDIR /tmp/Manuscripts
RUN jar cfM0 /tmp/dependencies/Manuscripts.xar .

ADD https://github.com/BetaMasaheft/Authority-Files.git#${AUTHORITY_FILES_REF} /tmp/Authority-Files
WORKDIR /tmp/Authority-Files
RUN jar cfM0 /tmp/dependencies/Authority-Files.xar .

ADD https://github.com/BetaMasaheft/Persons.git#${PERSONS_REF} /tmp/Persons
WORKDIR /tmp/Persons
RUN jar cfM0 /tmp/dependencies/Persons.xar .

ADD https://github.com/BetaMasaheft/Places.git#${PLACES_REF} /tmp/Places
WORKDIR /tmp/Places
RUN jar cfM0 /tmp/dependencies/Places.xar .

ADD https://github.com/BetaMasaheft/Institutions.git#${INSTITUTIONS_REF} /tmp/Institutions
WORKDIR /tmp/Institutions
RUN jar cfM0 /tmp/dependencies/Institutions.xar .

ADD https://github.com/BetaMasaheft/Narrative.git#${NARRATIVE_REF} /tmp/Narrative
WORKDIR /tmp/Narrative
RUN jar cfM0 /tmp/dependencies/Narrative.xar .

ADD https://github.com/BetaMasaheft/Studies.git#${STUDIES_REF} /tmp/Studies
WORKDIR /tmp/Studies
RUN jar cfM0 /tmp/dependencies/Studies.xar .

ADD https://github.com/BetaMasaheft/corpora.git#${CORPORA_REF} /tmp/corpora
WORKDIR /tmp/corpora
RUN jar cfM0 /tmp/dependencies/corpora.xar .

# -- expanded corpus (private repo; BuildKit secret, token never in a layer) --
RUN --mount=type=secret,id=github_token \
    TOKEN=$(cat /run/secrets/github_token) && \
    git clone https://x-access-token:${TOKEN}@github.com/BetaMasaheft/expanded.git /tmp/expanded-data && \
    git -C /tmp/expanded-data checkout ${EXPANDED_REF} && \
    rm -rf /tmp/expanded-data/.git
WORKDIR /tmp/expanded-data
# .git removed above: the ADD-based checkouts are .git-free, a manual clone is
# not — without this the xar ships gigabytes of git objects into eXist
RUN jar cfM0 /tmp/dependencies/expanded.xar .


FROM duncdrum/existdb:${EXISTDB_VERSION}

ARG WORKS_REF
ARG MANUSCRIPTS_REF
ARG AUTHORITY_FILES_REF
ARG PERSONS_REF
ARG PLACES_REF
ARG INSTITUTIONS_REF
ARG NARRATIVE_REF
ARG STUDIES_REF
ARG CORPORA_REF
ARG EXPANDED_REF

COPY --from=build /tmp/dependencies/*.xar /exist/autodeploy

# boot once so autodeploy runs and the collection indexes bake into the image
RUN [ "java", "org.exist.start.Main", "client", "--no-gui", "-l", "-u", "admin", "-P", "", "-x", "'HelloWorld!!'" ]

# after the boot so label edits never re-trigger the index bake; overrides the
# identity labels inherited from the parent eXist image
LABEL org.opencontainers.image.title="betmas-data" \
      org.opencontainers.image.url="https://github.com/BetaMasaheft/BetMas" \
      org.opencontainers.image.source="https://github.com/BetaMasaheft/BetMas" \
      org.opencontainers.image.description="BetaMasaheft data base image: eXist + data packages + expanded corpus, indexed" \
      eu.betamasaheft.ref.works=${WORKS_REF} \
      eu.betamasaheft.ref.manuscripts=${MANUSCRIPTS_REF} \
      eu.betamasaheft.ref.authority-files=${AUTHORITY_FILES_REF} \
      eu.betamasaheft.ref.persons=${PERSONS_REF} \
      eu.betamasaheft.ref.places=${PLACES_REF} \
      eu.betamasaheft.ref.institutions=${INSTITUTIONS_REF} \
      eu.betamasaheft.ref.narrative=${NARRATIVE_REF} \
      eu.betamasaheft.ref.studies=${STUDIES_REF} \
      eu.betamasaheft.ref.corpora=${CORPORA_REF} \
      eu.betamasaheft.ref.expanded=${EXPANDED_REF}

EXPOSE 8080
