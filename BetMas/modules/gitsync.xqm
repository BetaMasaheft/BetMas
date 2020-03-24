xquery version "3.1";

module namespace gitsync = "http://syriaca.org/ns/gitsync";

(:~ 
 : XQuery endpoint to respond to Github webhook requests. Query responds only to push requests. 
 : The EXPath Crypto library supplies the HMAC-SHA1 algorithm for matching Github secret. 

 : Secret can be stored as environmental variable.
 : Will need to be run with administrative privileges, suggest creating a git user with privileges only to relevant app.
 :
 : @author Winona Salesky
 : @version 1.1 
 :
 : @see http://expath.org/spec/crypto 
 : @see http://expath.org/spec/http-client
 : 
 
 : @author Pietro Liuzzo 
 : @version 1.2
 :  slightly modified to serve only PERSONS repo for BetaMasaheft
 :  added validation and specific report, changed to use 3.1 and to use parse-json instead of xqjson
 : @see https://exist-db.org/exist/apps/wiki/blogs/eXist/XQuery31
 :  after storing the file this is transformed to RDF and stored in the RDF collection
 :)

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace updatefuseki = 'https://www.betamasaheft.uni-hamburg.de/BetMas/updatefuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/updateFuseki.xqm";
import module namespace validation = "http://exist-db.org/xquery/validation";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare variable $gitsync:institutions := doc('/db/apps/BetMas/lists/institutions.xml');
declare variable $gitsync:persons := doc('/db/apps/BetMas/lists/persNamesLabels.xml');
declare variable $gitsync:textparts := doc('/db/apps/BetMas/lists/textpartstitles.xml');
declare variable $gitsync:places := doc('/db/apps/BetMas/lists/placeNamesLabels.xml');
declare variable $gitsync:deleted := doc('/db/apps/BetMas/lists/deleted.xml');
declare variable $gitsync:taxonomy := doc(concat($config:data-rootA,'/taxonomy.xml'));
declare variable $gitsync:canotax := doc('db/apps/BetMas/lists/canonicaltaxonomy.xml');
declare variable $gitsync:data2rdf := 'xmldb:exist:///db/apps/BetMas/rdfxslt/data2rdf.xsl';
(:~
 : Recursively creates new collections if necessary. 
 : @param $uri url to resource being added to db 
 :)
