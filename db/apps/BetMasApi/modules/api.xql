xquery version "3.1" encoding "UTF-8";

(:~
 : roaster OpenAPI router entry point. Routes requests according to api.json,
 : resolving each operationId to a function in one of the imported modules.
 :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/api" at "../local/rest.xqm";
import module namespace apiL = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiLists" at "../local/apilists.xqm";
import module namespace apiLx = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiListsX" at "../local/apilistsXML.xqm";
import module namespace apiS = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiSearch" at "../local/apiSearch.xqm";
import module namespace apiT = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiTexts" at "../local/apiText.xqm";
import module namespace apiTit = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiTitles" at "../local/apiTitles.xqm";
import module namespace apisparql = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apisparql" at "../local/sparqlRest.xqm";
import module namespace att = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/att" at "../local/attestations.xqm";
import module namespace chojnacki = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/chojnacki" at "../local/chojnacki.xqm";
import module namespace clavis = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/clavis" at "../local/clavis.xqm";
import module namespace enrich = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/enrich" at "../local/enrichSdCtable.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/places" at "../local/places.xqm";
import module namespace quotations = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/quotations" at "../local/quotations.xqm";
import module namespace roles = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/roles" at "../local/roles.xqm";
import module namespace SK = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/SK" at "../local/sharedKeywords.xqm";
import module namespace WC = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/WC" at "../local/wordCount.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/dts" at "../specifications/dts.xqm";
import module namespace dtsXML = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/dtsXML" at "../specifications/dtsXML.xqm";
import module namespace iiif = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/iiif" at "../specifications/iiif.xqm";
import module namespace jsonapi = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/jsonapi" at "../specifications/json.xqm";
import module namespace persdts = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/persdts" at "../specifications/persistentdts.xqm";
import module namespace persiiif = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/persiiif" at "../specifications/persistentiiif.xqm";
import module namespace shine = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/shine" at "../specifications/shine.xqm";
import module namespace void = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/void" at "../specifications/void.xqm";

declare function local:lookup($name as xs:string) {
	function-lookup(xs:QName($name), 1)
};

roaster:route(("api.json"), local:lookup#1)
