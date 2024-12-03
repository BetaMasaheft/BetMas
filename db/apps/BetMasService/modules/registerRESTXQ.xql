xquery version "3.1";


(:restviews:)
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/collatex.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/compare.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/genderInfo.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/idlookup.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/ids.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/items.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/list.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/litcompare.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/LitFlowRest.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/permanentItems.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/viewer.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/workmap.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasWeb/restviews/user.xqm")),

(:BetMasAPI local:)
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/apilists.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/apiSearch.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/apiText.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/apiTitles.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/attestations.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/chojnacki.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/clavis.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/enrichSdCtable.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/nodesAndEdges.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/places.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/quotations.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/rest.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/roles.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/search.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/sharedKeywords.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/sparqlRest.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/local/wordCount.xqm")),


(:BetMasAPI specifications:)
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/dts.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/dtsXML.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/iiif.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/json.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/persistentdts.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/persistentiiif.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/shine.xqm")),
exrest:register-module(xs:anyURI("/db/apps/BetMasApi/specifications/void.xqm"))


(:other RestXQ modules:)
(:
exrest:register-module(xs:anyURI("/db/apps/gez-en/modules/rest.xqm")),
exrest:register-module(xs:anyURI("/db/apps/parser/modules/morphoparser.xqm"))
:)