declare function gitsync:create-collections($uri as xs:string) {
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

declare function gitsync:rdf($collection-uri, $file-name){
    let $stored-file := doc($collection-uri || '/' || $file-name)
(:transforms and stores the RDF as XML:)
    let $rdf := transform:transform($stored-file, $gitsync:data2rdf, ())
    let $rdffilename := replace($file-name, '.xml', '.rdf')
    let $collectionName := substring-after($collection-uri, '/db/apps/BetMasData/')
    let $shortCollName := if( matches($collectionName, 'manuscripts')) then 'manuscripts' 
                        else if( matches($collectionName, 'works')) then 'works' 
                        else if( matches($collectionName, 'persons')) then 'persons' 
                        else if( matches($collectionName, 'places')) then 'places'  
                        else if( matches($collectionName, 'institutions')) then 'institutions' 
                        else if( matches($collectionName, 'persons')) then 'persons' 
                        else 'authority-files'
    let $storecoll := concat('/db/rdf/', $shortCollName)
    let $storeRDFXML := xmldb:store($storecoll, $rdffilename, $rdf)
(:retrieve the RDF/XML as stored, and send it to update Apache Jena Fuseki and the triplestore:)
    let $rdfxml := doc($storecoll || '/'||$rdffilename)
    let $updateFuseki := updatefuseki:update($rdfxml, 'INSERT')
    return
        'stored RDF/XML and updated fuseki'
};

declare function gitsync:updateinstitutionsMOD($file-name){
    let $institutionslist := $gitsync:institutions//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update value  $institutionslist/t:item[@xml:id=$id] with titles:printTitleMainID($id)
    return
        'updated institutions.xml static list'
};

declare function gitsync:updateinstitutionsDEL($file-name){
    let $institutionslist := $gitsync:institutions//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update delete  $institutionslist/t:item[@xml:id=$id]
    return
        'removed value from list in institutions.xml'
};

declare function gitsync:updateinstitutionsADD($file-name){
    let $institutionslist := $gitsync:institutions//t:list
    let $id := substring-before($file-name, '.xml')
(:  This will inevitably cause the order in that list to be broken :)
    let $update :=  update insert <item xmlns="http://www.tei-c.org/ns/1.0">{titles:printTitleMainID($id)}</item> into  $institutionslist
    return
        'added value at the end of the list in institutions.xml'
};


declare function gitsync:updatepersonsMOD($file-name){
    let $perslist := $gitsync:persons//t:list
    let $id := substring-before($file-name, '.xml')
    let $t := titles:printTitleMainID($id)
    let $update :=  update value  $perslist/t:item[@corresp=$id] with $t
    return
        'updated persNamesLabels.xml static list with ' || $t || ' for item with id = ' || $id || '. '
};

declare function gitsync:updatepersonsDEL($file-name){
    let $perslist := $gitsync:persons//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update delete  $perslist/t:item[@corresp=$id]
    return
        'removed value from list in persNamesLabels.xml '
};


declare function gitsync:updateplacesMOD($file-name){
    let $placelist := $gitsync:places//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update value  $placelist/t:item[@corresp=$id] with titles:printTitleMainID($id)
    return
        'updated placeNamesLabels.xml static list'
};

declare function gitsync:updateplacesDEL($file-name){
    let $placelist := $gitsync:places//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update delete  $placelist/t:item[@corresp=$id]
    return
        'removed value from list in placeNamesLabels.xml '
};

declare function gitsync:updatetextpartsMOD($file-name){
    let $institutionslist := $gitsync:places//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update value  $institutionslist/t:item[@corresp=$id] with titles:printTitleMainID($id)
    return
        'updated textpartstitles.xml static list '
};

declare function gitsync:updatetextpartsDEL($file-name){
    let $institutionslist := $gitsync:places//t:list
    let $id := substring-before($file-name, '.xml')
    let $update :=  update delete  $institutionslist/t:item[@corresp=$id]
    return
        'removed value from list in textpartstitles.xml '
};



(:~
 : Updates files in eXistdb with github data
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function gitsync:do-update($commits, $contents-url as xs:string?, $data-collection) {
    let $committerEmail := $commits?1?pusher?email
    return
        
        for $modified in $commits?1?modified?*
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
        let $thispayload := util:base64-decode($file)
        let $JSON := parse-json($thispayload)
        let $file-data := $JSON?content
        let $file-name := $JSON?name
        let $collection := xs:anyURI($data-collection)
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
                            {(gitsync:create-collections($collection-uri), xmldb:store($collection-uri, xmldb:encode-uri($file-name), xs:base64Binary($file-data)))}
                        </message>
                    </response>
                ,
                (:        if the update goes well, validation happens after storing, because the app needs to remain in sync with the GIT repo. Yes, invalid data has to be allowed in.:)
                let $stored-file := doc($collection-uri || '/' || $file-name)
                return
                    if($file-name='taxonomy.xml') then (
                    gitsync:TaxonomyMessage()
                    ) 
                    else gitsync:validateAndConfirm($stored-file, $committerEmail, 'updated')
                    ,
                    if(contains($data-collection, 'institutions')) then (
                    gitsync:updateinstitutionsMOD($file-name) )
                    else if(contains($data-collection, 'persons')) then (
                    gitsync:updatepersonsMOD($file-name) ) 
                    else if(contains($data-collection, 'places')) then (
                    gitsync:updateplacesMOD($file-name) ) 
                    else ()
                    ,
                   gitsync:rdf($collection-uri, $file-name),
                     if (ends-with($file-name, '.xml')) then (
                     let $Stfile := doc($collection-uri || '/' || $file-name)
                     let $collectionName := substring-after($data-collection, '/db/apps/BetMasData/')
                     let $stored-fileID := $Stfile/t:TEI/@xml:id/string()
                     let $filename := substring-before($file-name, '.xml')
                     let $allids := for $xmlid in $Stfile//@xml:id return lower-case(string($xmlid))
                     let $taxonomy := for $key in $gitsync:taxonomy//t:catDesc/text() return lower-case($key)
                     return
                     if ($stored-fileID eq $filename) then (
                     if(($allids = $taxonomy) and ($collectionName !='authority-files')) then (let $intersect := distinct-values($allids[.=$taxonomy])
                     return
                     gitsync:wrongAnchor($committerEmail, $intersect, $filename)) else ()
                     ) else (
                     gitsync:wrongID($committerEmail, $stored-fileID, $filename)
                     )
                     ) else ()
                    
                )
            } catch * {
                (<response
                    status="fail">
                    <message>Failed to update resource: {concat($err:code, ": ", $err:description)}</message>
                </response>,
                        gitsync:failedCommitMessage($committerEmail, $data-collection, concat('Failed to update resource ' ,$file-name, ': ',$err:code, ": ", $err:description))
                        )
            }
};

