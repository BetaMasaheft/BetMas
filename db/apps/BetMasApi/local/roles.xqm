
xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace roles = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/roles";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";


(:~ given a role, search other attestations of it and print the persName around them and related infos :) 
declare
%rest:GET
%rest:path("/api/RoleAttestations")
%rest:query-param("role", "{$role}", "")
%output:method("html")
function roles:RoleAttestations($role  as xs:string*){
($config:response200,
let $r :=$role
let $q := <query><fuzzy min-similarity="0.8">{$r}</fuzzy></query>
let $roleAttestations := for $att in (collection($config:data-rootMS), collection($config:data-rootW))//t:TEI[ft:query(., $q)]  
                                            let $expanded := kwic:expand($att) 
                                         return $expanded//exist:match[parent::t:roleName]/parent::t:* 
let $roleAttestationsIdentified := $roleAttestations[parent::t:persName]

let $results := for $atttestation in $roleAttestations/parent::t:persName
                                let $id := $atttestation/@ref
                                group by $ID := $id
     let $roles := 
           for $rol in $atttestation 
           let $type := $rol/t:roleName/@type 
           group by $RT :=$type  
           let $atts := for $ratt in $rol 
                                   let $text := string-join($ratt/t:roleName/text())
                                   group by $T := $text
                                   let $sources := for $rat in $ratt 
                                                                let $root := string(root($rat)/t:TEI/@xml:id) 
                                                                group by $ROOT := $root
                                                                let $occurrences := for $occurr in $rat
                                                                let $f := string($occurr/@notBefore)
                                                                 let $t := string($occurr/@notAfter)
                                                                 let $anchor := if($occurr/ancestor::t:body) then let $parent := $occurr/ancestor::t:*[@n][1] return ($parent/name() ||'_' || string($parent/@n)) else string($occurr/ancestor::t:*[@xml:id][1]/@xml:id)
                                                                                                         return 
                                                                                                         <div class="w3-threequarter w3-padding">
                                                                                                         <div class="w3-third">from: {$f}</div>
                                                                                                         <div class="w3-third">to: {$t}</div>
                                                                                                         <div class="w3-third">in: {$anchor}</div>
                                                                                                         </div>
                                                                                                            
                                                                return
                                                                <div class="w3-threequarter">
                                                                <div class="w3-quarter"><a href="/{$ROOT}" class="MainTitle" data-value="{$ROOT}">{$ROOT} <span class="w3-tag w3-gray">{count($occurrences)}</span></a></div>
                     {for $occ in $occurrences return $occ}
                     </div>
                                  return 
                                   <div  class="w3-col" style="width:85%">
                                   <div class="w3-quarter">{$T} <span class="w3-tag w3-gray">{count($sources)}</span></div>
                     {for $sour in $sources return $sour}
                     </div>
           return
           <div  class="w3-col" style="width:85%">
           <div  class="w3-col" style="width:15%">{string($RT)} <span class="w3-tag w3-gray">{count($atts)}</span></div>
                     {for $att in $atts return $att}
                     </div>
                      return
                     <div class="w3-row">
                     <div class="w3-col" style="width:15%"><a href="/{string($ID)}" class="MainTitle" data-value="{string($ID)}">{string($ID)} <span class="w3-tag w3-gray">{count($roles)}</span></a></div>
                     {for $role in $roles return $role}
                     </div>
                     
return
<div class="w3-container">
<p>There are in total {count($roleAttestationsIdentified)} attestations of the role name <span class="w3-tag w3-gray">{$r}</span> related to {count(config:distinct-values($roleAttestations/parent::t:persName/@ref))} persons.</p>
{for $result in $results return$result}
</div>
)
};



(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/api/hasrole/{$role}")
%output:method("json")
%test:arg('role', 'donor') %test:assertExists
%test:arg('role', 'scribe') %test:assertExists
function roles:role($role as xs:string*) {

let $log := log:add-log-message('/api/hasrole/' || $role, sm:id()//sm:real/sm:username/string() , 'REST')
let $cp := collection($config:data-rootPr)
let $path :=  $exptit:col//t:persName[@role eq  $role][@ref[not(starts-with(. ,'PRS0000'))][. != 'PRS0476IHA'][. != 'PRS0204IHA']]
let $total := count($path)
let $hits := for $pwl in $path
                    let $id := string($pwl/@ref)
                   
                    group by $ID := $id
            
        return
            map {
                'pwl' : $ID,
                'title' : exptit:printTitleID($ID),
                'hits' : count($pwl)
                    }

return 
     ( $config:response200Json,
map {
'role' : $role,
'hits' : $hits,
'total' : count($hits),
'referring' : $total
})
};


(:~ returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given. :)
declare
%rest:GET
%rest:path("/api/hasrole/{$role}/{$ID}")
%output:method("json")
%test:args('patron', 'PRS2916Bruce') %test:assertExists
%test:args('owner', 'PRS2916Bruce') %test:assertExists
function roles:roleID($role as xs:string*, $ID as xs:string*) {
let $ID := if(starts-with($ID, 'https://betamasaheft.eu/')) then string($ID) else 'https://betamasaheft.eu/' || string($ID)
let $log := log:add-log-message('/api/hasrole/' || $role, sm:id()//sm:real/sm:username/string() , 'REST')
let $path :=  $exptit:col//t:persName[@role eq  $role][@ref eq $ID]
let $hits := for $x in $path
                        let $root := string(root($x)/t:TEI/@xml:id)
                        group by $r := $root
                    return
                        map {
                            'prov' : $r,
                            'sourceTitle' : exptit:printTitleID($r),
                            'count' : count($x)
                            }
                    
let $hs := if (count($hits) gt 1) then $hits else [$hits]
 return
             ( $config:response200Json,
            map {
                'pwl' : $ID,
                'title' : exptit:printTitleID($ID),
                'hits' : count($path),
                'hasthisrole' : $hs    
                    }
)
};
