xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 :
 : @author Pietro Liuzzo 
 :)
module namespace restSearch = "https://www.betamasaheft.uni-hamburg.de/BetMas/restSearch";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~ given the filter name and the context, calls the function which will return a filter with options :)
declare

%rest:GET
%rest:path("/api/SearchFormParts/{$paraname}")
%rest:query-param("cont", "{$cont}", "$apprest:collection-rootMS")
%output:method("html5")
function restSearch:FormPart($paraname  as xs:string*, $cont as xs:string*)
{
<div class="form-group" id="authorsform">
        <label  for="{$paraname}">{$paraname}</label>
                {switch ($paraname)
case 'contents' return apprest:contents($cont)
case 'origPlace' return apprest:origPlace($cont)
case 'script' return apprest:scripts($cont)
case 'scribe' return apprest:scribes($cont)
case 'donor' return apprest:donors($cont)
case 'patron' return apprest:patrons($cont)
case 'owner' return apprest:owners($cont)
case 'binder' return apprest:binders($cont)
case 'ParMaker' return apprest:parmakers($cont)
case 'objecttype' return apprest:support($cont)
case 'material' return apprest:material($cont)
case 'bmaterial' return apprest:bmaterial($cont)
case 'tabots' return apprest:tabots($cont)
case 'placetype' return apprest:placeType($cont)
case 'authors' return apprest:WorkAuthors($cont)
default return ('not a valid name for a parameter')}
                </div>

};


