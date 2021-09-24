            
xquery version "3.1" encoding "UTF-8";
(:~
 : module to retrive quotations of  a given specific passage
 : 
 : @author Pietro Liuzzo 
 :)
module namespace quotations = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/quotatoins";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

(:~ 
given a passage in a text, search places where this passage has been
quoted
cRef=betmas:LIT1546Genesi.1.1
where betmas: is prefix for https://betamasaheft.eu/
and .1.1 will map to &ref=1.1
:) 
declare
%rest:GET
%rest:path("/api/quotations/{$text}/{$passage}")
%output:method("json")
function quotations:allquotations($text  as xs:string*,$passage  as xs:string*){
let $quotations := $exptit:col//t:cit[t:ref[contains(@cRef, $text)]]
let $thispassage := 
for $quote in $quotations[t:ref[contains(substring-after(@cRef, concat($text, ':')), $passage)]]
                                            let $id := string(root($quote)/t:TEI/@xml:id) 
                                          let $titlesource := exptit:printTitleID($id)
                                           let $source := map {'id' : $id, 'title' : $titlesource} 
                                            let $t := $quote/t:quote/text()
                                            let $r := string($quote/t:ref/@cRef)
                                        return 
                                        map {'text' : $t, 'source' : $source, 'ref' : $r}
return if (count($thispassage) ge 1) then map {'total' : count($thispassage), 'quotations' : [$thispassage]} else map {'total' : 0, 'info' : 'sorry, there are no marked up quotations of this passage'}
};
