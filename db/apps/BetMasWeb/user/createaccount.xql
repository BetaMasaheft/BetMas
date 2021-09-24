xquery version "3.1";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "../modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace console = "http://exist-db.org/xquery/console";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $user := request:get-parameter('userName', ());
declare variable $fullname := request:get-parameter('fullName', ());
declare variable $email := request:get-parameter('email', ());
declare variable $pw := request:get-parameter('password', ());
declare variable $role := request:get-parameter('role', ());
declare variable $maingroup := request:get-parameter('group', ());
declare variable $secondarygroup := request:get-parameter('group2', ());


if (sm:is-authenticated() and sm:is-dba(xmldb:get-current-user()))
    
    then
    try{
let $createAccount := sm:create-account($user, $pw, $fullname, $maingroup, $role)
let $secondaryGroup:= if(empty($secondarygroup))  then () else sm:add-group-member($secondarygroup, $user)
let $addemail := sm:set-account-metadata($user, xs:anyURI('http://axschema.org/contact/email'), $email)
return
            try{
            (
            let $contributorMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>{sm:get-account-metadata($user, xs:anyURI('http://axschema.org/contact/email'))}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>Welcome to Beta Maṣāḥǝft!</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Your account data</title>
                            </head>
                            <body>
                                <p>Dear {$user}, Welcome to Beta Maṣāḥǝft!</p>
                                <p>Your password has just been set to: <b>{$pw}</b>.</p>
                                <p>You can change your password by going to <a href="{$config:appUrl||'/user/'||$user}">your user page</a> where you also find all relevant information about your account.</p>
                                {for $x in sm:get-account-metadata-keys($user) return <p><b>{switch($x) case 'http://exist-db.org/security/description' return 'Role: ' case 'http://axschema.org/namePerson' return 'Full name: ' case 'http://axschema.org/contact/email' return 'E-mail: ' default return ()}</b>  {sm:get-account-metadata($user,$x)}</p>}
                                <p>Thank you very much for your collaboration!</p>
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
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <cc></cc>
                <bcc></bcc>
                <subject>A user account has been created.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>New account data</title>
                            </head>
                            <body>
                                <p>{$user}, has a new account.</p>
                                {for $x in sm:get-account-metadata-keys($user) return <p><b>{$x}</b>:{sm:get-account-metadata($user,$x)}</p>}
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
                            class="lead">Thank you very much {xmldb:get-current-user()}!</p>
                        <p>Your account data has been saved!</p>
                    
                    </div>
                </body>
            </html>
            )
        }
        catch * {
        
            (
            let $adminMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <cc></cc>
                <bcc></bcc>
                <subject>A user has tried to set up an account on Beta Maṣāḥǝft and failed.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Failure to set new account</title>
                            </head>
                            <body>
                                <p>{$user}, has tried without success to set a new account.</p>
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
                            class="lead">Sorry, the system could not create this account.</p>
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