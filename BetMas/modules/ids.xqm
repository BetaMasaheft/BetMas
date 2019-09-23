xquery version "3.1" encoding "UTF-8";
(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 : 
 : @author Pietro Liuzzo 
 :)
module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMas/listIds";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "log.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare 
%rest:GET
%rest:path("/BetMas/listIds")
%output:method("html5")
function listIds:getlist(){
<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
       <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1"></script>
        <script type="text/javascript" src="resources/js/analytics.js"></script>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>list of ids</title>
        {apprest:scriptStyle()}
    </head>
    <body id="body">
        {nav:barNew()}
        {nav:modalsNew()}
          {nav:searchhelpNew()}
          <p class="w3-large">Please note that this list excludes the IslHornAfr manuscripts and EMML manuscripts. The ids of the first group are all made of the IHA sigla followed by a progressive number. The ids of the EMML manuscripts are made of the sigla EMML follwed by a progressive number.</p>
          {
let $allrepos := $config:collection-rootMS//t:repository[matches(@ref, 'INS')]
let $repos := $allrepos[not(ends-with(@ref, 'IHA'))][not(@ref = 'INS0004HMML')]
for $repo in $repos
let $ref := $repo/@ref
group by $ref
let $rID := string($ref)
let $tit := try{titles:printTitleMainID($rID)} catch * {'no title'}
order by $tit
return
    <div class="w3-container"><h1>{$tit} ({$rID})</h1>
    {for $rep in $repo
    let $collection := if($rep/following-sibling::t:collection) then $rep/following-sibling::t:collection[1]/text() else 'no specific collection'
    group by $collection
    order by $collection
    return 
        <div class="w3-row"><h2>{$collection}</h2>
        <div class="w3-container">{
          let $ids := for $reC in $rep
            
let $root := root($reC)
let $id := string($root/t:TEI/@xml:id)
  return $id
         for $i in $ids 
         order by $i
         return
         <div class="w3-row"><b>{$i}</b></div>
            
        }
        </div>
        </div>
    }
    </div>
    }
    </body>
    </html>
    };