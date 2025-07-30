FROM ubuntu:latest AS build

# zip is needed to make xars
RUN apt update && apt install -y zip

ARG COMMIT_HASH=local

COPY db/apps/BetMas /tmp/BetMas
COPY db/apps/BetMasService /tmp/BetMasService
COPY db/apps/BetMasWeb /tmp/BetMasWeb
COPY db/apps/lists /tmp/lists
COPY db/apps/parser /tmp/parser
COPY db/apps/BetMasInitInstance /tmp/betmas-init
COPY db/apps/expanded /tmp/expanded

RUN mkdir /tmp/dependencies
RUN mkdir /tmp/init

WORKDIR /tmp/BetMas
RUN zip -0r /tmp/dependencies/BetMas.xar .

WORKDIR /tmp/lists
RUN  zip -0r /tmp/dependencies/lists.xar .

WORKDIR /tmp/parser
RUN cat ./expath-pkg.xml
RUN  zip -0r /tmp/dependencies/parser.xar .

WORKDIR /tmp/BetMasWeb
RUN  zip -0r /tmp/dependencies/BetMasWeb.xar .

WORKDIR /tmp/BetMasService
RUN  zip -0r /tmp/dependencies/BetMasService.xar .

WORKDIR /tmp/BetMasService
RUN  zip -0r /tmp/dependencies/BetMasService.xar .

WORKDIR /tmp/betmas-init
RUN  zip -0r /tmp/init/betmas-init.xar .

FROM ghcr.io/drrataplan/betamasaheft:6.2.0-manuscript-expanded

# Undeploy and remove the older versions of the packages so we can replace them with new ones
RUN ["java","org.exist.start.Main","client","--no-gui","-l","-u", "admin", "-P", "","-x", "('https://betamasaheft.eu/betmasweb/', 'https://www.betamasaheft.uni-hamburg.de/BetMas', 'https://betamasaheft.eu/BetMasService')!(repo:undeploy(.), repo:remove(.))"]

COPY --from=build /tmp/dependencies/*.xar /exist/autodeploy

RUN ["java","org.exist.start.Main","client","--no-gui","-l","-u", "admin", "-P", "","-x", "'Hello World!'"]

# Prepare this betmas-init package to be installed when deploying. It reads an env variable that is only
# available when the container is started
COPY --from=build /tmp/init/*.xar /exist/autodeploy
