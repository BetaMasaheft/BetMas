xquery version "3.1" encoding "UTF-8";
(:~
 : this function makes a call to wikidata API 
 :)
module namespace wiki = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/wiki";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace http = "http://expath.org/ns/http-client";

declare function wiki:wikitable($Qitem as xs:string) {
  let $api-url := concat("https://www.wikidata.org/wiki/Special:EntityData/", $Qitem, ".json")
let $response :=
try {
let $request := <http:request method="GET" href="{$api-url}">
<http:header name="User-Agent" value="betamasaheft.eu (info@betamasaheft.eu)"/>
</http:request>
return http:send-request($request)
} catch * { () }

let $json :=
(util:base64-decode(string-join($response)))


let $json-doc :=
if ($json) then parse-json($json) else ()
let $claims :=  $json-doc?entities?($Qitem)?claims?P214 
let $viaf-id := 
if (exists($claims)) then
let $firstClaim := $claims?1
return $firstClaim?mainsnak?datavalue?value
else ()
let $WDurl := concat("https://www.wikidata.org/wiki/", $Qitem)
  return
    if (exists($viaf-id) and string-length($viaf-id) > 0) then
      <div class="w3-responsive">
        <table class="w3-table w3-hoverable">
          <tbody>
            <tr>
              <td>WikiData Item</td>
              <td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
            </tr>
            <tr>
              <td>VIAF ID</td>
              <td>
                <a target="_blank" href="https://viaf.org/viaf/{$viaf-id}">{$viaf-id}</a>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    else
      <div class="w3-responsive">
        <table class="w3-table w3-hoverable">
          <tbody>
            <tr>
              <td>WikiData Item</td>
              <td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
            </tr>
          </tbody>
        </table>
      </div>
};