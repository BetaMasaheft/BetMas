xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"   at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare option output:method "json";
declare option output:indent "yes";

declare
%rest:GET
%rest:path("/BetMas/api/dts/test")
%output:method("json")
function dts:dtstest() {
let $test :=
map {
    "@context": map {
        "dts": "http://example.org/dts-ontology/",
        "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#", 
        "saws" : "http://purl.org/saws/ontology",
        "tei": "http://www.tei-c.org/ns/1.0"
    },
    "@graph": map {
        "@id": "urn:dts:betmas:LIT1113Anqasa",
        "rdf:type": "work",
        "license": "http://creativecommons.org/licenses/by-sa/4.0/",
        "dt:size": "1",
        "@labels": map {
            "@value": "ʾAnqaṣa bǝrhān",
            "description": "The ʾAnqaṣa bǝrhān is a collection of hymns to be chanted on Sundays in praise of the \n            Blessed Virgin.\n            It is part of the Ethiopic psalter, copied following the . \n            Tradition ascribes its composition to St. Yāred."
        },
        "dts:metadata": map {"saws:isAttributedToAuthor": "Yāred"}
    }
}
return
$test
};

declare
%rest:GET
%rest:path("/BetMas/api/dts/cit")
%output:method("json")
function dts:Cit() {
 ($config:response200Json,
         <json:value>
         <documentation>Sorry, this one is not yet there at all!</documentation>
         </json:value>)
         
};

