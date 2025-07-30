xquery version "3.1";
declare namespace f = "http://fidal.parser";
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace functx = "http://www.functx.com";

import module namespace morpho="http://betamasaheft.eu/parser/morpho" at "morphoparser.xqm";

(:
qn 
<CV>
        <chars xmlns="http://fidal.parser">
            <syllab>
                <char>ወ</char>
                <firstOrder>ወ</firstOrder>
                <position>1</position>
                <order>1</order>
                <transcription>w</transcription>
            </syllab>
            <syllab>
                <char>ለ</char>
                <firstOrder>ለ</firstOrder>
                <position>2</position>
                <order>1</order>
                <transcription>l</transcription>
            </syllab>
            <syllab>
                <char>ደ</char>
                <firstOrder>ደ</firstOrder>
                <position>3</position>
                <order>1</order>
                <transcription>d</transcription>
            </syllab>
            <syllab>
                <char>ተ</char>
                <firstOrder>ተ</firstOrder>
                <position>4</position>
                <order>1</order>
                <transcription>t</transcription>
            </syllab>
            <syllab>
                <char>ኒ</char>
                <firstOrder>ነ</firstOrder>
                <position>5</position>
                <order>3</order>
                <transcription>n</transcription>
            </syllab>
        </chars>
    </CV>
<query>ወለደተኒ</query>
<formulas>y23 12345 123 123 123 123 1223 1123 11223 1233 W23 1W3 12W W223 11W3 122W WW23 L23 1L3 12L L223 11L3 122L LL23 Y23 1Y3 12Y Y223 11Y3 122Y YY23 W23 1W3 12W W223 11W3 122W WW23 L23 1L3 12L L223 11L3 122L LL23 Y23 1Y3 12Y Y223 11Y3 122Y YY23 W23 1W3 12W W223 11W3 122W WW23 L23 1L3 12L L223 11L3 122L LL23 Y23 1Y3 12Y Y223 11Y3 122Y YY23 y2 1234 12 12 12 12 122 112 1122 123 W2 1W 12 W22 11W 122 WW2 L2 1L 12 L22 11L 122 LL2 Y2 1Y 12 Y22 11Y 122 YY2 W2 1W 12 W22 11W 122 WW2 L2 1L 12 L22 11L 122 LL2 Y2 1Y 12 Y22 11Y 122 YY2 W2 1W 12 W22 11W 122 WW2 L2 1L 12 L22 11L 122 LL2 Y2 1Y 12 Y22 11Y 122 YY2</formulas>
    
qp  
<CV>
        <chars xmlns="http://fidal.parser">
            <syllab>
                <char>ወ</char>
                <firstOrder>ወ</firstOrder>
                <position>1</position>
                <order>0</order>
                <transcription>w</transcription>
            </syllab>
            <syllab>
                <char>ለ</char>
                <firstOrder>ለ</firstOrder>
                <position>2</position>
                <order>0</order>
                <transcription>l</transcription>
            </syllab>
            <syllab>
                <char>ደ</char>
                <firstOrder>ደ</firstOrder>
                <position>3</position>
                <order>0</order>
                <transcription>d</transcription>
            </syllab>
            <syllab>
                <char>ተ</char>
                <firstOrder>ተ</firstOrder>
                <position>4</position>
                <order>0</order>
                <transcription>t</transcription>
            </syllab>
            <syllab>
                <char>ኒ</char>
                <firstOrder>ነ</firstOrder>
                <position>5</position>
                <order>0</order>
                <transcription>n</transcription>
            </syllab>
        </chars>
    </CV>
<query>ወለደተኒ</query>
<formulas>ya2a3a 1a2a3a4a5i 1a2a3a 1a2a3a 1a2a3a 1a2a3a 1a22a3a 11a2a3a 11a22a3a 1a2a33a Wa2a3a 1aWa3a 1a2aWa Wa22a3a 11aWa3a 1a22aWa WWa2a3a La2a3a 1aLa3a 1a2aLa La22a3a 11aLa3a 1a22aLa LLa2a3a Ya2a3a 1aYa3a 1a2aYa Ya22a3a 11aYa3a 1a22aYa YYa2a3a Wa2a3a 1aWa3a 1a2aWa Wa22a3a 11aWa3a 1a22aWa WWa2a3a La2a3a 1ǝLa3a 1La3a 1a2ǝLa 1a2La La22a3a 11ǝLa3a 11La3a 1a22ǝLa 1a22La LLa2a3a Ya2a3a 1aYa3a 1a2aYa Ya22a3a 11aYa3a 1a22aYa YYa2a3a Wa2a3a 1aWa3a 1a2aWa Wa22a3a 11aWa3a 1a22aWa WWa2a3a La2a3a 1aLa3a 1a2aLa La22a3a 11aLa3a 1a22aLa LLa2a3a Ya2a3a 1aYa3a 1a2aYa Ya22a3a 11aYa3a 1a22aYa YYa2a3a ya2a3 1a2a3a4a5 1a2a3 1a2a3 1a2a3 1a2a3 1a22a3 11a2a3 11a22a3 1a2a33 Wa2a3 1aWa3 1a2aW Wa22a3 11aWa3 1a22aW WWa2a3 La2a3 1aLa3 1a2aL La22a3 11aLa3 1a22aL LLa2a3 Ya2a3 1aYa3 1a2aY Ya22a3 11aYa3 1a22aY YYa2a3 Wa2a3 1aWa3 1a2aW Wa22a3 11aWa3 1a22aW WWa2a3 La2a3 1ǝLa3 1a2ǝL La22a3 11ǝLa3 1a22ǝL LLa2a3 Ya2a3 1aYa3 1a2aY Ya22a3 11aYa3 1a22aY YYa2a3 Wa2a3 1aWa3 1a2aW Wa22a3 11aWa3 1a22aW WWa2a3 La2a3 1aLa3 1a2aL La22a3 11aLa3 1a22aL LLa2a3 Ya2a3 1aYa3 1a2aY Ya22a3 11aYa3 1a22aY YYa2a3</formulas>
    
:)
let $transcriptionType := "BM"
let $fuzzy := 'false'
let $type := 'verb'
let $qn := 'ዘኢወለደተኒ'
let $qp := 'ወለደተኒ'
let $test := 
     <realizations xmlns="http://fidal.parser">
            <realization>ው</realization>
            <realization>ወ</realization>
            <realization>ዉ</realization>
            <realization>ዊ</realization>
            <realization>ዋ</realization>
            <realization>ዌ</realization>
            <realization>ው</realization>
            <realization>ዎ</realization>
        </realizations>
let $letter := $test//f:realization[. = 'ወ']
let $letter2 := $morpho:letters//f:realization[. = 'ወ']
for $q in (1 to 2)
return (
('from local with namespace ' || count($letter/preceding-sibling::f:realization)),
('from indexed with namespace ' || count($letter2/preceding-sibling::f:realization)),
('from indexed ignoring namespace ' || count($letter2/preceding-sibling::*:realization))
)