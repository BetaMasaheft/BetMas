# BetMas
Exist-db application (without data)
This is at the moment not the master repo of the app. It is a copy for transparency and version tracking purposes, which reproduces what is currently online. Once the new version is ready and online, the code is updated here and the release note going with it explains what has changed. 
This is the code used by the app displaying the data of the project.
All js dependencies typically stored in resources are not copied in this repo
The data is omitted and is the one stored in this same group in the specific repositories.

The Beta Masaheft app works at the moment with two of the application building models availble in exist-db
most functions have been taken from examples already available. If authors feel they are not adequately akwnoledged, please tell me!

# this description is !WORK IN PROGRESS!

# the data
the data is stored in repositories in this group and is pushed to the live app via webhooks in each repo which point to the gitsyncREPONAME.xql files in the modules collection. 

## Controller/model/view 
The parts of the app using this technology use functions in modules which need to be imported by view.xql, the xquery which calls the templates module and matches the data-template attributes in the html with the xquery functions.

### Templates
- templates/search.html is used by the advanced search, as.html
- templates/searchR.html is used by search.html
- templates/list.html is used by index like resources 
- templates/page.html is used by the index page and documentation pages

### Advanced search form
The initial form in as.html uses the controller template model with the template search.html, which calls 
a javascirpt filters.js which on click loads with AJAX the selected form*.html file. Each of these contains a call to a function app:NAMEofTHEform which will call app:formcontrol which will call app:selectors
This allows the form to be flexibly adjusted and load only what is needed.
The number of parameters needed does not allow to do this (to my current knowledge) with RESTXQ unfortunately

### The index page
The index page calls some functions to display the data and give an introduction to the project.

### The navigation bar
The navigation bar is called in the templates or from the restxq modules and is the primary navigation aid. The standard navbar is in nav.xql, but some templates needing modification of it have their own.

### Other static pages
Search results are presented in a html page in this way from search.html
API Documentation is hand produced in apidoc.html
The breakdown of the work from the Team is displayed in team.html
the basic information, including version about the app is in appInfo.html

### Resources/indexes
The indexes under Resources use the controller/model/view system to load from the called html a single function producing the result. these functions are in resources.xqm

### Explicit TEI
post.xsl transformation is called directly by the controller for any request with the pattern /tei/resource.xml.
this is different from calling simply resource.xml which will return the source file

## RESTXQ APIs
### Items View
items.xql is the restXQ module which maps the request for a specific resource in the database to a series of views, text, entry, xml (see above) and relations.

### List View
list.xql produces the list views for reosurces in the app and some filter options

### Comparison
compare.xql is another restXQ module which calls the function producing the carousel with the manuscripts containing one selected text

### DTS
dts.xql implements the DTS specification (still only partially and not according to implementation guidelines) to serve text from BM. 

### IIIF
iiif.xql takes data from the TEI of manuscripts and produces dinamically manifests according to the IIIF presentation API. most uris are dereferencable. Structures and Ranges are used to locate and make available for navigation relevant information in the TEI file
 
### Gazetteer (Pelagios Interconnection format) and pelagios annotations
places.xql produces annotations according to the pelagios format and the gazetteer of places in the pelagios interconnection format

## other functions modules
- config.xqm and app.xqm contain modules used by the app in general
- coordinates.xql contains functions which produce coordinates and place informations for other modules
- error.xqm contains the error messages for restxq functions using it
- item.xqm contains functions used for the item view and called by items.xql RESTXQ module
- map.xqm contains the functions used to produce maps in the app
- timeline.xqm contains the functions used to produce timelines
- titles.xqm contains the functions used to print the titles based on element or id
- view.xql is the core module of the controller model
- viewer is the RESTXQ module containing the mirador.js for images display (it could have lived in items.xql)
- relations.xqm has a series of functions used to produce nodes and edges for vis.js
- sandbox is where I test stuff

## Javascript usage
### general
jquery
bootstrap

### Vis.js
is used for graphs and timelines

### Mottie js Keyboard
We use this very nice js keyboard to which we have contributed an ethiopic keyboard wich can be used both with predefined combinataion (documented in combo.html) or holding the selected character. 

