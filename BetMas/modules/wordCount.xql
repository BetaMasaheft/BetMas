xquery version "3.1" encoding "UTF-8";
(:~
 : module returning word count for a single piece of text in a manuscript.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace WC = "https://www.betamasaheft.uni-hamburg.de/BetMas/WC";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


(:~ given the id of a manuscript returns the word count for eventual transcriptions of that work in the given witness :) 
declare

%rest:GET
%rest:path("/BetMas/api/WordCount/{$manuscriptID}/{$workID}")
%output:method("text")
function WC:WordCount($manuscriptID  as xs:string*, $workID as xs:string*) as xs:string{
let $ms := collection($config:data-rootMS)/id($manuscriptID)
let $tit := $ms//t:title[@ref = $workID]

let $msitemID := $tit/parent::t:msItem/@xml:id

return

if($ms//t:div[contains(@corresp, $msitemID)]) then
let $div := $ms//t:div[contains(@corresp, $msitemID)]
let $count := count(tokenize(string-join($div//text(), ' '), '\W+'))
return
'word count: ' || $count
else ('word count: no transcription available')

};
