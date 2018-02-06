xquery version "3.0" encoding "UTF-8";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace site="http://exist-db.org/apps/site-utils";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace apidoc="https://www.betamasaheft.uni-hamburg.de/BetMas/apidoc" at "apidocumentation.xql";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace new="https://www.betamasaheft.uni-hamburg.de/BetMas/new" at "newEntry.xqm";
import module namespace rels="https://www.betamasaheft.uni-hamburg.de/BetMas/rels" at "relations.xqm";
import module namespace lists="https://www.betamasaheft.uni-hamburg.de/BetMas/lists"at "resources.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMas/timeline"at "timeline.xqm";


declare namespace saxon="http://saxon.sf.net/"; 
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "xhtml";
declare option output:omit-xml-declaration "no";
declare option saxon:output "omit-xml-declaration=no";
declare option output:media-type "text/html";


let $config := map {
    $templates:CONFIG_APP_ROOT := $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR := true()
}

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
return
    templates:apply($content, $lookup, (), $config)