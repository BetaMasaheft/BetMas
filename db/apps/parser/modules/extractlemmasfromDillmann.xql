xquery version "3.1";
import module namespace config = "http://betamasaheft.aai.uni-hamburg.de:8080/exist/apps/gez-en/config" at "config.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";


<lemmas xmlns="http://fidal.parser">
{for $lemma in $config:collection-root//t:entry[starts-with(@xml:id, 'L')]
order by $lemma/@n
return
<lemma>
{$lemma/@xml:id}
{$lemma/@n}
{if($lemma/t:form/t:rs[@type='root']) then attribute type{'root'} else ()}
{$lemma/t:form/t:foreign}
<translation>{string-join($lemma//t:cit[@type='translation']/t:quote/text(), ', ')}</translation></lemma>
}
</lemmas>