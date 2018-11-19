xquery version "3.0" encoding "UTF-8";
(:~ 
 : the geoJson transformation is launched in the controller. 
 : the controller points to this module to retrieve the file and has the link to the xslt to transform the content returned here
 :)
declare namespace t="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";


let $item := request:get-parameter('uri',())
let $collection := request:get-parameter('collection',())
return

        doc(concat(($config:data-root),'/', $collection,'/',$item,'.xml'))/t:TEI

