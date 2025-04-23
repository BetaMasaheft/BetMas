xquery version "3.1";

let $modules := (
(:restviews:)
xs:anyURI("/db/apps/BetMasWeb/restviews/collatex.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/compare.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/genderInfo.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/idlookup.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/ids.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/items.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/list.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/litcompare.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/LitFlowRest.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/permanentItems.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/viewer.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/workmap.xqm"),
xs:anyURI("/db/apps/BetMasWeb/restviews/user.xqm"),

(:BetMasAPI local:)
xs:anyURI("/db/apps/BetMasApi/local/apilists.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/apiSearch.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/apiText.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/apiTitles.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/attestations.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/chojnacki.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/clavis.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/enrichSdCtable.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/nodesAndEdges.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/places.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/quotations.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/rest.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/roles.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/search.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/sharedKeywords.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/sparqlRest.xqm"),
xs:anyURI("/db/apps/BetMasApi/local/wordCount.xqm"),


(:BetMasAPI specifications:)
xs:anyURI("/db/apps/BetMasApi/specifications/dts.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/dtsXML.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/iiif.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/json.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/persistentdts.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/persistentiiif.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/shine.xqm"),
xs:anyURI("/db/apps/BetMasApi/specifications/void.xqm")
)
for $module in $modules
return
(
exrest:deregister-module($module),
exrest:register-module($module)
)



(:other RestXQ modules:)
(:
xs:anyURI("/db/apps/gez-en/modules/rest.xqm"),
xs:anyURI("/db/apps/parser/modules/morphoparser.xqm")
:)