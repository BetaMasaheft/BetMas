 xquery version "3.1";
 
(: Utility file used for the static institutions list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMasWeb/modules/titlesData.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";

declare variable $local:shortTitles := $apprest:collection-rootIn//t:titleStmt/t:title[@type='short'] ;

    for $repo in doc('/db/apps/lists/institutions.xml')//t:item
    let $repoID := string($repo/@xml:id)
    let $file := $apprest:collection-rootIn//id($repoID)
    let $threeletters :=  if($file//t:titleStmt/t:title[@type='short']) then 'EMML, ' || $file//t:titleStmt/t:title[@type='short'] else 
       let $endID := upper-case(substring ($repoID, 8,3))
       let $endID3 :=        if (string-length($endID) lt 3) then concat($endID, 'I') else $endID
       return
   if($endID3 = $local:shortTitles) then 'BM, ' ||$endID3 || ' same as EMML' else 'BM, ' ||$endID3
   return
$threeletters ||', ' ||  $repoID||', ' ||  replace($repo/text(), ',', ' ')