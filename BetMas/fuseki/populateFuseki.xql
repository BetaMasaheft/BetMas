xquery version "3.1" encoding "UTF-8";

import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";

(:https://www.w3.org/2019/09/lexicog/:)

(:takes 1 parent URI and a sequence of nested senses:)
declare function local:sense($parentURI as xs:string, $sense){
let $parentURI_comp := $parentURI || '_comp' 
let $nested := for $s in $sense 
              let $senseURI := $parentURI || '_sense_' ||string($s/@xml:id)
              return if($s/t:sense) then local:sense($senseURI, $s/t:sense) else ()
let $nestedLexical := for $s in $sense 
              let $senseURI := $parentURI || '_sense_' ||string($s/@xml:id)
              return $senseURI || ' a ontolex:LexicalSense  . 
              '
let $components := for $s in $sense 
              let $senseURI := $parentURI || '_sense_' ||string($s/@xml:id) 
              let $senseURI_comp := $senseURI || '_comp'
              return $senseURI_comp || ' a lexicog:LexicographicComponent . 
              '
let $describes :=          for $s in $sense 
              let $senseURI := $parentURI || '_sense_' ||string($s/@xml:id) 
              let $senseURI_comp := $senseURI || '_comp'
              return $senseURI_comp || ' lexicog:describes ' || $senseURI || ' .
              '
let $rdfSeq :=  
              for $s at $p in $sense
              let $senseURI := $parentURI || '_sense_' ||string($s/@xml:id)
              let $senseURI_comp := $senseURI || '_comp'
                             return 
	   'rdf:_'||$p||' '|| $senseURI_comp
let $rdfSeqStatement := $parentURI_comp || ' ' || string-join($rdfSeq, '; 
') || ' .
'	   
return
($rdfSeqStatement
,$nested,
$components,
$nestedLexical,
$describes)
};

let $operation := 'INSERT'

let $dictionary := 
       let $tripleslexicon := '
dillmann:lexicon a lexicog:LexicographicResource ;
                    a lime:Lexicon ;
                    lime:language "gez" ; # not sure if this should be different, this is the language about which the lexicon is
	    dc:language "la" . # this is the language in which the lexicon is written
	    dillmann:traces a lexicog:LexicographicResource ;
	    dc:language "en" .
	    dillmann:leslau a lexicog:LexicographicResource ;
	    dc:language "en" .
	    '
return
	    fusekisparql:update('dillmann', $operation, $tripleslexicon)

let $data := collection($config:data-root) 
(:looks for the roots and orders them, so that the next one is the next root:)
let $lexicogEntries := for $lexicogentry in $data//t:rs[@type='root'] order by number($lexicogentry/ancestor::t:entry/@n) return $lexicogentry/ancestor::t:entry
(:takes all the non roots, so that they can be grabbed by looking at @n:)
let $limeEntry := $data//t:entry[not(descendant::t:rs[@type='root'])]

let $triplesentry := 
                for $root in $lexicogEntries
                   let $id := $root/@xml:id
                   let $entryURI := concat('dillmann:',string($id))
                   let $entryN := $root/@n
                   let $entryIndex := index-of($lexicogEntries, $lexicogEntries[@xml:id = $id])
                   let $NextEntryN := $lexicogEntries[$entryIndex[1] +1]/@n  (:added first in sequence because I got a scary "too many operands at the left of  +", hinting at the presence in the root sequence of one o more double numbered entries...:)
                   let $rootentries := ($root, $limeEntry[xs:integer(@n) ge xs:integer($entryN)][xs:integer(@n) lt xs:integer($NextEntryN)])
                   let $rootentriescount := count($rootentries)
                   let $rootmembers := for $member in $rootentries return concat('dillmann:',string($member/@xml:id), '_comp')
                   let $components := for $comp in $rootmembers 
                                                            return  $comp || ' a lexicog:LexicographicComponent ;
                                                             lexicog:describes '||replace($comp, '_comp', '')||' .'
                    let $limentries := for $member in $rootentries return '
                                                         dillmann:lexicon lime:entry dillmann:'||string($member/@xml:id) || ' ;
                                                         rdf:_'||string($member/@n)||' dillmann:'||string($member/@xml:id) || ' . #added, not in document, to represent the general sequence of entries.
                                                         dillmann:'||string($member/@xml:id) ||  ' a ontolex:LexicalEntry .'
                   let $senses := for $en in $rootentries
                                            let $uri := 'dillmann:'||string($en/@xml:id)
                                            return local:sense($uri,$en/t:sense)
                                            
                                                         
                                                         
(:                   roots are both lexicog and lime entries, while non roots are only lime entries.:)
                let $entry :=
           'dillmann:lexicon lexicog:entry  '||$entryURI|| '_entry ;
                                              rdf:_'||string($entryIndex[1])||' '||$entryURI ||'_entry . #added, not in documentation, to sequence the roots in dillmann
            '|| $entryURI || '_entry a lexicog:Entry
                                             '|| (if($rootentriescount ge 1) then ( '; 
                                             rdf:member ' || string-join($rootmembers, ', ') || ' .') else (' .'))||  '
                                             '  ||string-join( $components, '
                   ') ||string-join( $limentries, '
                   ') || '
                   '||string-join($senses, '
                   ')
                   return 
                   fusekisparql:update('dillmann', $operation, $entry)
                   
                   
                                   
let $lexicon := for $entry in ($lexicogEntries, $limeEntry) 
                    let $entryURI := concat('dillmann:',string($entry/@xml:id))
                   let $senses := for $sense in $entry/t:sense
                                                let $senseURI := $entryURI || '_sense_' ||string($sense/@xml:id)
                                                let $definition := if($sense/t:cit[@type="translation"]/t:quote) 
                                                                                    then (for $d in $sense/t:cit[@type='translation']
                                                                                                group by $L := $d/@xml:lang 
                                                                                                   let $values := for $def in $d/t:quote return '"' || $def ||'"@'||string($L)
                                                                                                  return 'skos:definition ' || string-join($values, ', ')) else ()
                                                      return 
                                                ($entryURI || ' ontolex:sense' || ' ' || $senseURI || ' .',
                                                 $senseURI || ' ontolex:isLexicalizedSenseOf ' ||$senseURI||'_concept .',
                                                 $senseURI||'_concept a ontolex:LexicalConcept '||(if(count($definition) ge 1) then (' ; 
                                                                                               ' ||string-join($definition, ' ; 
                                                                                               ') || ' .') else ' .'))
                    let $entry := 
$entryURI || '_form a ontolex:Form ;
       ontolex:writtenRep "'||normalize-space(string-join($entry/t:form//text())) ||'"@gez .

   '||$entryURI||' ontolex:lexicalForm  '||$entryURI||'_form .
   
   ' || string-join($senses, '
')
return
fusekisparql:update('dillmann', $operation, $entry)
       

return
'finished'
