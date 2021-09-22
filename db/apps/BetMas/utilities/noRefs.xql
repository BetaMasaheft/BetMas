xquery version "3.0";
(:~
 :this is a module requested by the user where a query is run to find out which entries and id are never referred to in a given collection 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
import module namespace apprest="https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";

for $item in collection($config:data-rootMS)//t:TEI
let $all := collection($config:data-root)
let $id := string($item/@xml:id)
let $pointHere := apprest:WhatPointsHere($id, $all)
return
if($pointHere = '') then $id else ()