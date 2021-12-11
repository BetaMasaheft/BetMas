xquery version "3.1";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace console = "http://exist-db.org/xquery/console";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $oldgroup := request:get-parameter('oldgroup', ());

let $user := sm:id()//sm:real/sm:username/string()


return
    
    if (sm:is-authenticated())
    
    then
        try{
        let $rmgroup:=sm:remove-group($oldgroup)
        let $notification := let $adminMessage := <mail>
                <from>info@betamasaheft.eu</from>
                <to>info@betamasaheft.eu</to>
                <cc></cc>
                <bcc></bcc>
                <subject>A group has been deleted in Beta Maṣāḥǝft.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Group {$oldgroup} has been deleted.</title>
                            </head>
                            <body>
                                <p>Group {$oldgroup} has been deleted.</p>
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
            
            return
            
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
                        <p>You have deleted the group {$oldgroup}</p>
                    
                    </div>
                </body>
            </html>
            }
        
        catch * {
           let $notification:= let $adminMessage := <mail>
                <from>info@betamasaheft.eu</from>
                <to>info@betamasaheft.eu</to>
                <cc></cc>
                <bcc></bcc>
                <subject>User {$user} has tried to delete the account {$oldgroup} from Beta Maṣāḥǝft.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Failure to delete  account </title>
                            </head>
                            <body>
                                <p>{$user}, has tried without success to delete {$oldgroup}.</p>
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
            
            return
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
                    
                    <title>Account not deleted</title>
                </head>
                <body>
                    <div
                        id="confirmation"><p
                            class="lead">Sorry, the system could not delete the group.</p>
                    
                                <p>{concat($err:code, ": ", $err:description)}</p>
                    </div>
                </body>
            </html>
            }
    
    
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