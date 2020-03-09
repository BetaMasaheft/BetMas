            
xquery version "3.1" encoding "UTF-8";
(:~
 : module to retrive quotations of  a given specific passage
 : 
 : @author Pietro Liuzzo 
 :)
module namespace quotations = "https://www.betamasaheft.uni-hamburg.de/BetMas/quotatoins";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


    (:~ given a role, search other attestations of it and print the persName around them and related infos :) 
declare
%rest:GET
%rest:path("/BetMas/api/quotations/{$text}/{$passage}")
%output:method("json")
function quotations:allquotations($text  as xs:string*,$passage  as xs:string*){
let $quotations := $config:collection-root//t:cit[t:ref[contains(@cRef, $text)]]
let $thispassage := for $quote in $quotations[t:ref[contains(substring-after(@cRef, concat($text, ':')), $passage)]]
                                            let $id := string(root($quote)/t:TEI/@xml:id) 
                                          let $titlesource := titles:printTitleMainID($id)
                                           let $source := map {'id' : $id, 'title' : $titlesource} 
                                            let $t := $quote/t:quote/text()
                                            let $r := string($quote/t:ref/@cRef)
                                        return 
                                        map {'text' : $t, 'source' : $source, 'ref' : $r}
return if (count($thispassage) ge 1) then map {'total' : count($thispassage), 'quotations' : [$thispassage]} else map {'total' : 0, 'info' : 'sorry, there are no marked up quotations of this passage'}
};
