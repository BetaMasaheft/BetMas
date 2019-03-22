xquery version "3.0" encoding "UTF-8";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "../modules/config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "../modules/editors.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $WorkID := request:get-parameter('id', ());
declare variable $cmlc := request:get-parameter('cmcl', ());
declare variable $bhg := request:get-parameter('bhg', ());
declare variable $bho := request:get-parameter('bho', ());
declare variable $bhl := request:get-parameter('bhl', ());
declare variable $cavt := request:get-parameter('cavt', ());
declare variable $cant := request:get-parameter('cant', ());
declare variable $cpg := request:get-parameter('cpg', ());

if(contains(sm:get-user-groups(xmldb:get-current-user()), 'Editors')) then
let $editor := editors:editorNames(xmldb:get-current-user())
    
    let $getItem :=collection($config:data-rootW)//id($WorkID)
    let $uri := base-uri($getItem)
    let $item := doc($uri)
    let $changes := $item//t:revisionDesc
    let $cc := if($cmlc = 'null' or $cmlc = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0" type="CC"><ptr target="bm:CC"/><citedRange unit="item">{substring-after($cmlc, 'cc')}</citedRange></bibl>
    let $biblcpg := if($cpg = 'null' or $cpg = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0"  type="CPG"><ptr target="bm:CPG1"/><citedRange unit="item">{$cpg}</citedRange></bibl>
    let $biblbho := if($bho = 'null' or $bho = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0" type="BHO"><ptr target="bm:BHO"/><citedRange unit="item">{$bho}</citedRange></bibl>
    let $biblbhl := if($bhl = 'null' or $bhl = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0"  type="BHL"><ptr target="bm:BHL"/><citedRange unit="item">{$bhl}</citedRange></bibl>
    let $biblbhg := if($bhg = 'null' or $bhg = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0"  type="BHG"><ptr target="bm:BHG"/><citedRange unit="item">{$bhg}</citedRange></bibl>
    let $biblcant := if($cant = 'null' or $cant = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0"  type="CANT"><ptr target="bm:CANT1"/><citedRange unit="item">{$cant}</citedRange></bibl>
    let $biblcavt := if($cavt = 'null' or $cavt = '') then () else <bibl  xmlns="http://www.tei-c.org/ns/1.0"  type="CAVT"><ptr target="bm:CAVT2"/><citedRange unit="item">{$cavt}</citedRange></bibl>
                   
    let $allbibl := ($cc, $biblcpg, $biblbho, $biblbhl, $biblbhg, $biblcant, $biblcavt)                            
    let $clavisListBibl := <p xmlns="http://www.tei-c.org/ns/1.0" ><listBibl type="clavis">
    {$allbibl}
               </listBibl></p>
    let $sourceDesc := $item//t:sourceDesc
    let $clavis := $item//t:listBibl[@type='clavis']
    let $updateClavis := if(exists($clavis)) then (
update insert $allbibl into $clavis
    ) else update insert $clavisListBibl into $sourceDesc
    let $updatechanges := update insert <change xmlns="http://www.tei-c.org/ns/1.0" who="{$editor}" when="{format-date(current-date(), "[Y0001]-[M01]-[D01]")}">Added ids matched from the PATHs project via API.</change> into $changes


    (:confirmation page with instructions for editors:)
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
                <link
                    rel="stylesheet"
                    href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="resources/css/style.css"/>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>

                <title>Save Confirmation</title>
            </head>
             <body>
                <div id="confirmation" class="container">
                    <div class="jumbotron">
                    <p
                        class="lead">Thank you very much {xmldb:get-current-user()}!</p>
                    <p>
                        <span
                            class="lead">{$WorkID}</span> has been updated!</p>
                    <p>But <span
                            class="label label-warning confirmationwarning">WAIT!</span> you are <span
                            class="label label-warning confirmationwarning">not yet done</span>...</p>
                    <p>Download the file in your BetMas project's <span
                            class="lead">WORKS</span> folder under <span
                            class="lead">the CORRECT SUBDIRECTORY</span>.<br/>
                        <a
                            id="downloaded"
                            href="{$uri}"
                            download="{$WorkID}.xml"
                            class="btn btn-primary"><i
                                class="fa fa-download"
                                aria-hidden="true"></i> Download</a><br/>
                                open it up and check it is valid and complete. <br/>
                                <span
                            class="label label-warning confirmationwarning">DO THIS!</span><br/>
                        <b>commit it and sync to GIT</b>.</p>
                        <div class="alert alert-warning">
                        <p>If you forget, your changes will be lost next time data is pushed from github or upload.</p> 
                        <p>Don't complain then!</p>
                        </div>
                    <a
                        href="/clavismatching.html">try to match some more works with PATHs/CMCL</a>
                </div>
                </div>
                
                <script
                    type="text/javascript"
                    src="resources/js/confirmonleave.js"/>
            </body>
        </html>
        else 
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
                <link
                    rel="stylesheet"
                    href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="resources/css/style.css"/>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>

                <title>Save Confirmation</title>
            </head>
             <body>
                <div id="confirmation" class="container">
                    <div class="jumbotron">
                    <p
                        class="lead">Sorry {xmldb:get-current-user()}! You have no sufficient rights to use this module.</p>
                    
                        </div>
                    <a
                        href="/">back to home</a>
                </div>
                
                <script
                    type="text/javascript"
                    src="resources/js/confirmonleave.js"/>
            </body>
        </html>
