xquery version "3.1";
(:~
 : lists the functions available in the restXQ module to be printed in the api documentation
 : 
 : @author Pietro Liuzzo 
 :)
module namespace apidoc="https://www.betamasaheft.uni-hamburg.de/BetMas/apidoc";

declare namespace rest="http://exquery.org/ns/restxq";

declare function apidoc:iiif($node as node()*, $model as map(*)){
    let $restxq := rest:resource-functions()
let $iiif :=  $restxq//rest:resource-function[rest:identity[ends-with(@namespace, 'iiif')]]
for $request in $iiif
return 
    
    <div id="{$request/rest:identity/@local-name}" class="APIexamplestable">
    <div class="w3-row lead"><div class="w3-container">Pattern</div></div>
            <div class="w3-row">
            <div class="w3-container"><pre>{'/'||string-join($request/rest:annotations//rest:segment[position() gt 1]/text(), '/')}</pre></div>
            </div>
    </div>
    
};