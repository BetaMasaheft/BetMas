

xquery version "3.1" encoding "UTF-8";
(:~
 : lists from API
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace apiL = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiLists";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";


(:~ returns a json object with an array of object one for each resource in the specified collection :)
declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list/json")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%rest:query-param("repo", "{$repo}", "")
%output:method("json")
function apiL:collectionJSON($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*, $repo as xs:string*) {
    
let $log := log:add-log-message('/api/'||$collection||'/list/json', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
         ( $config:response200Json,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
          let $repo := if ($repo != '') then
        ("[descendant::t:repository/@ref = '" || $repo || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", $repo, $term)

let $hits := util:eval($path)

return
    <json:value>
        <items>
            {
                for $resource in subsequence($hits, $start, $perpage)
                let $rid := $resource/@xml:id
                let $rids := string($rid)
                let $title := titles:printTitleMainID($rid)
                order by $title[1] descending
                return
                    <json:value
                        json:array="true">
                        <id>{$rids}</id>
                        <title>{$title}</title>
                        {
                        element item {
                                element uri {base-uri($resource)},
                                element name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                                element type {string($resource/@type)},
                                switch ($resource/@type)
                                    case 'mss'
                                        return
                                            (
                                            element support {
                                                for $r in $resource//@form
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element institution {
                                                for $r in $resource//t:repository/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element script {
                                                for $r in $resource//@script
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element material {
                                                for $r in $resource//t:support/t:material/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element content {
                                                for $r in $resource//t:title/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element scribe {
                                                for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element donor {
                                                for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element patron {
                                                for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'pers'
                                        return
                                            (element occupation {
                                                for $r in $resource//t:occupation
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element role {
                                                for $r in $resource//t:person/t:persName/t:roleName
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element gender {$resource//t:person/@sex})
                                    case 'place'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    
                                    case 'ins'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            })
                                    case 'work'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element witness {
                                                for $r in $resource//t:witness/@corresp
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'narr'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    default return
                                        ()
                        }
                    }
                </json:value>
        }
    
    </items>
    <total>{count($hits)}</total>
</json:value>)
};


(:~ returns a json object with an array of object one for each resource in the specified repository with id and title :)
declare
%rest:GET
%rest:path("/BetMas/api/manuscripts/{$repo}/list/ids/json")
%output:method("json")
function apiL:listRepoJSON($repo as xs:string*) {
    
let $log := log:add-log-message('/api/manuscripts/'||$repo||'/list/ids/json', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
         ( $config:response200Json,
    let $msfromrepo := collection($config:data-rootMS)//t:TEI[descendant::t:repository[@ref = $repo]]
    let $total := count($msfromrepo) 
   let $items :=  for $resource in $msfromrepo 
    let $id := string($resource/@xml:id)
    let $title :=  titles:printTitleMainID($id)
    return map {'id' := $id, 'title' := $title}
    return 
    map {'items' := $items,
    'total' := $total}
    )
};


(:~ returns a json object with an array of object one for each resource in the specified collection :)
declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%output:method("xml")
%test:args('manuscripts', '1', '20', 'GoldenGospel') %test:assertXPath('/','item')
function apiL:collection($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*) {
    if ($perpage gt 100) then ($config:response200XML, <info>Try a lower value for the parameter perpage. Maximum is 100.</info>) else
let $log := log:add-log-message('/api/' || $collection || '/list', xmldb:get-current-user(), 'REST')
    (: logs into the collection :)
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
        ( $config:response200XML,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'personsNoEthnic'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", if($collection='personsNoEthnic') then "[starts-with(@xml:id, 'PRS')]" else (), $term)

let $hits := util:eval($path)

return
    
    
    <items>
        {
            for $resource in subsequence($hits, $start, $perpage)
            let $title := titles:printTitleMainID(string($resource/@xml:id))
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
                                    for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute donor {
                                    for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute patron {
                                    for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
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
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
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
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
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
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                },
                                attribute witness {
                                    for $r in $resource//t:witness/@corresp
                                    return
                                        string($r) || ' '
                                })
                        case 'narr'
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
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                })
                        default return
                            (),
                $title
            }
    }
    <total>{count($hits)}</total>
</items>)

};

