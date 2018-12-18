xquery version "3.1" encoding "UTF-8";
(:~
 :error page returned as rest xq fallback before returning status code
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error";

declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";


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
        
        {apprest:scriptStyle()}
   </head>
   <body>
    {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
<div xmlns="http://www.w3.org/1999/xhtml" class="container alert alert-warning">
    {switch($name('type')) case 'collection' return (<h1>{$name('name')} is not a collection name.</h1>,
    <p class="lead">Available collections are:</p>,
    <ul>{
    for $c in xmldb:get-child-collections($config:data-root)
    return
    <li><a href="/{$c}/list">{$c}</a></li>
    }</ul>,
    <p>You can also see the same items listed by catalogue <a href="/catalogues/list">here</a></p>)
    
    case 'repo' return (
<h1>{$name('name')} is not the id af any available repository.</h1>,<p class="lead">Available repositories are listed <a href="/institutions/list">here</a>.</p>
    )
    case 'catalogue' return (<h1>{$name('name')} is not the id af any available catalogue.</h1>,<p class="lead">Available catalogues are the following:</p>,
    <ul>
    {
   for $catalogue in distinct-values($config:collection-rootMS//t:listBibl[@type='catalogue']//t:ptr/@target)
	let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
order by $data
return
    <li class="lead">
    <a href="/catalogues/{$catalogue}/list">{$data}</a>
    </li>
    }
    </ul>
    )
    case 'item' return (<h1>{$name('name')} is not an available item.</h1>, <ul><li>Ids are case sensitive.</li><li>Try browsing or using simple or advanced search.</li></ul>)
    default return 'There was an error, try again.'}
</div>

        {nav:footer()}
</body>
</html>
};