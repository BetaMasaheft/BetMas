# Migrate BetaMasaHeft to new server

## Loading data

Most data is on GitHub, except expanded data, lists and Dillmann

### Loading application

 * Take the apps from latest production. there might have been changes
   * Use eXide Application/Download app for the following items:
	 * /db/apps/BetMas
	 * /db/apps/BetMasApi
	 * /db/apps/BetMasService
	 * /db/apps/BetMasWeb
	 * /db/apps/DillmannData
	 * /db/apps/EthioStudies
	 * /db/apps/alpheiosannotations
	 * /db/apps/gez-en
	 * /db/apps/guidelines
	 * /db/apps/lists
	 * /db/apps/parser
   * Extract and place into [BetMas](https://github.com/BetaMasaheft/BetMas)
   * Rebase fixing commits over it: [BetMas#exist-6.x](https://github.com/BetaMasaheft/BetMas/tree/exist-6.x)
 * Deploy them
 * Update app url
   * edit /db/apps/BetMasWeb/modules/loc.xqm to read the correct app url
 * Register RestXQ stuff:
   * call `/db/apps/BetMasService/modules/registerRESTXQ.xql`
   * http://116.202.114.60:8081/exist/apps/BetMasService/modules/registerRESTXQ.xql

### Loading data

Take and deploy from GitHub:

 * [authority-files](https://github.com/BetaMasaheft/authority-files)
 * [corpora](https://github.com/BetaMasaheft/corpora)
 * [institutions](https://github.com/BetaMasaheft/institutions)
 * [manuscripts](https://github.com/BetaMasaheft/manuscripts)
 * [narratives](https://github.com/BetaMasaheft/narrative)
 * [persons](https://github.com/BetaMasaheft/persons)
 * [places](https://github.com/BetaMasaheft/places)
 * [studies](https://github.com/BetaMasaheft/studies)
 * [works](https://github.com/BetaMasaheft/works)

**Chojnacki does not seem to be used in the end!** VERIFY THO


### Install additional things

* At least https://iipimage.sourceforge.io/ is used in production now to host IIIF images

### Loading expanded content

Expanded content is too large to download through the normal way. Instead, it needs to be downloaded through exide. This XQuery script can do that:

```xquery
xquery version "3.1";

let $file-system-target-base-directory :=
    '/media/add/expanded-data-dump'
let $source-collection := '/db/apps/expanded'
for $doc in collection($source-collection)
let $target :=
    (: Put the files into a corresponding directory in the file system :)
    concat($file-system-target-base-directory, replace(base-uri($doc), '/', '\\'))
return
    file:serialize($doc, $target, ("omit-xml-declaration=yes", "indent=yes"))
```

After that, rsync it to local:

```
scp -r bmadmin@betamasaheft2.aai.uni-hamburg.de:/media/add/expanded-data-dump/expanded-data-dump .
```

Finally deploy it:

```
deploy-expanded.sh
```

### Indexing

Touch /db/apps/expanded/collection.xconf

## Permissions

Fix the permissons for everything in `/db/apps/lists`. They need to be world-writable.
