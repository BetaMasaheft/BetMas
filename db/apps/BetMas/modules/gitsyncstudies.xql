xquery version "3.1";

(:module namespace gitsync = "http://syriaca.org/ns/gitsync";:)

(:~ 
 : XQuery endpoint to respond to Github webhook requests. Query responds only to push requests. 
 : The EXPath Crypto library supplies the HMAC-SHA1 algorithm for matching Github secret. 
 
 : Secret can be stored as environmental variable.
 : Will need to be run with administrative privileges, suggest creating a git user with privileges only to relevant app.
 :
 : @author Winona Salesky
 : @version 1.1 
 :
 : @see https://github.com/joewiz/xqjson   
 : @see http://expath.org/spec/crypto 
 : @see http://expath.org/spec/http-client
 : 
 
 : slightly modified to serve only Studies repo for BetaMasaheft
 
 : @author Pietro Liuzzo added validation and specific report, changed to use 3.1 and to use parse-json instead of xqjson in some cases
 :)
import module namespace gitsync = "http://syriaca.org/ns/gitsync" at "xmldb:exist:///db/apps/BetMas/modules/gitsync.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace crypto = "http://expath.org/ns/crypto";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(:~
 : Validate github post request.
 : Check user agent and github event, only accept push events from master branch.
 : Check git hook secret against secret stored in environmental variable
 : @param $GIT_TOKEN environment variable storing github secret
 :)



let $post-data := request:get-data()

return
    if (not(empty($post-data))) then
        let $payload := util:base64-decode($post-data)
        let $json-data := parse-json($payload)
        
        let $data-collection := '/db/apps/BetMasData/studies'
        
        let $login := xmldb:login($data-collection, 'BetaMasaheftAdmin', 'BMAdmin')
        
        return
            try {
                
                if (matches(request:get-header('User-Agent'), '^GitHub-Hookshot/')) then
                    if (request:get-header('X-GitHub-Event') = 'push') then
                        let $signiture := request:get-header('X-Hub-Signature')
                        let $expected-result := <expected-result>{request:get-header('X-Hub-Signature')}</expected-result>
                        let $private-key :=
                        environment-variable('GIT_SECRETstudies')
                        let $actual-result :=
                        <actual-result>
                            {concat('sha1=', crypto:hmac($payload, $private-key, "HMAC-SHA-1", "hex"))}
                        </actual-result>
                        let $condition := normalize-space($expected-result/text()) = normalize-space($actual-result/text())
                        return
                            if ($condition) then
                                gitsync:parse-request($json-data, $data-collection)
                            else
                                <response
                                    status="fail"><message>Invalid secret.</message></response>
                    else
                        <response
                            status="fail"><message>Invalid trigger.</message></response>
                else
                    <response
                        status="fail"><message>This is not a GitHub request.</message></response>
            } catch * {
                <response
                    status="fail">
                    <message>Unacceptable headers {concat($err:code, ": ", $err:description)}</message>
                </response>
            }
    else
        <response
            status="fail">
            <message>No post data recieved</message>
        </response>

