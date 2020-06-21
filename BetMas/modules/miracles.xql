xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMas/locus" at "xmldb:exist:///db/apps/BetMas/modules/locus.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
'BMid,	bibliography,	Incipit text,	Note to the incipit,	Link to record in Beta Masaheft,	english titles separated by |, in MSS, total mss',
for $miracle in $config:collection-rootW//t:relation[@name='saws:formsPartOf'][@passive='LIT2384Taamme'][@active="LIT3615Miracle"]
let $bmid := string($miracle/@active)
let $link := 'https://betamasaheft.eu/'||$bmid
let $textlink := 'https://betamasaheft.eu/works/'||$bmid||'/text'
let $miraclefile := $config:collection-rootW/id($bmid)
let $entitles := replace(string-join($miraclefile//t:title[@xml:lang='en'], ' | '), ',', '')
let $bibl := for $bib in $miraclefile//t:bibl return
<span class="Zotero-citation" 
           data-value="{$bib/t:ptr/@target}" 
           data-unit="{$bib/t:citedRange[1]/@unit}" 
           data-range="{$bib/t:citedRange[1]/text()}">{string($bib/t:ptr/@target)}</span>
let $incipit := replace(string-join($miraclefile//t:div[@subtype='incipit']/t:ab/text(), ' '), ',', '')
let $incipitnote := replace(string-join(string:tei2string($miraclefile//t:div[@subtype='incipit']/t:note), ' '), ',', '')
let $mss := $config:collection-rootMS//t:title[@ref= $bmid]

return
<tr>
<td><a href="{$link}">{titles:printTitleMainID($bmid)}</a> ({$bmid})</td>
<td>{normalize-space($entitles)}</td>
<td>{$bibl}</td>
<td>{normalize-space($incipit)} <a href="{$textlink}">available text</a></td>
<td>{$incipitnote}</td>
<td><table>
<thead><tr>
<td>manuscript</td>
<td>placement</td>
<td>position</td>
<td>word count</td>
<td>total miracles</td>
<td>1/4</td>
<td>2/4</td>
<td>3/4</td>
<td>4/4</td>
</tr></thead><tbody>{
for $m in $mss
                        let $root :=string(root($m)/t:TEI/@xml:id)
                        
                        let $msitem := $m/parent::t:msItem
                        let $placement := if ($m/preceding-sibling::t:locus) then (locus:stringloc($m/preceding-sibling::t:locus)) else ''
                        let $number := count($msitem/preceding-sibling::t:msItem) +1
                        let $totalparts := count($msitem/parent::t:*/child::t:msItem)
                        let $position :=$number || '/' || $totalparts
                         let $works := for $w in $msitem/ancestor::t:TEI//t:msItem/t:title/@ref 
                                              return $config:collection-rootW/id($w)//t:keywords
                         let $totalmiracles := count($works//t:term[@key = 'Miracle'])                         
                        return 
                        <tr>
                        <td><a href="https://betamasaheft.eu/{$root}">{titles:printTitleMainID($root)}</a></td>
                        <td>{$placement}</td>
                        <td>{$position}</td>
                        <td><span class="WordCount" data-msID="{$root}" data-wID="{$bmid}"/></td>
                        <td>{$totalmiracles} </td>
                        <td class="{$bmid}firstquarter">{if($number le ($totalparts div 4)) then 'x' else ''}</td>
                        <td class="{$bmid}secondquarter">{if(($number le ($totalparts div 2)) and ($number gt ($totalparts div 4))) then 'x' else ''}</td>
                        <td class="{$bmid}thirdquarter">{if(($number gt ($totalparts div 2)) and ($number le (($totalparts div 4) + ($totalparts div 2)))) then 'x' else ''}</td>
                        <td class="{$bmid}fourthquarter">{if($number gt (($totalparts div 4) + ($totalparts div 2))) then 'x' else ''}</td>
                        </tr>
                        
}
<tr><td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td class="{$bmid}percentfirstquarter">percent in 1/4</td>
<td class="{$bmid}percentsecondquarter">percent in 2/4</td>
<td class="{$bmid}percentsecondtquarter">percent in 3/4</td>
<td class="{$bmid}percentsecondquarter">percent in 4/4</td>
</tr>
</tbody></table></td>
<td>{count($mss)}</td>
<td><a href="https://betamasaheft.eu/compare?workid={$bmid}">Compare manuscript structure</a></td>
<td><a href="https://betamasaheft.eu/workmap?worksid={$bmid}">Map of Mss current location</a>
<a href="https://betamasaheft.eu/workmap?worksid={$bmid}">Map of Mss place of origin </a></td>
</tr>
