xquery version "3.1" encoding "UTF-8";
(:~
 : https://github.com/BetaMasaheft/Documentation/issues/920
 : https://github.com/BetaMasaheft/Documentation/issues/1162
 : https://github.com/BetaMasaheft/Documentation/issues/1314
 https://github.com/BetaMasaheft/Documentation/issues/1426 --> function to normalize measure before indexing it
 : @author Pietro Liuzzo 
 :)
module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMas/locus";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

import module namespace r = 'http://joewiz.org/ns/xquery/roman-numerals' at 'roman-numerals.xqm';
import module namespace functx="http://www.functx.com";

declare variable $locus:Regex := '^\d+(r|v)?([a-z])?(\d+)?';
declare variable $locus:RegexProt := '^[xvi]+';
(:
funzione per collegare riferimenti in locus al testo
target=1rv => &ref=1rv oppure (vedi sopra) a .1rv che poi verra rediretto a &ref=1rv
target=1rv 4rv => for each value: come sopra					
from=1r to=3v => &start=1r&end=3v oppure (vedi sopra) a .1r-3v che poi verra rediretto a &start=1r&end=3v
:)

(:
https://github.com/BetaMasaheft/Documentation/issues/1314
for a locus check the entire sequence from available data in a record
and return the actual numeric value in the entire sequence.
<measure unit='leaf'> has most various contents
164 (I + 163), 1-71 + 1(after 91), 1-91, 101.0, 101a-116b, 122 (III + 118 + 42a),
128+4, 134 (1 + 133), 138 + 5, 152 (V + 147), 153ff, 1a-100b and 117ab, 21-188
input: iii+69+iv, usually content of <measure unit="leaf">
returns an XML structure with the breakdown of the informations as 
<measures>
<measure unit="guardleaf" type="front">3</measure>
<measure unit="leaf">69</measure>
<measure unit="guardleaf" type="back">3</measure>
</measures>
:)
declare
%test:arg("value", "i") %test:assertEquals("")
function locus:analyzeMeasure($measure as xs:string*) {
(:   set different parsers for each possible structure and try each:)
let $parsers := (
'([ivx]?)(\+?)(\d{1,3})(\+?)([ivx]?)', (:matches: iii+69+iv, ii+69, 69+i, 69 :)
'(\d{1,3}?)(\+?)(\d{1,3})(\+?)(\d{1,3}?)',  (:matches: 3+69+1, 2+69, 69+1, 69 :)
'', (:134 (1 + 133):)
'' (:152 (V + 147):)
)
for $parser in $parsers
let $analyse:= analyze-string($measure, $parser)
return $analyse
};

(:locus @corresp-- foliation:)

(:
normalize values of locus attributes 
@target --> #1v #2r 
@from and @to --> 1ra

format of the reference is 
folio numer, verso or recto, letter for column.
\d[+]                [v|r]                  \w

but if folio is in protective quire, 
then small roman numerals are used and v(erso)|r(ecto)
which need to be converted to the previous format
:)
declare 
%test:arg('folio', '1ra') %test:assertEquals(1)
%test:arg('folio', '2v') %test:assertEquals(2)
%test:arg('folio', '45ra5') %test:assertEquals(45)
%test:arg('folio', 'iii') %test:assertEquals(3)
%test:arg('folio', 'ivv') %test:assertEquals(4)
%test:arg('folio', 'iir') %test:assertEquals(2)
%test:arg('folio', 'ivv(erso)') %test:assertEquals(4)
%test:arg('folio', 'ir(ecto)') %test:assertEquals(1)
function locus:folio($folio as xs:string) as xs:integer {
    if (matches($folio, $locus:Regex)) then
       replace($folio, '\d+$', '') 
       => replace('[rvabcd]', '') 
       => replace('#', '') 
       => xs:integer()
    else if(matches($folio, $locus:RegexProt))
    then 
    let $strictRomanNumeralMatch := 
(:    https://www.oreilly.com/library/view/regular-expressions-cookbook/9780596802837/ch06s09.html#:~:text=Roman%20numerals%20are%20written%20using,form%20a%20proper%20Roman%20numeral.:)
       analyze-string($folio, '^(x[cl]|l?x*)(i[xv]|v?i*)') 
(:       the regex should match only VALID roman numerals, what will not be achieved is to match
an ambiguous syntax as iv where v could be verso or part of a valid 4 in roman numerals. 
this vails also where iv(erso) is used, because it will match as 4 :)
       return locus:roman-arabic($strictRomanNumeralMatch//s:match//text())
    else
        0
};

(: support better referencing potential for locus as in 
https://github.com/BetaMasaheft/Documentation/issues/1162#issuecomment-608639384
proposal 2 or 3 :)

(:parse locus attributes for columns, recto and verso, folio numer:)

(:given one locus element get the sequence of folio references between @from and @to:)

(:given one locus element get the sequence of folio references listed in @target :)

(:given a series of locus elements, get the sequence of folio references 
involved in all, ordered :)

(:if a value is in roman numerals, convert it to arabic:)
declare
%test:arg("value", "i") %test:assertEquals("1")
%test:arg("value", "iv") %test:assertEquals("4")
%test:arg("value", "xxx") %test:assertEquals("30")
function locus:roman-arabic($value as xs:string*) {
    r:roman-numeral-to-integer(upper-case($value))
};
