xquery version "3.1" encoding "UTF-8";
(:~
 : lists from API
 : 
 : @author Pietro Liuzzo 
 :)
module namespace apiLx = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiLists";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace http="http://expath.org/ns/http-client";
import module namespace console="http://exist-db.org/xquery/console";

(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.w3.org/2013/XSL/json";
declare namespace test="http://exist-db.org/xquery/xqsuite";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";


(:~ returns a json object with an array of object one for each resource in the specified collection :)
declare
%rest:GET
%rest:path("/api/{$collection}/list/xml")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
function apiLx:collection($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*) {
    (:if ($perpage gt 100) 
            then ($config:response200XML, <info>Try a lower value for the parameter perpage. Maximum is 100.</info>) 
    else:)
     
    let $test := console:log('got here')
    let $log := log:add-log-message('/api/' || $collection || '/list', sm:id()//sm:real/sm:username/string() , 'REST')
    (: logs into the collection 
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw):)
     let $term := if ($term != '') then
             ("[descendant::t:term/@key eq '" || $term || "' ]")
      else
        ''
       let $collecPath := switch2:collection($collection)

      let $path := concat($collecPath, "//t:TEI", if($collection='personsNoEthnic') then "[starts-with(@xml:id, 'PRS')]" else (), $term)

     let $hits := util:eval($path)
    return
        ( $config:response200XML,
         <items>
        {
            for $resource in subsequence($hits, $start, $perpage)
            let $title := exptit:printTitleID(string($resource/@xml:id))
            order by $title[1] descending
            return
           
                element item {
                    attribute uri {base-uri($resource)},
                    attribute name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                    attribute id {string($resource/@xml:id)},
                    attribute type {string($resource/@type)},
                    switch ($resource/@type)
                        case 'mss'
                            return
                                (
                                attribute support {
                                    for $r in $resource//@form
                                    return
                                        string($r) || ' '
                                },
                                attribute institution {
                                    for $r in $resource//t:repository/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute script {
                                    for $r in $resource//@script
                                    return
                                        string($r) || ' '
                                },
                                attribute material {
                                    for $r in $resource//t:support/t:material/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute content {
                                    for $r in $resource//t:title/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute scribe {
                                    for $r in $resource//t:persName[@role eq 'scribe']/@ref[not(. eq 'PRS00000') and not(. eq 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute donor {
                                    for $r in $resource//t:persName[@role eq 'donor']/@ref[not(. eq 'PRS00000') and not(. eq 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute patron {
                                    for $r in $resource//t:persName[@role eq 'patron']/@ref[not(. eq 'PRS00000') and not(. eq 'PRS0000')]
                                    return
                                        string($r) || ' '
                                })
                        case 'pers'
                            return
                                (attribute occupation {
                                    for $r in $resource//t:occupation
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute role {
                                    for $r in $resource//t:person/t:persName/t:roleName
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute gender {$resource//t:person/@sex})
                        case 'place'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type eq 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'ins'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type eq 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'work'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name eq "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name eq "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                },
                                attribute witness {
                                    for $r in $resource//t:witness/@corresp
                                    return
                                        string($r) || ' '
                                })
                        case 'nar'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name eq "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name eq "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                })
                        default return
                            (),
                $title
            }
    }
     <total>{count($hits)}</total>
</items>
)
};

