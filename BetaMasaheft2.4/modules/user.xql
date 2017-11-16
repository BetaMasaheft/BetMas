xquery version "3.1" encoding "UTF-8";
(:~
 : module for the user personal page view
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace user = "https://www.betamasaheft.uni-hamburg.de/BetMas/user";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log = "http://www.betamasaheft.eu/log" at "log.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console"; (:
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";:)
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
at "resource:org/exist/xquery/lib/kwic.xql";

(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: made up namespace for log:)
declare namespace l = "http://log.log";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare
%rest:GET
%rest:POST
%rest:path("/BetMas/user/{$username}")
%output:method("html5")
function user:personalPage($username as xs:string) {
let $Imap := map {'type':= 'user', 'name' := $username}
let $test := console:log($username)
let $test2 := console:log(xmldb:get-current-user())

return 

    if (sm:is-dba(xmldb:get-current-user()) or (($username = xmldb:get-current-user()) 
    and sm:is-account-enabled(xmldb:get-current-user()) 
    and sm:is-authenticated()))
    then
    (
    log:add-log-message('/user/' || $username, xmldb:get-current-user(), 'user'),
    <rest:response>
        <http:response
            status="200">
            <http:header
                name="Content-Type"
                value="text/html; charset=utf-8"/>
        </http:response>
    </rest:response>,
    <html
        xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <title
                property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
            <link
                rel="shortcut icon"
                href="resources/images/favicon.ico"/>
            <meta
                name="viewport"
                content="width=device-width, initial-scale=1.0"/>
            {apprest:scriptStyle()}
        </head>
        <body
            id="body">
            {nav:bar()}
            {nav:modals()}
            {nav:searchhelp()}
            
            <div
                id="content"
                class="container-fluid col-md-12">
                <h2>Dear {$username}, thank you very much for all your nice work for the project!</h2>
                <div
                    class="col-md-12">
                    <div class="col-md-12 alert alert-success">
                    <h2>All about you... </h2>
                    <p><b>User name: </b> {$username}</p>
                    <p><b>Member of: </b>{let $groups := for $g in sm:get-user-groups($username) return $g return string-join($groups, ', ')}</p>
                    {for $x in sm:get-account-metadata-keys($username) return <p><b>{switch($x) case 'http://exist-db.org/security/description' return 'Role: ' case 'http://axschema.org/namePerson' return 'Full name: ' case 'http://axschema.org/contact/email' return 'E-mail: ' default return ()}</b>  {sm:get-account-metadata($username,$x)}</p>}
                    </div>
                    <div
                        class="col-md-6 alert alert-info">
                        {let $userinitials := app:editorNames($username)
                                    let $changes := collection($config:data-root)//t:change[@who = $userinitials]
                                    let $changed := for $c in $changes
                                    order by $c/@when descending
                                    return $c
                                        return
                                        (
                                        <h3>Your latest 50 changes in files out of {count($changes)} you made</h3>,
                        <div  class=" col-md-12 userpanel"><table
                                class="table table-responsive"><thead><tr><th>date and time</th><th>item</th></tr></thead><tbody>{
                                    
                                    for $itemchanged in subsequence($changed, 1, 50)
                                    return
                                        <tr>
                                        <td>{format-date($itemchanged/@when, "[D01].[M01].[Y1]")}</td>
                                        <td><a
                                                href="/{string(root($itemchanged)/t:TEI/@xml:id)}">{titles:printTitle($itemchanged)}</a></td></tr>
                                }</tbody></table></div>
                                )
                                }
                    </div>
                    <div
                        class="col-md-6"><h3>The last 50 pages you visited</h3>
                        <div  class=" col-md-12 userpanel"><table
                                class="table table-responsive"><thead><tr><th>type</th><th>date and time</th><th>info</th></tr></thead><tbody>{
                                       let $selection :=  for $c in doc('/db/apps/BetMas/log/bm-log.xml')//l:logentry[l:user[. = $username]][not(l:type[.='query'])][not(contains(l:type, 'XPath'))]
                                                                  order by $c/@timestamp descending
                                                                  return $c
                                       for $loggedentity in subsequence($selection, 1, 50)
                                        return
                                            <tr><td>{$loggedentity/l:type/text()}</td><td>{
                                            format-dateTime($loggedentity/@timestamp,
                 "[D01].[M01].[Y1] [H01]:[m01]:[s01]")
                                            }</td><td><a 
                                            href="{switch($loggedentity/l:type)
                                            case 'compare' return $config:appUrl || '/compare' || $loggedentity/l:url/text()
                                            default return $loggedentity/l:url/text()}">{$loggedentity/l:url/text()}</a></td></tr>
                                    }</tbody></table>
                        </div>
                    </div></div>
                <div
                    class="col-md-12">
                    <div
                        class="col-md-6"><h3>Your queries</h3>
                        <div  class="col-md-12 userpanel"><table
                                class="table table-responsive"><thead><tr><th>date</th><th>info</th></tr></thead><tbody>{
                                       let $selection := for $c in doc('/db/apps/BetMas/log/bm-log.xml')//l:logentry[l:user[. = $username]][l:type[.='query']]
                                                                 order by $c/@timestamp descending
                                                                  return $c
                                       for $loggedentity in subsequence($selection, 1, 50) 
                                        let $link := '/search.html' || $loggedentity/l:url/text()
                                        return
                                            <tr><td>{format-dateTime($loggedentity/@timestamp,
                 "[D01].[M01].[Y1] [H01]:[m01]:[s01]")}</td><td><a href="{$link}">{$loggedentity/l:url/text()}</a></td></tr>
                                    }</tbody></table>
                        </div>
                        </div>
                        <div
                        class="col-md-6 alert alert-info"><h3>Your XPATHs</h3>
                        <div class="userpanel"><table
                                class="table table-responsive"><thead><tr><th>date</th><th>info</th></tr></thead><tbody>{
                                       let $selection := for $c in doc('/db/apps/BetMas/log/bm-log.xml')//l:logentry[l:user[. = $username]][contains(l:type, 'XPath')]
                                                                 order by $c/@timestamp descending
                                                                  return $c
                                       for $loggedentity in subsequence($selection, 1, 50) 
                                       let $link := '/xpath?xpath=' || $loggedentity/l:url/text()
                                        return
                                            <tr><td>{format-dateTime($loggedentity/@timestamp,
                 "[D01].[M01].[Y1] [H01]:[m01]:[s01]")}</td><td><a href="{$link}">{$loggedentity/l:url/text()}</a></td></tr>
                                    }</tbody></table>
                        </div>
                        </div>
                    </div>
                    <div
                        class="col-md-12 alert alert-warning"><h3>Manage your account</h3>
                        <div
                        class="col-md-12 ">
                        <h4>change email</h4>
                        <form
                            action="/user/changemail.xql" method="POST">
                            <div class="form-group">
    <label for="exampleInputEmail1">Email address</label>
    <input type="email" class="form-control" id="email"name="email" aria-describedby="emailHelp" placeholder="Enter email"></input>
    <small id="emailHelp" class="form-text text-muted">This is needed for the website notifications.</small>
  </div>
  
  <button type="submit" class="btn btn-primary">Submit</button>
                            </form>
                            </div>
                            <div
                        class="col-md-12 ">
                            <h4>Change password</h4>
                            <form
                            action="/user/changepw.xql" method="POST">
                            <div class="form-group">
    <label for="exampleInputEmail1">Email address</label>
    <input type="email" class="form-control" id="email"name="email" aria-describedby="emailHelp" placeholder="Enter email"></input>
    <small id="emailHelp" class="form-text text-muted">This is needed for the website notifications.</small>
  </div>
  <div class="form-group">
    <label for="exampleInputPassword1">Old Password</label>
    <input type="password" class="form-control" id="oldpassword" name="oldpassword"  placeholder="Old Password"></input>
  </div>
  <div class="form-group">
    <label for="exampleInputPassword1">New Password</label>
    <input type="password" class="form-control" id="newpassword" name="newpassword"  placeholder="New Password"></input>
  </div>
  <button type="submit" class="btn btn-primary">Submit</button>
                            </form>
                            </div>
                            </div>
                            {if(sm:is-dba(xmldb:get-current-user())) then 
                             (<div
                        class="col-md-12 alert alert-success">
                        <h3>Create new account</h3>
                        <form
                            action="/user/createaccount.xql" method="POST">
                           <div class="form-group">
    <label for="fn">Full name</label>
    <input class="form-control" id="fn" name="fullName" aria-describedby="emailHelp" placeholder="Enter your full name" required="required"></input>
    </div>
  <div class="form-group">
    <label for="un">user name</label>
    <input  class="form-control" id="un" name="userName" aria-describedby="emailHelp" placeholder="select a user name" required="required"></input>
    <small id="emailHelp" class="form-text text-muted">Check that this is not already used!</small>
  </div>
                           <div class="form-group">
    <label for="mail">Email address</label>
    <input type="email" class="form-control" id="mail" name="email" aria-describedby="emailHelp" placeholder="Enter email" required="required"></input>
    <small id="emailHelp" class="form-text text-muted">This is needed for the website notifications.</small>
  </div>
  <div class="form-group">
    <label for="pw">Password</label>
    <input type="password" class="form-control" id="pw" name="password"  placeholder="Password" required="required"></input>
  </div>
  
  <div class="form-group">
    <label for="role">Role</label>
    <input type="text" class="form-control" id="role" name="role"  placeholder="role description" required="required"></input>
  </div>
  
  <div class="form-group">
    <label for="primarygroup">Select group</label>
    <select class="form-control" id="primarygroup" name="group" required="required">
    <option selected="selected">Please chose</option>
      {for $g in  sm:get-groups()
      order by count(sm:get-group-members($g)) descending
      return <option value="{$g}">{$g}</option>}
    </select>
  </div>
  <div class="form-group">
    <label for="group2">Secondary Group</label>
    <select class="form-control" id="group2" name="group2">
    <option selected="selected" disabled="disabled">none</option>
      {for $g in sm:get-groups()
      return if($g = 'dba') then () else <option value="{$g}">{$g}</option>}
    </select>
  </div>
  <button type="submit" class="btn btn-primary">Submit</button>
                            </form>
                            </div>,
                            
                            <div class="col-md-12  alert alert-warning">
                            <h3>Add user to group</h3>
                            <form action="/user/addUsertoGroup.xql" method="POST">
                             <div class="form-group">
    <label for="group2">user</label>
    <select class="form-control" id="user" name="user">
    <option selected="selected" disabled="disabled">none</option>
      {for $g in sm:list-users() return <option value="{$g}">{$g}</option>}
    </select>
  </div>
                            <div class="form-group">
    <label for="group2">Secondary Group</label>
    <select class="form-control" id="group3" name="group3">
    <option selected="selected" disabled="disabled">none</option>
      {for $g in sm:get-groups() return
     <option value="{$g}">{$g}</option>}
    </select>
    
  </div>
    
  <button type="submit" class="btn btn-primary">Submit</button>
    </form>
                            </div>,
                            <div class="col-md-12">
                            <div  class="col-md-6">There are currently the following users in this eXist-db instance
                
                <table  class="table table-responsive"><thead><tr><th>user</th><th>metadata</th></tr></thead><tbody>{
                        for $u in sm:list-users()
                        return
                            (<tr>
                            <td>{$u}</td>
                            <td>{if(sm:is-dba($u)) then 'dba' else 'user'}</td>
                            </tr>, 
                            <tr>
                            <td></td>
                            <td>{for $x in sm:get-account-metadata-keys($u) return <p><b>{$x}</b>:{sm:get-account-metadata($u,$x)}</p>}</td>
                            </tr>)
                    }</tbody></table>
            </div>
            <div  class="col-md-6">There are currently the following groups in this eXist-db instance
                
                <table class="table table-responsive"><thead><tr><th>group</th><th>members</th></tr></thead><tbody>{
                        for $u in sm:get-groups()
                        order by count(sm:get-group-members($u)) descending
                        return
                            <tr><td>{$u}</td><td>{
                                    <ul>
                                        {
                                            for $m in sm:get-group-members($u)
                                            return
                                                <li>{$m}</li>
                                        }
                                    </ul>
                                }</td></tr>
                    }</tbody></table>
            </div>
                            </div>,
<div
                        class="col-md-12 alert alert-danger">
                        <h3>Delete account</h3>
                        <form
                            action="/user/deleteaccount.xql" method="POST">
                           
  <div class="form-group">
    <label for="un">user name</label>
    <input class="form-control" id="un" name="olduser" aria-describedby="emailHelp" placeholder="select a user name"></input>
    <small id="Help" class="form-text text-muted">Be very sure!</small>
  </div>
                        
  <button type="submit" class="btn btn-primary">Submit</button>
                            </form>
                            </div>,
<div
                        class="col-md-12 alert alert-danger">
                        <h3>Delete group</h3>
                        <form
                            action="/user/deletegroup.xql" method="POST">
                           
  <div class="form-group">
<label for="grouptobedeleted">Select group to be deleted</label>
    <select class="form-control" id="grouptobedeleted" name="oldgroup">
      {for $g in  sm:get-groups()
      return <option value="{$g}">{$g}</option>}
    </select>
    <small id="delgroupHelp" class="form-text text-muted">Be very sure!</small>
  </div>
                        
  <button type="submit" class="btn btn-primary">Submit</button>
                            </form>
                            </div>
                            )
                            else ()}
            </div>
        </body>
    </html>)
    else (<rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Imap))
};