(:~
 : Adds new files to eXistdb. Changes permissions for group write. 
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
 : NOTE permission changes could happen in a db trigger after files are created
:)
declare function gitsync:do-add($commits, $contents-url as xs:string?, $data-collection) {
    let $committerEmail := $commits?1?pusher?email
    return
        
        for $modified in $commits?1?added?*
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
        let $thispayload := util:base64-decode($file)
        let $JSON := parse-json($thispayload)
        let $file-data := $JSON?content
        let $file-name := $JSON?name
        let $collection := xs:anyURI($data-collection)
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
                                gitsync:create-collections($collection-uri),
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
                   ( 
                   gitsync:validateAndConfirm($stored-file, $committerEmail, 'updated')
                    ,
                    if(contains($data-collection, 'institutions')) then (
                        gitsync:updateinstitutionsADD($file-name)
                    ) else (),
                      let $deletedlist := $gitsync:deleted//t:list
                      let $alldeleted := $gitsync:deleted//t:list/t:item/text()
                    let $id := substring-before($file-name, '.xml')
                    let $remove :=
                    if ($id = $alldeleted) then
                    let $item := $deletedlist/t:item[.=$id]
                    return
                    update delete $item
                    else ()
                    return
                    'removed value from the list in deleted.xml'
                    ,
                    gitsync:rdf($collection-uri, $file-name)
                     ,
                if (ends-with($file-name, '.xml')) then (
                     let $stored-fileID := $stored-file/t:TEI/@xml:id/string()
                     let $filename := substring-before($file-name, '.xml')
                     let $collectionName := substring-after($data-collection, '/db/apps/BetMasData/')
                     let $allids := for $xmlid in $stored-file//@xml:id return string($xmlid)
                     let $taxonomy := for $key in $gitsync:taxonomy//t:catDesc/text() return lower-case($key)
                     return
                     if ($stored-fileID eq $filename) then (
                     if(($allids = $taxonomy) and ($collectionName !='authority-files')) then (let $intersect := distinct-values($allids[.=$taxonomy])
                     return
                     gitsync:wrongAnchor($committerEmail, $intersect, $filename)) else ()
                     )
                     else(
                     gitsync:wrongID($committerEmail, $stored-fileID, $filename)
                     )
                     ) else ()
)
                )
            } catch * {
            (
                <response
                    status="fail">
                    <message>Failed to add resource: {concat($err:code, ": ", $err:description)}
                    </message>
                </response>,
                        gitsync:failedCommitMessage($committerEmail, $data-collection, concat('Failed to add resource ' ,$file-name, ': ',$err:code, ": ", $err:description))
                        )
            }
};

