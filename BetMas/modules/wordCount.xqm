xquery version "3.1" encoding "UTF-8";
(:~
 : module returning word count for a single piece of text in a manuscript.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace WC = "https://www.betamasaheft.uni-hamburg.de/BetMas/WC";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~ given the id of a manuscript returns the word count for eventual transcriptions of that work in the given witness :) 
declare

%rest:GET
%rest:path("/BetMas/api/WordCount/{$manuscriptID}/{$workID}")
%test:args("FSUor13", "LIT1933Mashaf#Introduction") %test:assertEquals("word count: 85")
%test:args("FSUrueppII2", "LIT2697Sam") %test:assertEquals("word count: no transcription available")
%test:args("FSUrueppII2", "LIT1933Mashaf") %test:assertEquals("no textual unit LIT1933Mashaf in the manuscript FSUrueppII2")
%output:method("text")
function WC:WordCount($manuscriptID  as xs:string*, $workID as xs:string*) as xs:string{
let $ms := collection($config:data-rootMS)/id($manuscriptID)
let $tit := $ms//t:title[@ref = $workID]
return
if(count($tit) = 0) then ('no textual unit ' || $workID || ' in the manuscript ' || $manuscriptID) else
let $msitemID := $tit/parent::t:msItem/@xml:id

return

if($ms//t:div[@corresp = $msitemID]) then
let $div := $ms//t:div[@corresp = $msitemID]
let $count := count(tokenize(string-join($div//text(), ' '), '\W+'))
return
'word count: ' || $count
else ('word count: no transcription available')

};
