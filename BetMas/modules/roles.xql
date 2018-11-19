
xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace roles = "https://www.betamasaheft.uni-hamburg.de/BetMas/roles";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";


(:~ given a role, search other attestations of it and print the persName around them and related infos :) 
declare
%rest:GET
%rest:path("/BetMas/api/RoleAttestations")
%rest:query-param("role", "{$role}", "")
%output:method("html")
function roles:RoleAttestations($role  as xs:string*){
($config:response200,
let $r :=$role
let $q := <query><fuzzy min-similarity="0.8">{$r}</fuzzy></query>
let $roleAttestations := collection($config:data-rootMS, $config:data-rootW)//t:roleName[ft:query(., $q)]
let $roleAttestationsIdentified := $roleAttestations[parent::t:persName]

let $results := for $atttestation in $roleAttestations/parent::t:persName
                                let $id := $atttestation/@ref
                                group by $ID := $id
     let $roles := 
           for $rol in $atttestation 
           let $type := $rol/t:roleName/@type 
           group by $RT :=$type  
           let $atts := for $ratt in $rol 
                                   let $text := $ratt/t:roleName/text()
                                   group by $T := $text
                                   let $sources := for $rat in $ratt 
                                                                let $root := string(root($rat)/t:TEI/@xml:id) 
                                                                group by $ROOT := $root
                                                                let $occurrences := for $occurr in $rat
                                                                let $f := string($occurr/@notBefore)
                                                                 let $t := string($occurr/@notAfter)
                                                                 let $anchor := if($occurr/ancestor::t:body) then let $parent := $occurr/ancestor::t:*[@n][1] return ($parent/name() ||'_' || string($parent/@n)) else string($occurr/ancestor::t:*[@xml:id][1]/@xml:id)
                                                                                                         return 
                                                                                                         <div class="col-md-9">
                                                                                                         <div class="col-md-4">from: {$f}</div>
                                                                                                         <div class="col-md-4">to: {$t}</div>
                                                                                                         <div class="col-md-4">in: {$anchor}</div>
                                                                                                         </div>
                                                                                                            
                                                                return
                                                                <div class="col-md-9">
                                                                <div class="col-md-3"><a href="/{$ROOT}" class="MainTitle" data-value="{$ROOT}">{$ROOT} <span class="badge">{count($occurrences)}</span></a></div>
                     {for $occ in $occurrences return $occ}
                     </div>
                                  return 
                                   <div class="col-md-10">
                                   <div class="col-md-3">{$T} <span class="badge">{count($sources)}</span></div>
                     {for $sour in $sources return $sour}
                     </div>
           return
           <div class="col-md-10">
           <div class="col-md-2">{string($RT)} <span class="badge">{count($atts)}</span></div>
                     {for $att in $atts return $att}
                     </div>
                      return
                     <div class="row">
                     <div class="col-md-2"><a href="/{string($ID)}" class="MainTitle" data-value="{string($ID)}">{string($ID)} <span class="badge">{count($roles)}</span></a></div>
                     {for $role in $roles return $role}
                     </div>
                     
return
<div class="col-md-12">
<p>There are in total {count($roleAttestationsIdentified)} attestations of the role name <span class="label label-success">{$r}</span> related to {count(distinct-values($roleAttestations/parent::t:persName/@ref))} persons.</p>
{for $result in $results return$result}
</div>
)
};