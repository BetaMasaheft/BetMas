xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the app for login and logout
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
import module namespace locallogin="https://www.betamasaheft.eu/login" at "../modules/login.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "../modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace console = "http://exist-db.org/xquery/console";
declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

let $test1 := console:log(xmldb:get-current-user())
let $logout := locallogin:logout()
let $test2 := console:log(xmldb:get-current-user())
return


<html>
    <head>
        
        <title>Login</title>
        <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport"></meta>
        <link rel="shortcut icon" href="$shared/resources/images/exist_icon_16x16.ico"></link>
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap-3.0.3.min.css"></link>
        <link href="resources/css/font-awesome.min.css" rel="stylesheet" type="text/css"></link>
        <link href="resources/css/ionicons.min.css" rel="stylesheet" type="text/css"></link>
        <link href="resources/css/AdminLTE.css" rel="stylesheet" type="text/css"></link>
        <link href="resources/css/skin-black.min.css" rel="stylesheet" type="text/css"></link>
        <link rel="stylesheet" type="text/css" href="resources/css/style.css"></link>
        <script type="text/javascript" src="$shared/resources/scripts/jquery/jquery-1.7.1.min.js"></script>
        <script type="text/javascript" src="resources/scripts/app.js"></script>
        <script type="text/javascript" src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
    </head>
    <body>
<div>
    <form action="/auth/login.xql" method="post" >
        <div class="form-group">
            <input type="text" name="user" class="form-control" placeholder="User ID" autofocus="autofocus"/>
        </div>
        <div class="form-group">
            <input type="password" name="password" class="form-control" placeholder="Password"/>
        </div>
        <div class="row">
            <div class="col-md-12">
                <button type="submit" class="btn btn-primary btn-block btn-flat">Sign in</button>
            </div>
        </div>
    </form>
</div></body>
</html>