(:~
 : Removes files from the database uses xmldb:remove
 : Pulls data from github repository, parses file information and passes data to xmldb:store
 : @param $commits serilized json data
 : @param $contents-url string pointing to resource on github
:)
declare function gitsync:do-delete($commits, $contents-url as xs:string?, $data-collection) {
let $committerEmail := $commits?1?pusher?email
return
    for $modified in $commits?1?removed?*
    let $file-path := concat($contents-url, $modified)
    let $collection := xs:anyURI($data-collection)
    let $file-name := tokenize($modified, '/')[last()]
    let $rdffilename := replace($file-name, '.xml', '.rdf')
    let $resource-path := substring-before($modified, $file-name)
    let $collection-uri := replace(concat($collection, '/', $resource-path), '/$', '')
    let $rdfcoll := '/db/rdf/' || substring-after($data-collection, 'Data/')
    let $rdfxml:= doc($rdfcoll||$rdffilename)
    let $updateFuseki := updatefuseki:update($rdfxml, 'DELETE')
    return
        try {
            <response
                status="okay">
                <message>removed {$collection-uri}/{$file-name}{xmldb:remove($collection-uri, $file-name)} 
                and {$rdfcoll}/{$rdffilename}{xmldb:remove($rdfcoll, $rdffilename)} also from fuseki
                {(
                    if(contains($data-collection, 'institutions')) then (
                    gitsync:updateinstitutionsDEL($file-name)) 
                    else if(contains($data-collection, 'persons')) then (
                    gitsync:updatepersonsDEL($file-name)) 
                    else if(contains($data-collection, 'places')) then (
                    gitsync:updateplacesDEL($file-name)) 
                    else (),
                    let $deletedlist := $gitsync:deleted//t:list
                    let $id := substring-before($file-name, '.xml')
(:                    This will inevitably cause the order in that list to be broken :)
                    let $update :=  update insert <item xmlns="http://www.tei-c.org/ns/1.0">{$id}</item> into  $deletedlist
                    return
                    'added value at the end of the list in deleted.xml'
                    )
                    }</message>
            </response>
        } catch * {
(            <response
                status="fail">
                <message>Failed to remove resource: {concat($err:code, ": ", $err:description)}</message>
            </response>,
                        gitsync:failedCommitMessage($committerEmail, $data-collection, concat('Failed to remove resource ' ,$file-name, ': ',$err:code, ": ", $err:description))
                        )
        }

};



(:~
 :after storing a resource (and thus keeping the app in sync with the git repos)
 :this function takes the file and validates it. if it is valid it does nothing else. 
 : If it is not it sends an email to the committer asking for changes and giving wise advice...
 : this function is called only on add and update
:)
declare function gitsync:validateAndConfirm($item, $mail, $type) {
    let $id := string($item//t:TEI/@xml:id)
    let $schema := xs:anyURI('https://raw.githubusercontent.com/BetaMasaheft/Schema/master/tei-betamesaheft.rng')
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
                <to>{$mail[1]}</to>
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
                                <p><b>Please fix these issues as soon as possible and push the data to the <b>persons</b> repo again.</b></p>
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
                mail:send-email($contributorMessage, 'public.uni-hamburg.de', ())
            
            )
};

(:~
 :after storing a resource (and thus keeping the app in sync with the git repos)
 :this function takes the file and validates it. if it is valid it does nothing else. 
 : If it is not it sends an email to the committer asking for changes and giving wise advice...
 : this function is called only on add and update
:)
declare function gitsync:wrongID($mail, $storedFileID, $filename) {
let $address := if ($mail[1] = 'noreply@github.com') then 'pietro.liuzzo@uni-hamburg.de' else $mail[1]
     let $WrongIdMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>{$address}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>It looks like there is a mismatching id for a file you pushed to Beta maṣāḥǝft...</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>The file {$filename}.xml has id {$storedFileID} instead of {$filename}.</title>
                            </head>
                            <body>
                                <p>The file {$filename}.xml has id {$storedFileID} instead of {$filename}.</p>
                                <p>
                                Please fix it as soon as possible.
                                </p>
                                <p>Thank you!</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
                mail:send-email($WrongIdMessage, 'public.uni-hamburg.de', ())
};

(:~
 :after storing a resource check that the file does not use taxonomy ids, if it does report email
:)
declare function gitsync:wrongAnchor($mail, $intersect, $filename) {
     let $WrongIdMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>{$mail[1]}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>It looks like there is a wrong anchor in a file you pushed to Beta maṣāḥǝft...</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>The file {$filename}.xml uses an invalid @xml:id.</title>
                            </head>
                            <body>
                                <p>The file {$filename}.xml has @xml:id {string-join($intersect, ', ')} which are not allowed as IDs, because they are values reserved for 
                                the taxonomy.
                                </p>
                                <p>
                                Please fix it as soon as possible.
                                </p>
                                <p>Thank you!</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
                mail:send-email($WrongIdMessage, 'public.uni-hamburg.de', ())
};