(: http://distributed-text-services.github.io/collection-api/#/:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/collections")
%rest:query-param("start", "{$start}", 1)
%output:method("json")
function dts:Collection($start as xs:integer*) {
    
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
       ($config:response200Json,
    <json:value>
        {
        <context>
        <dts>http://w3id.org/dts-ontology/</dts>
        <perseus>http://perseus.org/terms</perseus>
    <saws>http://purl.org/saws/ontology</saws>
    <snap>http://data.snapdrgn.net/ontology/snap</snap>
    <dcterms>http://purl.org/dc/terms</dcterms>
    <bm>http://betamasaheft.aai.uni-hamburg.de/</bm>
    <ecrm>http://erlangen-crm.org/current/</ecrm>
    <t>http://www.tei-c.org/ns/1.0</t>
    </context>,
    <graph>{
            let $cols := collection('/db/apps/BetMas/data/works')
            let $total := count($cols)
            return
                (<contents>
                    {
                        
                        for $child in subsequence($cols, $start, 20)
                        return
                            <json:value>
                                <id>urn:dts:betmas:{string($child/t:TEI/@xml:id)}</id>
                                <type>{string($child/t:TEI/@type)}</type>
                                <labels>
                                            {
                                                for $lang in $child//t:language
                                                return
                                                    <lang>
                                                        {string($lang/@ident)}</lang>
                                            }
                                        <value>{titles:printTitleMainID($child/t:TEI/@xml:id)}</value>
                                    
                                </labels>
                            </json:value>
                    }
                </contents>,
                <size>{$total}</size>,
                <current>{$start}-{($start+20)-1}</current>,
                if ($total > $start) then
                    (<next>
                        {$start + 20}-{($start + 40) - 1}
                    </next>,
                    if ($start > 20) then
                        <prev>
                            {$start - 20}-{$start - 1}
                        </prev>
                    else
                        ())
                else
                    ()
                )
                }</graph>
        }
    </json:value>
       )
};

declare
%rest:GET
%rest:path("/BetMas/api/dts/collections/{$id}")
%output:method("json")
function dts:CollectionsID($id as xs:string*) {
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    return
  
        ($config:response200Json,
    <json:value>
        <context>
        <perseus>http://perseus.org/terms</perseus>
   <rdf>http://www.w3.org/1999/02/22-rdf-syntax-ns#</rdf>
    <dts>http://ontology-dts.org/terms</dts>
    <saws>http://purl.org/saws/ontology</saws>
    <snap>http://data.snapdrgn.net/ontology/snap</snap>
    <dcterms>http://purl.org/dc/terms</dcterms>
    <bm>http://betamasaheft.aai.uni-hamburg.de/</bm>
    <ecrm>http://erlangen-crm.org/current/</ecrm>
    <tei>http://www.tei-c.org/ns/1.0</tei>
    </context>
    <graph>{
            let $record := collection($config:data-root)//($id)[name()='TEI']
            return
                (
                <id>urn:dts:betmas:{string($record/@xml:id)}</id>,
                <type>{string($record/@type)}</type>,
                <license>http://creativecommons.org/licenses/by-sa/4.0/</license>,
                <size>1</size>,
                <labels>
                            {
                                for $lang in $record//t:language
                                return
                                  <lang>     
                                     {  string($lang/@ident) }
                                 </lang>
                            }
                        <value>{titles:printTitleMainID($id)}</value>
                        <description>{$record//t:abstract//text()}</description>
                    </labels>,
                <vocabulary>http://purl.org/dc/elements/1.1/</vocabulary>,
                <capabilities>
                    <isOrdered>false</isOrdered>
                    <hasRoles>false</hasRoles>
                </capabilities>,
                <metadata>
                {if ($record//t:relation[@name='dcterms:creator']) then (element dcterms:creator{titles:printTitleMainID($record//t:relation[@name='dcterms:creator']/string(@passive))}) 
                else if ($record//t:relation[@name='saws:isAttributedToAuthor']) then (element saws:isAttributedToAuthor{titles:printTitleMainID($record//t:relation[@name='saws:isAttributedToAuthor']/string(@passive))})
                else if ($record//t:author) then <t:author>{$record//t:author/text()}</t:author> 
                else ()}
                </metadata>,
                
                <members>
                <id>http://betamasaheft.aai.uni-hamburg.de/{$id}</id>
                <id>http://betamasaheft.aai.uni-hamburg.de/api/{$id}/tei</id>
                <id>http://betamasaheft.aai.uni-hamburg.de/api/{$id}/json</id>
                   
                                <contents>
                        {  let $members := for $mem in ($record//t:relation/@passive) 
                                                     let $name := string($mem/parent::t:*/@name)
                                                     return 
                                                   
                                                     if (contains($mem, ' ')) then 
                                                      for $m in tokenize(normalize-space($mem), ' ')
                                                       return 
                                                       <rels><id>{$m}</id><n>{$name}</n></rels>
                                                     else
                                                       <rels><id>{data($mem)}</id><n>{$name}</n></rels>
                            for $part in distinct-values($members//id)
                           return
                            <json:value>
                                    <id>urn:dts:betmas:{string($part)}</id>
                                    <type>work</type>
                                    <mappings>
                                    <role>{$members//n[preceding-sibling::id = $part]/text()}</role>
                                    </mappings>
                                    </json:value>
                                  }
                                  </contents>
                </members>,
                
                <version>{
                            max($record//t:change/xs:date(@when))
                    }</version>,
                
                <parents><json:value
                            json:array="true"> {
                       let $parents := for $par in ($record//t:relation[@name = 'saws:formsPartOf']/@passive) 
                                                    return $par
                            for $parent in distinct-values($parents)
                            let $papa := collection($config:data-root)//id($parent)[name()='TEI']
                            return
                                
                                    (<id>urn:dts:betmas:{string($papa/@xml:id)}</id>,
                                    <type>{string($papa/@type)}</type>,
                                    <labels>
                    
                            {
                                for $lang in $papa//t:language
                                return
                                    
                                 <lang>     {  string($lang/@ident) }</lang>
                            }
                        
                        <value>{titles:printTitleMainID($parent)}</value>
                    
                </labels>
                                    )
                                  
                               
                        } </json:value>
                        
                </parents>
                )
                }</graph>
        
    </json:value>)
};


(:The following function retrive the text of the selected work and returns
it with basic informations for next and following into a small JSON tree

:)

declare function dts:citation($item as node()){
if($item//t:titleStmt/t:title[@type='short']) then $item//t:titleStmt/t:title[@type='short']/text() else $item//t:titleStmt/t:title[@xml:id = 't1']/text()};
(:returns the full first level subdivision

Ex. 1 

:)


declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}")
%output:method("json")
function dts:get-workJSON($id as xs:string) {
    ($config:response200Json,
    let $collection := 'works'
    let $item := collection($config:data-root)//id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    return
        if ($item//t:div[@type = 'edition'])
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{dts:citation($item)}</citation>
                <text>{let $t := string-join($item//t:div[@type = 'edition']//text(), ' ') return normalize-space($t)}</text>
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/dts/' || $id || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
            
            
            </json:value>
        
        else
            <json:value>
                <json:value
                    json:array="true">
                    <info>No results, sorry</info>
                </json:value>
            </json:value>
    )
};




(:returns the lines of the second level of subdivision (subchapters)

XXX. 1 

XXX. 1 

:)

declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}")
%output:method("json")
function dts:get-toplevelJSON($id as xs:string, $level1 as xs:string*) {
    ($config:response200Json,
    let $collection := 'works'
    let $item := collection($config:data-root)//id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    return
        if ($L1)
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level1)}</citation>
                <text>{let $t := string-join($L1//text(), ' ') return normalize-space($t)}</text>
                {
                    if (number($level1) > 1 and $item//t:div[@type = 'edition']/t:div[@n = (number($level1) - 1)])
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{number($level1) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($level1) = count($item//t:div[@subtype = 'book']))
                    then
                        ()
                    else
                        if ($item//t:div[@type = 'edition']/t:div[@n = (number($level1) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{number($level1) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofwork>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}</partofwork>
            </json:value>
        
        else
            <json:value>
                <json:value
                    json:array="true">
                    <info>No results, sorry</info>
                </json:value>
            </json:value>
    )
};



(:returns the lines of the second level of subdivision (subchapters)

XXX. 2, 4

XXX. 2, 4-7

:)




declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$line}")
%output:method("json")
function dts:get-level1JSON($id as xs:string, $level1 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    let $collection := 'works'
    let $item := collection($config:data-root)//id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
   let $test := console:log($L1)
    
    return
        if (contains($line, '-'))
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            (console:log($l), 
                            console:log($L1//t:l[@n=string($l)]),
                            normalize-space($L1//t:l[@n = string($l)]//text()))
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L1//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L1//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1//t:*[@n]
                            return
                                
                                element {$subtype/name()} {('http://betamasaheft.aai.uni-hamburg.de/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofchapter>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}</partofchapter>
            
            </json:value>
        else 
        let $ltext := $L1//t:l[@n = $line]
        return
            if ($ltext)
            then
           
            let $onlytext := string-join($ltext//text(), '')
            return
                <json:value
                    json:array="true">
                    
                    <id>{data($recordid)}</id>
                    <citation>{(dts:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                    <title>{let $t := $item//t:titleStmt return $t/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{normalize-space($onlytext)}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($ltext))
                        then
                            ()
                        else
                            if ($L1//t:l[@n = (number($line) + 1)])
                            then
                                <next>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{number($line) + 1}</next>
                            else
                                ()
                    }
                    <contains><json:value
                            json:array="true">
                            {
                                for $subtype in $L1//t:*[@n]
                                return
                                    
                                    element {$subtype/name()} {('http://betamasaheft.aai.uni-hamburg.de/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                            }
                        </json:value>
                    </contains>
                    <partofchapter>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}</partofchapter>
                    <partofwork>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}</partofwork>
                
                </json:value>
            
            
            else
                <json:value>
                    <json:value
                        json:array="true">
                        <info>No results, sorry</info>
                    </json:value>
                </json:value>
    )
};

(:returns the lines of the second level of subdivision (subchapters)

XXX. 1 2,4

XXX. 1 2, 4-7

:)


declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$level2}/{$line}")
%output:method("json")
function dts:get-level2JSON($id as xs:string, $level1 as xs:string*, $level2 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    let $collection := 'works'
    let $item := collection($config:data-root)//id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    let $L2 := $L1/t:div[@n = $level2]
    return
        if (contains($line, '-'))
        then
            
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level2 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            normalize-space($L2//t:l[@n = string($l)]//text())
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L2//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L2//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <partofchapter>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                <partofbook>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}</partofbook>
                
                <partofwork>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}</partofwork>
            
            </json:value>
        
        else
            if ($L2//t:l[@n = $line])
            then
                <json:value>
                    {
                        
                        let $recordid := $item/t:TEI/@xml:id
                        
                        return
                            <json:value
                                json:array="true">
                                <id>{data($recordid)}</id>
                                <text>{normalize-space($L2//t:l[@n = $line]//text())}</text>
                                {
                                    if (number($line) > 1)
                                    then
                                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}/{number($line) - 1}</previous>
                                    else
                                        ()
                                }
                                {
                                    if (number($line) = count($L2//t:l[@n = $line]))
                                    then
                                        ()
                                    else
                                        if ($L2//t:l[@n = (number($line) + 1)])
                                        then
                                            <next>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}/{number($line) + 1}</next>
                                        else
                                            ()
                                }
                                <partofchapter>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                                <partofbook>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}/{$level1}</partofbook>
                                
                                <partofwork>http://betamasaheft.aai.uni-hamburg.de/api/dts/{$id}</partofwork>
                            
                            </json:value>
                    }
                </json:value>
            else
                <json:value>
                    <json:value
                        json:array="true">
                        <info>No results, sorry</info>
                    </json:value>
                </json:value>
    )
};


