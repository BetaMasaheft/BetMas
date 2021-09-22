 xquery version "3.1";
 declare namespace t="http://www.tei-c.org/ns/1.0";
(: used to update the list of languages :)
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare variable $local:range-lookup := 
    (
        function-lookup(xs:QName("range:index-keys-for-field"), 4),
        function-lookup(xs:QName("range:index-keys-for-field"), 3)
    )[1];
<TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>List of languages</title>
            </titleStmt>
            <publicationStmt><p/></publicationStmt>
            <sourceDesc><p>Generated from data</p></sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
    <body>
    <list>
{$local:range-lookup('TEIlanguageIdent', '', function($key, $count) {<item xmlns="http://www.tei-c.org/ns/1.0" xml:id="{$key}">{string-join(distinct-values(collection($config:data-root)//t:language[@ident=$key][text()]), ' / ')} </item>}, 100)}
                            
</list>
</body>
</text>
</TEI>
        

        
