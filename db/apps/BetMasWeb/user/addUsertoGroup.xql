xquery version "3.1";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace console = "http://exist-db.org/xquery/console";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $user := request:get-parameter('user', ());
declare variable $secondarygroup := request:get-parameter('group3', ());


if (sm:is-authenticated() and sm:is-dba(sm:id()//sm:real/sm:username/string()))
    
    then
    try{
let $createAccount := sm:add-group-member($secondarygroup, $user)
return
            try{
            (
            let $contributorMessage := <mail>
                <from>info@betamasaheft.eu</from>
                <to>{sm:get-account-metadata($user, xs:anyURI('http://axschema.org/contact/email'))}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>Welcome to Beta Maṣāḥǝft!</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>You have been added to the group {$secondarygroup} on Beta Maṣāḥǝft</title>
                            </head>
                            <body>
                                <p>Dear {$user}, </p>
                                <p>Your account has been added to the group {$secondarygroup}, inheriting its privileges.</p>
                                <p>Best Regards</p>
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
            
            ,
            
            let $adminMessage := <mail>
                <from>info@betamasaheft.eu</from>
                <to>eugenia.sokolinski@uni-hamburg.de</to>
                <cc></cc>
                <bcc></bcc>
                <subject>User {$user} has been added to the group {$secondarygroup}.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>New account data</title>
                            </head>
                            <body>
                                <p>{$user}, is now also in group {$secondarygroup}.</p>
                              </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
                if (mail:send-email($adminMessage, 'public.uni-hamburg.de', ()))
                then
                    console:log('Sent Message to editor OK')
                else
                    console:log('message not sent to editor')
            
            ,
            
            <html>
                
                <head>
                    <link
                        rel="shortcut icon"
                        href="resources/images/favicon.ico"/>
                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1.0"/>
                    <link
                        rel="shortcut icon"
                        href="resources/images/minilogo.ico"/>
                    <link
                        rel="stylesheet"
                        type="text/css"
                        href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/loadsource.js"></script>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                    
                    <title>Account data update confirmation</title>
                </head>
                <body>
                    <div
                        id="confirmation"><p
                            class="lead">Thank you very much {sm:id()//sm:real/sm:username/string()}!</p>
                        <p>{$user} has been added to {$secondarygroup}</p>
                    
                    </div>
                </body>
            </html>
            )
        }
        catch * {
        
            (
            let $adminMessage := <mail>
                <from>info@betamasaheft.eu</from>
                <to>eugenia.sokolinski@uni-hamburg.de</to>
                <cc></cc>
                <bcc></bcc>
                <subject>a dba has tried to add {$user} to {$secondarygroup} on Beta Maṣāḥǝft and failed.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Failure to add group member</title>
                            </head>
                            <body>
                                <p>{$user}, has not been added to {$secondarygroup}.</p>
                                  <p>{concat($err:code, ": ", $err:description)}</p>
                            </body>
                        </html>
                    </xhtml>
                </message>
            </mail>
            return
                (:send the email:)
                if (mail:send-email($adminMessage, 'public.uni-hamburg.de', ()))
                then
                    console:log('Sent Message to editor OK')
                else
                    console:log('message not sent to editor')
            
            ,
            <html>
                
                <head>
                    <link
                        rel="shortcut icon"
                        href="resources/images/favicon.ico"/>
                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1.0"/>
                    <link
                        rel="shortcut icon"
                        href="resources/images/minilogo.ico"/>
                    <link
                        rel="stylesheet"
                        type="text/css"
                        href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/loadsource.js"></script>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                    
                    <title>Not Authenticated</title>
                </head>
                <body>
                    <div
                        id="confirmation"><p
                            class="lead">Sorry, the system could not add this account to the specified group.</p>
                            <p>{concat($err:code, ": ", $err:description)}</p>
                    
                    </div>
                </body>
            </html>
            )}
    }
    catch * {<html>
                
                <head>
                    <link
                        rel="shortcut icon"
                        href="resources/images/favicon.ico"/>
                    <meta
                        name="viewport"
                        content="width=device-width, initial-scale=1.0"/>
                    <link
                        rel="shortcut icon"
                        href="resources/images/minilogo.ico"/>
                    <link
                        rel="stylesheet"
                        type="text/css"
                        href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/loadsource.js"></script>
                    <script
                        type="text/javascript"
                        src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                    
                    <title>Not Authenticated</title>
                </head>
                <body>
                    <div
                        id="confirmation"><p
                            class="lead">Sorry, {concat($err:code, ": ", $err:description)}</p>
                    
                    </div>
                </body>
            </html>}
    
    else
        (
        <html>
            
            <head>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <link
                    rel="shortcut icon"
                    href="resources/images/minilogo.ico"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                
                <title>Not Authenticated</title>
            </head>
            <body>
                <div
                    id="confirmation"><p
                        class="lead">Sorry, you must be authenticated to perform this action!</p>
                
                </div>
            </body>
        </html>
        )