### bootstrap-slider
is used for the date and other sliders in search filters

### slick
is used for the comparison of manuscripts for the carousel

### Mirador
is used to view images from the iiif manifests

### Openseedragon
is used to view images in the catalogue entry view

### Awdl
this does the small popups on links to perseus, geonames, wikipedia

## Docker deployments

The image is built in two layers, published separately:

- **`betmas-data`** (`docker/data.Dockerfile`, `.github/workflows/build-data.yml`): eXist plus the
  registry dependencies, all data repos and the private `expanded` corpus, autodeployed and indexed
  at build time. This is the slow build (~3h) — it rebuilds on a weekly schedule, on manual dispatch,
  or when `expanded`'s `main` branch moves, and nobody waits on it interactively. Published as
  `ghcr.io/betamasaheft/betmas-data`.
- **App image** (`docker/app.Dockerfile`, `.github/workflows/docker-build.yml`): the application xars
  in this repo (`BetMasService`, `BetMasWeb`, `parser`, `BetMas`) layered onto the current
  `betmas-data:latest`. This is the fast build (minutes) and runs on every push to `master`.
  Published as `ghcr.io/betamasaheft/betamasaheft:release-expanded`.

### Building the App Image Locally

```bash
docker build \
  -f docker/app.Dockerfile \
  -t ghcr.io/betamasaheft/betamasaheft:local \
  .
```

To build against a locally-built data image instead of the published one (e.g. while iterating on
`docker/data.Dockerfile`), pass `BETMAS_DATA_IMAGE`:

```bash
docker build \
  -f docker/app.Dockerfile \
  --build-arg BETMAS_DATA_IMAGE=betmas-data:local \
  -t ghcr.io/betamasaheft/betamasaheft:local \
  .
```

#### Pulling and Running the Image

Pull the pre-built image from GHCR:
```bash
docker pull ghcr.io/betamasaheft/betamasaheft:release-expanded
```

Run the container:
```bash
docker run -d \
  -p 8080:8080 \
  -e APP_URL=http://localhost:8080/exist/apps/BetMasWeb \
  --name betmas \
  ghcr.io/betamasaheft/betamasaheft:release-expanded
```

The application will be available at `http://localhost:8080/exist/apps/BetMasWeb`

### CI Build Process

`.github/workflows/docker-build.yml` builds and pushes the app image (multi-arch, amd64 and arm64)
after every successful `Format Check` run on `master`, or on manual dispatch. It always builds
against `betmas-data:latest` — it does not wait for or trigger a data rebuild.

`.github/workflows/build-data.yml` builds and pushes `betmas-data` on its own schedule (see above);
run it manually via GitHub Actions if a data repo needs to land sooner.

## Code Formatting with Prettier

This project uses [Prettier](https://prettier.io/) to maintain consistent code formatting for both XQuery and JavaScript files. Formatting is automatically checked in CI on every push and pull request.

### Supported File Types

- **XQuery files**: `.xq`, `.xql`, `.xqm`, `.xquery` (using [prettier-plugin-xquery](https://github.com/DrRataplan/prettier-plugin-xquery))
- **JavaScript files**: `.js`

### Local Usage

Install dependencies:
```bash
npm install
```

Check formatting:
```bash
npm run format:check
```

Auto-format files:
```bash
npm run format:write
```

Check only for errors (suppresses formatting warnings):
```bash
npm run format:check:errors
```

### CI Integration

The GitHub Actions workflow (`.github/workflows/format-check.yml`) automatically runs Prettier checks on:
- All pushes to `master`/`main` branches
- All pull requests targeting `master`/`main` branches

The CI will fail if files are not properly formatted, ensuring code style consistency across the project.

### Configuration

- Configuration file: `.prettierrc.js`
- Ignored files: `.prettierignore`
- Uses tabs for indentation
- Print width: 120 characters

Note: Some XQuery files using eXist-db specific update syntax (e.g., `update insert`, `update value`) are excluded from formatting checks due to parser limitations. These are listed in `.prettierignore`.