(:~
 :after storing a resource (and thus keeping the app in sync with the git repos)
 :this function takes the file and validates it. if it is valid it does nothing else. 
 : If it is not it sends an email to the committer asking for changes and giving wise advice...
 : this function is called only on add and update
:)
declare function gitsync:failedCommitMessage($mail, $data-collection, $message) {
     let $failureMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <cc>{$mail[1]}</cc>
                <bcc></bcc>
                <subject>The Syncing of GitHub with the Beta Masaheft App failed</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Failed Syncing {$data-collection} with the App.</title>
                            </head>
                            <body>
                                <p>Alas, your latest push to the application failed. Do not expect to find your latest changes in the application.</p>
                                <p>Your friendly tech lead already knows about it, as he is receiving this very same message, and will look at it as soon as possible. Below is the error message. You can read it,
                                some times it will tell you that you have forgotten to take care of your validation errors, in which case, 
                                please fix them as soon as possible. If you are not sure what to do, try not to worry too much, keep calm and carry on.</p>
                                <p>{$message}</p>
                                <p>Thank you!</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
               mail:send-email( $failureMessage, 'public.uni-hamburg.de', ())
};


(:~
 :after storing a resource (and thus keeping the app in sync with the git repos)
 :this function takes the file and validates it. if it is valid it does nothing else. 
 : If it is not it sends an email to the committer asking for changes and giving wise advice...
 : this function is called only on add and update
:)
declare function gitsync:mergeCommitMessage($mail, $data-collection, $message, $branch) {
     let $failureMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <bcc></bcc>
                <subject>Commit to {$branch}, not synced</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>The app did not sync the update to branch {$branch} of {$data-collection} with the App.</title>
                            </head>
                            <body>
                                <p>The app did not sync the update to branch {$branch} of {$data-collection} with the App.</p>
                                <p>{$message}</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
               mail:send-email( $failureMessage, 'public.uni-hamburg.de', ())
};
(:~
 : taxonomy and canonicaltaxonomy cannot be updated on the fly not to break the continuity of the
 one-way flow from github to the app. Pietro gets an email to update the canonical taxonomy in the rare 
 occasions in which the taxonomy has been updated.
:)
declare function gitsync:TaxonomyMessage() {
     let $failureMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <subject>taxonomy.xml has been updated. the canonicaltaxonomy.xml is thus outdated.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>taxonomy.xml has been updated. the canonicaltaxonomy.xml is thus outdated.</title>
                            </head>
                            <body>
                                <p>taxonomy.xml has been updated. the canonicaltaxonomy.xml is thus outdated.</p>
                                <p>Thank you!</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
               mail:send-email( $failureMessage, 'public.uni-hamburg.de', ())
};

(:~
 : Parse request data and pass to appropriate local functions
 : @param $json-data github response serializing as xml xqjson:parse-json()  
 :)
declare function gitsync:parse-request($json-data, $data-collection) {
let $login := xmldb:login($data-collection, 'Pietro', 'Hdt7.10')
let $repository := $json-data?repository
let $cturl := $repository?contents_url
let $contents-url := substring-before($cturl, '{')
return
        try {
            if ($json-data?ref = "refs/heads/master") then
                if (exists($json-data?commits)) then
                    let $commits := $json-data?commits
                    return
                        (
                        if (array:size($commits?1?modified) ge 1) then
                               gitsync:do-update($commits, $contents-url, $data-collection)
                        else
                            (),
                        if (array:size($commits?1?removed) ge 1) then
                            gitsync:do-delete($commits, $contents-url, $data-collection)
                        else
                            (),
                        if (array:size($commits?1?added) ge 1) then
                            gitsync:do-add($commits, $contents-url, $data-collection)
                        else
                            ())
                else
                    (<response
                        status="fail"><message>This is a GitHub request, however there were no commits.</message></response>
                        ,
                        gitsync:failedCommitMessage('', $data-collection, 'This is a GitHub request, however there were no commits.')
                        )
            else
                (<response
                    status="fail"><message>Not from the master branch.</message></response>,
                        gitsync:mergeCommitMessage('', $data-collection, 'Not from the master branch.', $json-data?ref)
                        )
                        
        } catch * {
            (<response
                status="fail">
                <message>{concat($err:code, ": ", $err:description)}</message>
            </response>,
                        gitsync:failedCommitMessage('', $data-collection, concat($err:code, ": ", $err:description))
                        )
        }
};

