xquery version "3.1" encoding "UTF-8";
(:~
 : early test implementation of the https://github.com/distributed-text-services
 : SERVER
 : @author Pietro Liuzzo 
:)
module namespace dtsXML="https://www.betamasaheft.uni-hamburg.de/BetMas/dtsXML";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare option output:method "json";
declare option output:indent "yes";


(:the old ones, still in use. :)

(:~bespoke json format, former dts proposal draft, returns a list:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/collections/{$id}")
%output:method("json")
function dtsXML:CollectionsID($id as xs:string*) {
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    return
  
        ($config:response200Json,
        
 log:add-log-message('/api/dts/collections/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
    <json:value>
        <context>
        <perseus>http://perseus.org/terms</perseus>
   <rdf>http://www.w3.org/1999/02/22-rdf-syntax-ns#</rdf>
    <dts>http://ontology-dts.org/terms</dts>
    <saws>http://purl.org/saws/ontology</saws>
    <snap>http://data.snapdrgn.net/ontology/snap</snap>
    <dcterms>http://purl.org/dc/terms</dcterms>
    <bm>{$config:appUrl}/</bm>
    <ecrm>http://erlangen-crm.org/current/</ecrm>
    <tei>http://www.tei-c.org/ns/1.0</tei>
    </context>
    <graph>{
            let $record := $config:collection-root/id($id)[name()='TEI']
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
                <id>{$config:appUrl}/{$id}</id>
                <id>{$config:appUrl}/api/{$id}/tei</id>
                <id>{$config:appUrl}/api/{$id}/json</id>
                   
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
                            let $papa := $config:collection-root/id($parent)[name()='TEI']
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


(:~ returns the short title for citations or the main one:)
declare function dtsXML:citation($item as node()){
if($item//t:titleStmt/t:title[@type='short']) 
then $item//t:titleStmt/t:title[@type='short']/text() 
else $item//t:titleStmt/t:title[@xml:id = 't1']/text()
};


(:~The following function retrive the text of the selected work and returns
: it with basic informations for next and following into a small JSON tree 
returns the lines of the second level of subdivision (subchapters) e.g. 
XXX. 1 
XXX. 1 

:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}")
%output:method("json")
function dtsXML:get-workJSON($id as xs:string) {
    ($config:response200Json,
 log:add-log-message('/api/dts/text/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    return
        if ($item//t:div[@type = 'edition'])
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{dtsXML:citation($item)}</citation>
                <text>{let $t := string-join($item//t:div[@type = 'edition']//text(), ' ') return normalize-space($t)}</text>
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl||'/api/dts/' || $id || '/' || $subtype/@n)}
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


(:~returns the lines of the second level of subdivision (subchapters) e.g.
XXX. 2, 4
XXX. 2, 4-7
:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}")
%output:method("json")
function dtsXML:get-toplevelJSON($id as xs:string, $level1 as xs:string*) {
    ($config:response200Json,
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    return
        if ($L1)
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dtsXML:citation($item) || ' ' || $level1)}</citation>
                <text>{let $t := string-join($L1//text(), ' ') return normalize-space($t)}</text>
                {
                    if (number($level1) > 1 and $item//t:div[@type = 'edition']/t:div[@n = (number($level1) - 1)])
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{number($level1) - 1}</previous>
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
                            <next>{$config:appUrl}/api/dts/{$id}/{number($level1) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
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

(:~returns the lines of the first level of subdivision (chapters):)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$line}")
%output:method("json")
function dtsXML:get-level1JSON($id as xs:string, $level1 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1||'/'||$line, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    
    return
        if (contains($line, '-'))
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dtsXML:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        let $thisline := $L1//t:l[@n = string($l)]
                        let $t := string-join($thisline//text(), ' ')
                            
                        return
                            normalize-space($t)
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{number(substring-before($line, '-')) - 1}</previous>
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
                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1//t:*[@n]
                            return
                                
                                element {$subtype/name()} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}</partofchapter>
            
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
                    <citation>{(dtsXML:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                    <title>{let $t := $item//t:titleStmt return $t/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{normalize-space($onlytext)}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{number($line) - 1}</previous>
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
                                <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{number($line) + 1}</next>
                            else
                                ()
                    }
                    <contains><json:value
                            json:array="true">
                            {
                                for $subtype in $L1//t:*[@n]
                                return
                                    
                                    element {$subtype/name()} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                            }
                        </json:value>
                    </contains>
                    <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}</partofchapter>
                    <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
                
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


(:~returns the lines of the second level of subdivision (chapters):)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$level2}/{$line}")
%output:method("json")
function dtsXML:get-level2JSON($id as xs:string, $level1 as xs:string*, $level2 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1||'/'||$level2||'/'||$line, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    let $L2 := $L1/t:div[@n = $level2]
    return
        if (contains($line, '-'))
        then
            
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dtsXML:citation($item) || ' ' || $level2 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            normalize-space($L2//t:l[@n = string($l)]//text())
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number(substring-before($line, '-')) - 1}</previous>
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
                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                <partofbook>{$config:appUrl}/api/dts/{$id}/{$level1}</partofbook>
                
                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
            
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
                                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number($line) - 1}</previous>
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
                                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number($line) + 1}</next>
                                        else
                                            ()
                                }
                                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                                <partofbook>{$config:appUrl}/api/dts/{$id}/{$level1}</partofbook>
                                
                                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
                            
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

