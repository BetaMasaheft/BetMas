xquery version "3.1";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace console = "http://exist-db.org/xquery/console";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $email := request:get-parameter('email', ());
declare variable $opw := request:get-parameter('oldpassword', ());
declare variable $npw := request:get-parameter('newpassword', ());

let $user := sm:id()//sm:real/sm:username/string()


return
    
    if (sm:is-authenticated())
    
    then
       try{
       (
       sm:passwd($user, $npw),
           let $contributorMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>{sm:get-account-metadata($user, xs:anyURI('http://axschema.org/contact/email'))}</to>
                <cc></cc>
                <bcc></bcc>
                <subject>Your new password for Beta Maṣāḥǝft has been set.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>New account data</title>
                            </head>
                            <body>
                                <p>Dear {$user}, your password has just been reset to: <b>{$npw}</b>.</p>
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
                <subject>A user has reset his/her password on Beta Maṣāḥǝft.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>New account data</title>
                            </head>
                            <body>
                                <p>{$user}, has a new password.</p>
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
                        <p>Your account data has been saved!</p>
                    
                    </div>
                </body>
            </html>
            )
            }
        
        catch *{
            (
            let $adminMessage := <mail>
                <from>pietro.liuzzo@uni-hamburg.de</from>
                <to>pietro.liuzzo@uni-hamburg.de</to>
                <cc></cc>
                <bcc></bcc>
                <subject>A user has tried to reset his/her password on Beta Maṣāḥǝft and failed.</subject>
                <message>
                    <xhtml>
                        <html>
                            <head>
                                <title>Failure to set new account data</title>
                            </head>
                            <body>
                                <p>{$user}, has tried without success to set a new password.</p>
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
                            class="lead">Sorry, the system could not change your password.</p>
                            <p>{concat($err:code, ": ", $err:description)}</p>
                    
                    </div>
                </body>
            </html>
            )}
    
    
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