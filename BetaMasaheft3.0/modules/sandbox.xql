xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace xxx="http://www.w3.org/2005/sparql-results#";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "tei2string.xqm";

import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "item.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMas/timeline" at "timeline.xqm";


declare function local:wordcount($manuscriptID, $workID){
let $ms := collection($config:data-rootMS)/id($manuscriptID)
let $msitemID := $ms//t:title[@ref = $workID]/parent::t:msItem/@xml:id
let $div := $ms//t:div[contains(@corresp, $msitemID)]
let $divID := string($div/@xml:id)
let $count := count(tokenize(string-join($div//text(), ' '), '\W+'))
return
$workID || ' in ms ' ||$manuscriptID || ' can be found in the msitem '|| $msitemID || ' and the corresponding div ' || $divID || 'with the transcription for this msItem has a word count of ' || $count
};

let $msid := 'FSUor133'
let $workid := 'LIT4706List'
return
item:wordcount($msid, $workid)