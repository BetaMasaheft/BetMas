xquery version "3.0";

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
 
 : slightly modified to serve only WORKS repo for BetaMasaheft
 
 : @author Pietro Liuzzo added validation and specific report
 :)

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace xqjson = "http://xqilla.sourceforge.net/lib/xqjson";
import module namespace crypto = "http://expath.org/ns/crypto";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace validation = "http://exist-db.org/xquery/validation";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace t = "http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(:~
 : Recursively creates new collections if necessary. 
 : @param $uri url to resource being added to db 
 :)
declare function local:create-collections($uri as xs:string) {
    let $collection-uri := substring($uri, 1)
    for $collections in tokenize($collection-uri, '/')
    let $current-path := concat('/', substring-before($collection-uri, $collections), $collections)
    let $parent-collection := substring($current-path, 1, string-length($current-path) - string-length(tokenize($current-path, '/')[last()]))
    return
        if (xmldb:collection-available($current-path)) then
            ()
        else
            xmldb:create-collection($parent-collection, $collections)
};

(:~
 : Updates files in eXistdb with github data
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function local:do-update($commits as node()*, $contents-url as xs:string?) {
    let $committerEmail := $commits/descendant::*/*:pair[@name = "committer"]/*:pair[@name = "email"]/text()
    return
        
        for $modified in $commits/descendant::*/*:pair[@name = "modified"]/*:item/text()
        let $file-path := concat($contents-url, $modified)
        let $gitToken := environment-variable('GITTOKEN')
        (:environment-variable('GIT_TOKEN'):)
        let $req :=
        <http:request http-version="1.1"
            href="{xs:anyURI($file-path)}"
            method="GET">
            <http:header
                name="Authorization"
                value="{('token ' || $gitToken)}"/>
        </http:request>
        let $file := http:send-request($req)[2]
        let $file-info :=
        let $payload := util:base64-decode($file)
        let $parse-payload := xqjson:parse-json($payload)
        return
            $parse-payload
        let $file-data := $file-info//*:pair[@name = "content"]
        let $collection := xs:anyURI('/db/apps/BetMas/data/works')
        let $file-name := $file-info//*:pair[@name = "name"]/text()
        let $resource-path := substring-before($modified, $file-name)
        let $collection-uri := concat($collection, '/', $resource-path)
        return
            try {
                (if (xmldb:collection-available($collection-uri)) then
                    
                    <response
                        status="okay">
                        <message>{xmldb:store($collection-uri, xmldb:encode-uri($file-name), xs:base64Binary($file-data))}</message>
                    </response>
                else
                    <response
                        status="okay">
                        <message>
                            {(local:create-collections($collection-uri), xmldb:store($collection-uri, xmldb:encode-uri($file-name), xs:base64Binary($file-data)))
                            }
                        </message>
                    </response>
                ,
                (:        if the update goes well, validation happens after storing, because the app needs to remain in sync with the GIT repo. Yes, invalid data has to be allowed in.:)
                let $stored-file := doc($collection-uri || '/' || $file-name)
                return
                    local:validateAndConfirm($stored-file, $committerEmail, 'updated')
                )
            } catch * {
                <response
                    status="fail">
                    <message>Failed to update resource {$file-name}: {concat($err:code, ": ", $err:description)}</message>
                </response>
            }
};

(:~
 : Adds new files to eXistdb. Changes permissions for group write. 
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
 : NOTE permission changes could happen in a db trigger after files are created
:)
declare function local:do-add($commits as node()*, $contents-url as xs:string?) {
    let $committerEmail := $commits/descendant::*/*:pair[@name = "committer"]/*:pair[@name = "email"]/text()
    return
        
        for $modified in $commits/descendant::*/*:pair[@name = "added"]/*:item/text()
        let $file-path := concat($contents-url, $modified)
        let $gitToken := environment-variable('GITTOKEN')
        (:environment-variable('GIT_TOKEN'):)
        let $req :=
        <http:request
        http-version="1.1"
            href="{xs:anyURI($file-path)}"
            method="GET">
            <http:header
                name="Authorization"
                value="{('token ' || $gitToken)}"/>
        </http:request>
        let $file := http:send-request($req)[2]
        let $file-info :=
        let $payload := util:base64-decode($file)
        let $parse-payload := xqjson:parse-json($payload)
        return
            $parse-payload
        let $file-data := $file-info//*:pair[@name = "content"]
        let $collection := xs:anyURI('/db/apps/BetMas/data/works')
        let $file-name := $file-info//*:pair[@name = "name"]/text()
        let $resource-path := substring-before($modified, $file-name)
        let $collection-uri := concat($collection, '/', $resource-path)
        return
            try {
                (if (xmldb:collection-available($collection-uri)) then
                    <response
                        status="okay">
                        <message>
                            {
                                (
                                xmldb:store($collection-uri, xmldb:encode-uri($file-name), xs:base64Binary($file-data)),
                                sm:chmod(xs:anyURI(concat($collection-uri, '/', $file-name)), 'rwxrwxr-x'),
                                sm:chgrp(xs:anyURI(concat($collection-uri, '/', $file-name)), 'Cataloguers')
                                )
                            }
                        </message>
                    </response>
                else
                    <response
                        status="okay">
                        <message>
                            {
                                (
                                local:create-collections($collection-uri),
                                xmldb:store($collection-uri, xmldb:encode-uri($file-name), xs:base64Binary($file-data)),
                                sm:chmod(xs:anyURI(concat($collection-uri, '/', $file-name)), 'rwxrwxr-x'),
                                sm:chgrp(xs:anyURI(concat($collection-uri, '/', $file-name)), 'Cataloguers')
                                )
                            }
                        </message>
                    </response>,
                (:        if the update goes well, validation happens after storing, because the app needs to remain in sync with the GIT repo. Yes, invalid data has to be allowed in.:)
                let $stored-file := doc($collection-uri || '/' || $file-name)
                return
                    local:validateAndConfirm($stored-file, $committerEmail, 'updated')
                )
            } catch * {
                <response
                    status="fail">
                    <message>Failed to add resource {$file-name}: {concat($err:code, ": ", $err:description)}
                    </message>
                </response>
            }
};

(:~
 : Removes files from the database uses xmldb:remove
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function local:do-delete($commits as node()*, $contents-url as xs:string?) {
    for $modified in $commits/descendant::*/*:pair[@name = "removed"]/*:item/text()
    let $file-path := concat($contents-url, $modified)
    let $collection := xs:anyURI('/db/apps/BetMas/data/works')
    let $file-name := tokenize($modified, '/')[last()]
    let $resource-path := substring-before($modified, $file-name)
    let $collection-uri := replace(concat($collection, '/', $resource-path), '/$', '')
    return
        try {
            <response
                status="okay">
                <message>Removed {$file-name}
                    {xmldb:remove($collection-uri, $file-name)}</message>
            </response>
        } catch * {
            <response
                status="fail">
                <message>Failed to remove resource {$file-name}: {concat($err:code, ": ", $err:description)}</message>
            </response>
        }

};


(:~
 :after storing a resource (and thus keeping the app in sync with the git repos)
 :this function takes the file and validates it. if it is valid it does nothing else. 
 : If it is not it sends an email to the committer asking for changes and giving wise advice...
 : this function is called only on add and update
:)
declare function local:validateAndConfirm($item, $mail, $type) {
    let $id := string($item//t:TEI/@xml:id)
    let $schema := doc('/db/apps/BetMas/schema/tei-betamesaheft.rng')
    (:validate:)
    let $validation := validation:jing($item, $schema)
    return
        (:       if all is ok, do not bother :)
        if ($validation = true()) then
            ()
            (:       if there are problems, fire notification email:)
        else
            (
            (:build the message:)
            let $report := validation:jing-report($item, $schema)
            let $contributorMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>{$mail}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>Oh no! You just pushed invalid data to Beta maṣāḥǝft...</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Report on the issues encountered in your file.</title>
                            </head>
                            <body>
                                <p>It's nice to push your changes directly to the live app and let the world know immediately about them!</p>
                                <p>This time however your newly {$type} file <mark>{$id}.xml</mark>
                                    <b>did not validate</b> to the Beta maṣāḥǝft schema,
                                    and there is a high chance of risk it will break
                                    something in the database, and lead to errors in the website and other outputs.</p>
                                <p>The following is a validation report from the app, but you can validate the file with your preferred method.</p>
                                <div
                                    style="background-color:#ffad99;"><p><b>{$report//status/text()}</b>.</p>
                                    {
                                        for $mess in $report//message
                                        return
                                            <p>{string($mess/@level)} at line {string($mess/@line)}: {$mess/text()}</p>
                                    }</div>
                                <p><b>Please fix these issues as soon as possible and push the data to the <b>works</b> repo again.</b></p>
                                <p>For the future, please note that you do not need to commit everything every time, you can decide
                                    what can be pushed to the app and what should not yet. Invalid files should fall ALWAYS in the second category.</p>
                                <p>Thank you!</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
                if (mail:send-email($contributorMessage, 'public.uni-hamburg.de', ()))
                then
                    console:log('Sent Message to editor OK')
                else
                    console:log('message not sent to editor')
            
            )
};


(:~
 : Parse request data and pass to appropriate local functions
 : @param $json-data github response serializing as xml xqjson:parse-json()  
 :)
declare function local:parse-request($json-data) {
    let $contents-url := substring-before($json-data//*:pair[@name = "contents_url"]/text(), '{')
    return
        try {
            if ($json-data//*:pair[@name = "ref"] = "refs/heads/master") then
                if ($json-data//*:pair[@name = "commits"]) then
                    let $commits := $json-data//*:pair[@name = "commits"]
                    return
                        (if ($commits/descendant::*/*:pair[@name = "modified"]/*:item/text()) then
                            local:do-update($commits, $contents-url)
                        else
                            (),
                        if ($commits/descendant::*/*:pair[@name = "added"]/*:item/text()) then
                            local:do-add($commits, $contents-url)
                        else
                            (),
                        if ($commits/descendant::*/*:pair[@name = "removed"]/*:item/text()) then
                            local:do-delete($commits, $contents-url)
                        else
                            ())
                else
                    <response
                        status="fail"><message>This is a GitHub request, however there were no commits.</message></response>
            else
                <response
                    status="fail"><message>Not from the master branch.</message></response>
        } catch * {
            <response
                status="fail">
                <message>{concat($err:code, ": ", $err:description)}</message>
            </response>
        }
};

(:~
 : Validate github post request.
 : Check user agent and github event, only accept push events from master branch.
 : Check git hook secret against secret stored in environmental variable
 : @param $GIT_TOKEN environment variable storing github secret
 :)



let $post-data := request:get-data()

return
    if (not(empty($post-data))) then
        let $payload := util:base64-decode(request:get-data())
        let $json-data := xqjson:parse-json($payload)
        
        let $data-collection := '/db/apps/BetMas/data/works'
        
        let $login := xmldb:login($data-collection, $config:ADMIN, $config:ppw)
        
        return
            try {
                
                if (matches(request:get-header('User-Agent'), '^GitHub-Hookshot/')) then
                    if (request:get-header('X-GitHub-Event') = 'push') then
                        let $signiture := request:get-header('X-Hub-Signature')
                        let $expected-result := <expected-result>{request:get-header('X-Hub-Signature')}</expected-result>
                        let $private-key :=
                        environment-variable('GIT_SECRETw')
                        let $actual-result :=
                        <actual-result>
                            {concat('sha1=', crypto:hmac($payload, $private-key, "HMAC-SHA-1", "hex"))}
                        </actual-result>
                        let $condition := normalize-space($expected-result/text()) = normalize-space($actual-result/text())
                        return
                            if ($condition) then
                                local:parse-request($json-data)
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

