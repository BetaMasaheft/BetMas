FROM ubuntu:latest AS build

# zip is needed to make xars
RUN apt update && apt install -y zip

COPY db/apps/BetMas /tmp/BetMas
COPY db/apps/BetMasService /tmp/BetMasService
COPY db/apps/BetMasInitInstance /tmp/BetMasInitInstance
COPY db/apps/BetMasWeb /tmp/BetMasWeb
COPY db/apps/lists /tmp/lists
COPY db/apps/parser /tmp/parser

RUN mkdir /tmp/dependencies
RUN mkdir /tmp/stage-2

ADD  http://exist-db.org:8098/exist/apps/public-repo/public/expath-crypto-module-6.0.1.xar /tmp/dependencies/expath-crypto.xar
ADD  http://exist-db.org:8098/exist/apps/public-repo/public/shared-resources-0.9.1.xar /tmp/dependencies/shared-resources.xar
ADD  https://exist-db.org/exist/apps/public-repo/public/monex-4.2.4.xar /tmp/dependencies/00monex.xar

WORKDIR /tmp/BetMas
RUN zip -0r /tmp/dependencies/XXX_BetMas.xar .

WORKDIR /tmp/lists
RUN  zip -0r /tmp/dependencies/lists.xar .
WORKDIR /tmp/parser
RUN  zip -0r /tmp/dependencies/parser.xar .

WORKDIR /tmp/BetMasWeb
RUN  zip -0r /tmp/dependencies/BetMasWeb.xar .
WORKDIR /tmp/BetMasService
RUN  zip -0r /tmp/dependencies/BetMasService.xar .

WORKDIR /tmp/BetMasInitInstance
RUN  zip -0r /tmp/stage-2/BetMasInitInstance.xar .

# Now install the rest of the items
ADD https://github.com/BetaMasaheft/Works.git /tmp/Works
WORKDIR /tmp/Works
RUN  zip -0r /tmp/dependencies/Works.xar .

ADD https://github.com/BetaMasaheft/Manuscripts.git /tmp/Manuscripts
WORKDIR /tmp/Manuscripts
RUN  zip -0r /tmp/dependencies/Manuscripts.xar .

# ADD https://github.com/BetaMasaheft/Dillmann.git /tmp/Dillmann
# WORKDIR /tmp/Dillmann/gez-en-2.6
# RUN  zip -0r /tmp/dependencies/Dillmann.xar .

ADD https://github.com/BetaMasaheft/Authority-Files.git /tmp/Authority-Files
WORKDIR /tmp/Authority-Files
RUN  zip -0r /tmp/dependencies/Authority-Files.xar .

ADD https://github.com/BetaMasaheft/Persons.git /tmp/Persons
WORKDIR /tmp/Persons
RUN  zip -0r /tmp/dependencies/Persons.xar .

ADD https://github.com/BetaMasaheft/Places.git /tmp/Places
WORKDIR /tmp/Places
RUN  zip -0r /tmp/dependencies/Places.xar .

ADD https://github.com/BetaMasaheft/Institutions.git /tmp/Institutions
WORKDIR /tmp/Institutions
RUN  zip -0r /tmp/dependencies/Institutions.xar .

ADD https://github.com/BetaMasaheft/Narrative.git /tmp/Narrative
WORKDIR /tmp/Narrative
RUN  zip -0r /tmp/dependencies/Narrative.xar .

ADD https://github.com/BetaMasaheft/Studies.git /tmp/Studies
WORKDIR /tmp/Studies
RUN  zip -0r /tmp/dependencies/Studies.xar .

ADD https://github.com/BetaMasaheft/corpora.git /tmp/corpora
WORKDIR /tmp/corpora
RUN  zip -0r /tmp/dependencies/corpora.xar .


ADD https://@github.com/BetaMasaheft/expanded.git /tmp/expanded-data
WORKDIR /tmp/expanded-data
RUN zip -0r /tmp/dependencies/expanded.xar .

# ADD https://github.com/BetaMasaheft/chojnacki.git /tmp/chojnacki
# WORKDIR /tmp/chojnacki
# RUN  zip -0r /tmp/dependencies/chojnacki.xar .


FROM duncdrum/existdb:6.4.0

# RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "xmldb:create-collection('/db/apps', 'log')" ]

COPY --from=build /tmp/dependencies/*.xar /exist/autodeploy

RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "'HelloWorld!!'" ]

# Finalize with expanding content
# RUN [ "java", "org.exist.start.Main", "client", "--no-gui",  "-l", "-u", "admin", "-P", "", "-x", "util:log('INFO', 'Expanding content'), util:eval(xs:anyURI('/db/apps/BetMasService/modules/makeExpand.xql'), false(), ('what-to-expand', '/db/apps/BetMasData'))" ]

# Copy betmas init to bootstrap the app with teh correct URL. Just set it as an environment arg: -e APP_URL=http://localhost:8080/exist/apps/BetMasWeb
COPY --from=build /tmp/stage2/*.xar /exist/autodeploy

EXPOSE 8080
