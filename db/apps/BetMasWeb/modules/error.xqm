xquery version "3.1" encoding "UTF-8";
(:~
 :error page returned as rest xq fallback before returning status code
 : 
 : @author Pietro Liuzzo 
 :)
module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";


declare function error:error($name as map(*)){
switch($name('type'))
case 'user' return 

<html xmlns="http://www.w3.org/1999/xhtml">
    <head></head>
    <body>
    <h1>Either you are not requesting your personal account or the account {$name('name')} is not an enabled account or you are not authenticated.</h1> 
    </body>
    </html>
case 'xmlitem' return 

<html xmlns="http://www.w3.org/1999/xhtml">
    <head></head>
    <body>
    <h1>{$name('name')} is not an available item.</h1> 
    </body>
    </html>
default return
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        
        {scriptlinks:scriptStyle()}
   </head>
   <body>
    {nav:barNew()}
        {nav:modalsNew()}
<div xmlns="http://www.w3.org/1999/xhtml" class="w3-container w3-card-4 w3-red w3-margin w3-padding-64">
    {switch($name('type')) case 'collection' return (<h1>{$name('name')} is not a collection name.</h1>,
    <p class="lead">Available collections are:</p>,
    <ul>{
    for $c in xmldb:get-child-collections($config:data-root)
    return
    <li><a href="/{$c}/list">{$c}</a></li>
    }</ul>,
    <p>You can also see the same items listed by catalogue <a href="/catalogues/list">here</a></p>)
    
    case 'repo' return (
<h1>{$name('name')} is not the id af any available repository.</h1>,<p class="w3-large">Available repositories are listed <a href="/institutions/list">here</a>.</p>
    )
    case 'catalogue' return (<h1>{$name('name')} is not the id af any available catalogue.</h1>,<p class="w3-large">Available catalogues are the following:</p>,
    <ul>
    {
   for $catalogue in config:distinct-values(collection($config:data-rootMS)//t:listBibl[@type eq 'catalogue']//t:ptr/@target)
	let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
 let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    let $data := http:send-request($request)[2]
order by $data
return
    <li class="w3-large">
    <a href="/catalogues/{$catalogue}/list">{$data}</a>
    </li>
    }
    </ul>
    )
    case 'item' return (<h1>{$name('name')} is not an available item.</h1>, <ul><li>Ids are case sensitive.</li><li>Try browsing or using simple or advanced search.</li></ul>)
    default return 'There was an error, try again.'}
</div>

        {nav:footerNew()}
</body>
</html>
};