xquery version "3.1";

module namespace gfb = "https://www.betamasaheft.uni-hamburg.de/BetMas/gfb";
import module namespace http = "http://expath.org/ns/http-client";
declare namespace b = "betmas.biblio";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare variable $gfb:ethiostudies := 'https://api.zotero.org/groups/358366/items' ;

(:   NEEDS POSTPROCESSING: THE ZOTERO OUTPUT as ESCAPED HTML

replace &lt;i&gt; and &lt;/i&gt; with proper tags:)

declare function gfb:zot($c) {
    let $xml-url-formattedBiblio := concat($gfb:ethiostudies,'?tag=', $c, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies-with-url-doi&amp;linkwrap=1')
(:    let $log := util:log('INFO', $xml-url-formattedBiblio):)
   let $data := try{let $request := <http:request href="{xs:anyURI($xml-url-formattedBiblio)}" method="GET"/>
                               return http:send-request($request)[2]} catch *{$err:description}
    let $log2 := util:log('INFO', $data)
    let $datawithlink := $data//*:div[@class = 'csl-entry']
    return
        $datawithlink
};

declare function gfb:shortCit($c){
 let $xml-url := concat($gfb:ethiostudies,'?tag=', $c, '&amp;include=citation&amp;style=hiob-ludolf-centre-for-ethiopian-studies-with-url-doi&amp;locale=en-GB')
 let $log := util:log('INFO', $xml-url)
            let $req :=
            <http:request
                http-version="1.1"
                href="{xs:anyURI($xml-url)}"
                method="GET">
            </http:request>

            let $zoteroApiResponse := http:send-request($req)[2]
            let $decodedzoteroApiResponse := util:base64-decode($zoteroApiResponse)
            let $parseedZoteroApiResponse := parse-json($decodedzoteroApiResponse)
            let $replaced := replace($parseedZoteroApiResponse?*?citation, '&lt;span&gt;', '') => replace('&lt;/span&gt;', '')
            return
                $replaced
                };

declare function gfb:updateentry($ref){
<entry xmlns="betmas.biblio" id="{$ref}">
     <citation>{ try{gfb:shortCit($ref)} catch * {util:log('INFO', ($ref, $err:description))}}</citation>
      <reference>{try{gfb:zot($ref)} catch * {util:log('INFO', ($ref, $err:description))} }</reference>
 </entry>
};

declare function gfb:entry($cit, $ref){
<entry xmlns="betmas.biblio" id="{$ref}">
     <citation>{$cit}</citation>
      <reference>{try{gfb:zot($ref)} catch * {util:log('INFO', ($ref, $err:description))} }</reference>
 </entry>
};


(: given a collection parses all the ptr/@target and makes a bibliography.xml file with all the results of consecutive iterative requests:)
declare function gfb:updateBib($context) {
let $bibliography := doc('/db/apps/lists/bibliography.xml')/b:bibliography
let $ptrs := collection("/db/apps/BetMasData")//t:bibl/t:ptr[starts-with(@target, 'bm:')]
let $citations := distinct-values($ptrs/@target)
let $cleancitations := for $c in $citations return replace($c, '\s+', '')
 for $rawc in $cleancitations
(: let $testrawc := util:log('INFO', $rawc):)
let $match := $bibliography//b:entry[@id=$rawc]
(: let $testmatch := util:log('INFO', $match):)
 return
 if (count($match) ge 1)
 then ((:update the entry:)
 util:log('INFO', ('entry for ' || $rawc || 'already exists'))
 ) 
 else 
 let $test := util:log('INFO', ($rawc || ' is not in bibliography, adding entry '))
(: let $total := util:log('INFO', $bibliography/b:total):)
 let $entry := gfb:updateentry($rawc)
 
let $update := if($entry/b:citation[not(text())] or $entry/b:reference[not(text())]) then util:log('WARN', $entry) else update insert $entry into $bibliography/b:entries
let $updatetotal := update value $bibliography/b:total with count($cleancitations)
(: add the entry:)
return
util:log('INFO', ('added entry for ' || $rawc))

};

(: given a collection parses all the ptr/@target and makes a bibliography.xml file with all the results of consecutive iterative requests:)
declare function gfb:makeBib($collection) {
let $ptrs := $collection//t:bibl/t:ptr[starts-with(@target, 'bm:')]
let $citations := distinct-values($ptrs/@target)
let $cleancitations := for $c in $citations return replace($c, '\s+', '')
let $bibliography :=
<bibliography
    xmlns="betmas.biblio"><total>{count($citations)}</total>
    <entries>{
            for $rawc in $cleancitations
            let $c := replace($rawc, '\s', '') 
            let $shortCit := try{gfb:shortCit($c)} catch * {util:log('INFO', ($c, $err:description))}
               group by $shortCit
                order by $shortCit
            return
                if ($shortCit = '' or $shortCit = ' ') then
                    for $sameCit in $rawc
                    let $cit := "EMPTY! WRONG POINTER!"
                    return
                        gfb:entry($cit, $sameCit)
                else
                    if (count($c) gt 1) then
                        for $sameCit at $p in $rawc
                        let $letters := ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'l', 'm', 'n', 'o')
                        let $cit := $shortCit||$letters[$p]
                        return
                        gfb:entry($cit, $sameCit)
                else
                        for $sameCit in $rawc
                        return
                        gfb:entry($shortCit, $sameCit)
        }
    </entries>
</bibliography>



let $store:=    xmldb:store('/db/apps/lists', 'bibliography.xml', $bibliography)
let $stored:= '/db/apps/lists/bibliography.xml'
let $permission := (sm:chgrp($stored, 'Cataloguers'), sm:chmod($stored, 'rwxrwxrwx'))  
let $message :='stored ' || $stored
return 
util:log('INFO', $message)
};

