xquery version "3.1" encoding "UTF-8";
(:~
 : module used by functions producing oa annoations for pelagios
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMas/ann";

declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "coordinates.xql";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace test="http://exist-db.org/xquery/xqsuite";


(:~for the annotations in pelagios, decide based on id how to format the uri
: wikidata.org/entity/ and not /wiki/ because it returns a 303 
: is actually the point. It's an indication that the resources represents 
: "a "real world thing", and the redirect is to the Web resource 
: describing the real world thing, as it were. (Rainer Simon)
:)

declare
 %test:arg("placeid", "INS00001BL") %test:assertEquals("http://betamasaheft.eu/institutions/INS00001BL") 
 %test:arg("placeid", "LOC1001Aallee") %test:assertEquals("http://betamasaheft.eu/places/LOC1001Aallee")
 %test:arg("placeid", "pleiades:12345") %test:assertEquals("https://pleiades.stoa.org/places/12345")
 %test:arg("placeid", "Q12345") %test:assertEquals("https://www.wikidata.org/entity/Q12345")
 %test:arg("placeid", "gn:12345") %test:assertEquals("http://sws.geonames.org/12345")
function ann:getannotationbody($placeid as xs:string){
if(starts-with($placeid, 'INS')) then $config:appUrl || '/institutions/' || $placeid
else if(starts-with($placeid, 'LOC')) then $config:appUrl || '/places/' || $placeid
else if(starts-with($placeid, 'pleiades:')) then 'https://pleiades.stoa.org/places/' || substring-after($placeid, 'pleiades:')
else if(starts-with($placeid, 'Q')) then 'https://www.wikidata.org/entity/' || $placeid
else 'http://sws.geonames.org/' || substring-after($placeid, 'gn:')
};


declare 
%test:args('<place xmlns="http://www.tei-c.org/ns/1.0" type="waradā">
               <placeName xml:id="n1">Aallee</placeName>
               <country ref="LOC3010Ethiop"/>
               <region notBefore="1991" type="RegionalState" ref="LOC6530Oromiyaa"/>
               <region notAfter="1974" type="Province"/>
               <settlement type="zone"/>
               <location>
                  <geo cert="low">8.431601 35.688606</geo>
               </location>
               <listBibl type="secondary">
                  <bibl>
                     <ptr target="bm:Zitelmann2007EnAeIllubabor"/>
                  </bibl>
               </listBibl>
               <note>
                  <date type="foundation" atLeast="1991">After 1991</date>
                  <ab type="description">Aallee is one of 12 <placeName>waradā</placeName> created in the highland
                        <placeName ref="LOC3924Illuba">Illubabor </placeName> after <date>1991</date> and the
                     introduction of "ethnic federalism". </ab>
               </note>
            </place>','Aallee','LOC1001Aallee') 
            %test:assertEquals('
             
             <http://betamasaheft.eu/places/LOC1001Aallee> a lawd:Place ;
  rdfs:label "Aallee";
 dcterms:source <http://betamasaheft.eu/LOC1001Aallee.xml> ;
 
lawd:hasName [ lawd:primaryForm "Aallee" ];
geo:location [ geo:lat 8.431601 ;  geo:long 35.688606 ] ; 
 foaf:primaryTopicOf <http://betamasaheft.eu/places/LOC1001Aallee/main> ;
                dcterms:isPartOf <http://betamasaheft.eu/places/LOC6530Oromiyaa>;

                .
                
                ') 
function ann:annotatedThing($node as element(), $tit, $id){
let $d := $node
let $r := $id
let $sr := string($r)
let $lang := if($d/t:placeName[.= $tit[1]]/@xml:lang) then '@' || $d/t:placeName[.= $tit[1]]/@xml:lang else ()
let $temporal := if($d//t:state[@type='existence'][@from or @to]) then for $existence in $d//t:state[@type='existence'][@from or @to] return let $from := string($existence/@from) let $to := string($existence/@to) return ('dcterms:temporal "' ||$from||'/'||$to||'";
 ') else ()
let $PeriodO := if($d//t:state[@type='existence'][@ref]) then for $periodExistence in  $d//t:state[@type='existence'][@ref]  let $periodid := string($periodExistence/@ref) let $period := collection($config:data-root)//id($periodid)[1] return ('dcterms:temporal <' || string(($period//t:sourceDesc//t:ref/@target)[1])|| '>;
 ') else ()
let $sameAs := if($d//@sameAs) then
' skos:exactMatch <' || ann:getannotationbody($d//@sameAs[1]) ||'> ;
'else ()
let $names := for $name in $d/t:placeName
let $l := if($name/@xml:lang) then '@' || string($name/@xml:lang) else ()
return 
if($name/@xml:id = 'n1') 
then '
lawd:hasName [ lawd:primaryForm "'||normalize-space($name)||'"' ||$l|| ' ];'
else '
lawd:hasName [ lawd:variantForm "'||normalize-space($name)||'"' ||$l|| ' ];'

let $partof := if($d/t:settlement[@ref]) then let $setts := for $s in $d/t:settlement/@ref return 'dcterms:isPartOf <' || ann:getannotationbody($s) || '>; 
'  return string-join($setts, ' 
')
else if ($d/t:region[@ref]) then let $regs := for $s in $d/t:region/@ref return 'dcterms:isPartOf <' || ann:getannotationbody($s ) || '>;
'  return string-join($regs, ' 
')
else if ($d/t:country[@ref]) then let $countries := for $s in $d/t:country/@ref return  'dcterms:isPartOf <' || ann:getannotationbody($s) || '>;
'  return string-join($countries, ' 
')
else ()
let $geo := if($d//t:geo/text()) then '
geo:location [ geo:lat '||substring-before($d//t:geo/text(), ' ')|| ' ;  geo:long '||substring-after($d//t:geo/text(), ' ')|| ' ] ;' else if($d//@sameAs[1]) then let $geoid := string($d//@sameAs[1]) let $coordinates := coord:GNorWD($geoid)  return if(starts-with($coordinates, 'no')) then () else '
geo:location [ geo:lat '||substring-before($coordinates, ',')|| ' ;  geo:long '||substring-after($coordinates, ',')|| ' ] ;' else ()
        
 return
 
 <annotatedThing id="{$r}">
 
             {'
             
             &lt;'||$config:appUrl || '/places/'||
 $sr||'&gt; a lawd:Place ;
  rdfs:label "' || 
 $tit[1] || '"' ||$lang ||';
 dcterms:source &lt;'||$config:appUrl || '/'||
 $sr||'.xml&gt; ;
 '||string-join($temporal, '
') ||string-join($PeriodO, '
') ||$sameAs ||string-join($names, ' 
 ')||
 $geo||
 ' 
 foaf:primaryTopicOf &lt;'||$config:appUrl || '/places/' || 
                $sr || '/main&gt; ;
                ' ||
                $partof
                ||'
                .
                
                '}
   
   
 </annotatedThing>
 
 (: this should go into the <annotatedThing/> but I am not sure how to do it... 

<annotations>
 {for $thisd at $x in collection($config:data-rootW, $config:data-rootMS)//t:placeName[@ref = $r]
 return
 <annotation>{
' <http://betamasaheft.aai.uni-hamburg.de/att/'||$x||'> a lawd:Attestation ;
  dcterms:publisher <http://betamasaheft.aai.uni-hamburg.de/places/list/> ;
  cito:citesAsEvidence
    <http://www.mygazetteer.org/documents/01234> ;
  cnt:chars "Αθήνα" 
  .
 '
 }
 </annotation>
 }
 </annotations>:)
};