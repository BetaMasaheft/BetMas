
xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace roles = "https://www.betamasaheft.uni-hamburg.de/BetMas/roles";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

declare namespace test="http://exist-db.org/xquery/xqsuite";

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
let $roleAttestations := ($config:collection-rootMS, $config:collection-rootW)//t:roleName[ft:query(., $q)]
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



(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/BetMas/api/hasrole/{$role}")
%output:method("json")
%test:arg('role', 'donor') %test:assertExists
%test:arg('role', 'scribe') %test:assertExists
function roles:role($role as xs:string*) {

let $log := log:add-log-message('/api/hasrole/' || $role, xmldb:get-current-user(), 'REST')
let $cp := $config:collection-rootPr
let $path :=  $config:collection-root//t:persName[@role = $role][@ref[not(starts-with(. ,'PRS0000'))][. != 'PRS0476IHA'][. != 'PRS0204IHA']]
let $total := count($path)
let $hits := for $pwl in $path
                    let $id := string($pwl/@ref)
                   
                    group by $ID := $id
            
        return
            map {
                'pwl' : $ID,
                'title' : titles:printTitleMainID($ID),
                'hits' : count($pwl)
                    }

return 
     ( $config:response200Json,
map {
'role' := $role,
'hits' := $hits,
'total' := count($hits),
'referring' := $total
})
};


(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/BetMas/api/hasrole/{$role}/{$ID}")
%output:method("json")
%test:arg('role', 'donor') %test:assertExists
%test:arg('role', 'scribe') %test:assertExists
function roles:roleID($role as xs:string*, $ID as xs:string*) {

let $log := log:add-log-message('/api/hasrole/' || $role, xmldb:get-current-user(), 'REST')
let $path :=  $config:collection-root//t:persName[@role = $role][@ref=$ID]
let $hits := for $x in $path
                        let $root := string(root($x)/t:TEI/@xml:id)
                        group by $r := $root
                    return
                        map {
                            'prov' : $r,
                            'sourceTitle' : titles:printTitleID($r),
                            'count' := count($x)
                            }
                    
let $hs := if (count($hits) gt 1) then $hits else [$hits]
 return
             ( $config:response200Json,
            map {
                'pwl' : $ID,
                'title' : titles:printTitleMainID($ID),
                'hits' : count($path),
                'hasthisrole' : $hs    
                    }
)
};
