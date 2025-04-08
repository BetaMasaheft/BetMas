xquery version "3.1";

(: find filename :)
declare namespace t="http://www.tei-c.org/ns/1.0";

for $doc in collection("/db/apps/") where contains(document-uri($doc), 'BNFabb9.')
order by util:document-id($doc)
return
util:document-id($doc) || ' = '  || base-uri($doc)