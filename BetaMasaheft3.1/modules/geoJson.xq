xquery version "3.0" encoding "UTF-8";

declare namespace t="http://www.tei-c.org/ns/1.0";

import module namespace BetMasMap = "http://www.exist-db.org/book/namespaces/betmas" at "map.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";


let $item := request:get-parameter('uri',())
let $collection := request:get-parameter('collection',())
return

        doc(concat(($config:data-root),'/', $collection,'/',$item,'.xml'))/t:TEI

