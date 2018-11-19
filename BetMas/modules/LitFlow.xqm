xquery version "3.1";
(:~
 : module used to produce Sankey Literatyre Flow Charts
 :
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
 
module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMas/LitFlow";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace local = "http://local.local";
import module namespace math="http://exist-db.org/xquery/math";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";


declare function LitFlow:compareGroups($groups , $g1  as xs:string*, $g2  as xs:string*){
(:select the starting group:)
for $kG1 in $groups//local:group[@key=$g1]/local:keysGroup
(:formats the name of the group prefixing it with the period:)
let $kG1Name := $g1||'/' || $kG1/text() 
(:sequence of keywords definying the starting group:)
let $keys := $kG1/local:key
let $t1 := $kG1/@total

let $pairs := 
(:selects the groups in the target period which share at least one keyword with those of the starting group:)
for $kG2 in $groups//local:group[@key=$g2]/local:keysGroup[local:key=$keys]
(:for each of those target groups formats the name prefixing it with the target period:)
let $kG2Name := $g2||'/' || $kG2/text() 
(:I want to get a figure of the relation between one group and another 
which takes into account the number of attestations and the number of keywords
:)
(:the actual number of shared keywords, the more out of the total, the stronger the connection between two groups
:)
let $totalShared := count($kG2/local:key[. = $keys])

(: the distance between keywords groups (K) is calculated by multiplying the number of keywords in the target group to the shared keywords 
and subtracting from that the result of multiplying the number of keywords in the starting group to the shared keywords
(nk2*sk) - (nk1*sk). a positive difference is an increase in diversity, 0 is the exact same, a negative difference is a descrease in diversity:)

let $distance := (count($kG2/local:key) * $totalShared) - (count($keys) * $totalShared) 

(:the second factor to be taken into consideration is the number of actual attestations:)

let $t2 := $kG2/@total
let $attestationsDelta :=  ($t2 - $t1) 

return 
<pair  xmlns="http://local.local"><name>{$kG2Name}</name><tot>{string($t2)}</tot><D>{$attestationsDelta}</D><K>{$distance}</K></pair>

(:taking the minimum values for D and K, and removing the minus to make them positive. 
I am sure there is a better function for doing this, or a type change, but I have not managed to find it out... :)
let $vectorX := xs:int(replace(string(min($pairs//local:D)), '-', '')) 
let $vectorY := xs:int(replace(string(min($pairs//local:K)), '-', '')) 

(:loop through the pairs and return the weighted distance:)
for $pair in $pairs
(:here the minimum as a positive integer +1 is added to each value so that they all end up 
translated to the upper right quadrant of an XY chart and the positive value of the 
hypothenuse can be used as weight for the data passed to the sankey :)

let $D := 1 + $vectorX + $pair/local:D
let $K := 1 + $vectorY + $pair/local:K

(:Gets the hypothenusa with the distance from 0 of the point determined by the translated coordinates :)
let $pitagora := math:sqrt(math:power($D, 2) + math:power($K, 2))

return 
('["'||$kG1Name ||' ('||  $t1||')", "'  || $pair//local:name/text() ||' (' || $pair//local:tot/text()|| ')", ' || $pitagora || ']')
};

declare function LitFlow:Sankey($filter, $type){
let $AdditionsTypes := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc='Additiones']//t:category/t:catDesc

(:the following selector excludes translations from subject list:)
let $Subjects := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc='Subjects']//t:category/t:catDesc

let $Periods := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc='Periods']//t:category/t:catDesc

let $DW := collection($config:data-rootW)//t:term[@key = $Periods]

let $DatedMss := collection($config:data-rootMS)//t:TEI[descendant::t:term[@key = $Periods]]

let $works := for $dMS in $DatedMss
                            for $key in $dMS//t:term[@key = $Periods]
                            let $root := string(root($key)/t:TEI/@xml:id)
(:                            select only the first level of msItems:)
                            for $WorkInDMS in $dMS//t:msItem[not(parent::t:msItem)]/t:title/@ref
                            return
                            <work mss="{$root}">
                            {$key/@key}
                            {$WorkInDMS}
                            </work>
                            
let $GuestText :=    for $dMS in $DatedMss
                            for $key in $dMS//t:term[@key = $Periods]
(:                            select only the first level of msItems:)
                            for $WorkInDMS in $dMS//t:item[ancestor::t:additions]/t:desc[@type='GuestText']/t:title/@ref
                            return
                            <work>
                            {$key/@key}
                            {$WorkInDMS}
                            </work>                
                            
let $datedWorks := if ($type= 'works') then $DW  else   ($works, $GuestText)         

let $groups := 
<groups>{
for $datedW in $datedWorks
let $period := $datedW/@key
group by $period
return
<group xmlns="http://local.local" total="{count($datedW)}">{$period}
{for $W in $datedW 
let $id := string($W/@ref)

let $root := 
                if ($type= 'works') 
                then root($W)[t:teiHeader/t:profileDesc/t:textClass/t:keywords/t:term[@key=$filter]] 
                else collection($config:data-rootW)/id($id)[t:teiHeader/t:profileDesc/t:textClass/t:keywords/t:term[@key=$filter]]
                
let $keywords := for $k in $root//t:term
                                    where $k/@key = $Subjects
                                    order by $k/@key descending 
                                    return string($k/@key)
let $keywordSequence := replace(string-join($keywords, '-'), '\s+', '')
group by $keywordSequence
return 
if(string-length($keywordSequence) le 0) then () else 
<keysGroup total="{count($W)}">
{$keywordSequence}
{
if(contains($keywordSequence, '-')) then
for $k in tokenize($keywordSequence, '-')

return <key>{$k}</key>

else <key>{$keywordSequence}</key>}
{for $work in $W 
let $id := if($type='works') then string(root($work)/t:TEI/@xml:id) else string($work/@ref)
let $ms := string($work/@mss)
return
<work><id>{$id}</id><mss>{$ms}</mss></work>}

</keysGroup>}
</group>
}</groups>



let $edges := (LitFlow:compareGroups($groups, 'Aks', 'Paks1'), 
LitFlow:compareGroups($groups, 'Paks1', 'Paks2'), 
LitFlow:compareGroups($groups, 'Paks2', 'Gon'), 
LitFlow:compareGroups($groups, 'Gon', 'ZaMa'), 
LitFlow:compareGroups($groups, 'ZaMa', 'MoPe'))
return 
<div class="col-md-12">
    <script type="text/javascript">{
" google.charts.load('current', {'packages':['sankey']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'From');
        data.addColumn('string', 'To');
        data.addColumn('number', 'Weight');
        data.addRows(["
        ||
string-join($edges, ',
') 
||
" ]);
var colors = ['#a6cee3', '#b2df8a', '#fb9a99', '#fdbf6f','#cab2d6', '#ffff99', '#1f78b4', '#33a02c'];
        // Sets chart options.
        var options = {
        height : 800,
           sankey: {
        node: {
          colors: colors
        },
        link: {
          colorMode: 'gradient',
          colors: colors
        }
      }
          
        };

        // Instantiates and draws our chart, passing in some options.
        var chart = new google.visualization.Sankey(document.getElementById('ethioLitFlow"||(if($type='works')
      then "W" else '')||"'));
        chart.draw(data, options);
      }
"}</script>

<div class="col-md-12 alert alert-info">
      {if($type='works')
      then <p class="lead">Work records grouped by period and set of keywords.</p> 
      else <p class="lead">Selection of works linked from first level msItems in manuscripts records.
      Periodization from manuscript, keywords from works.
      Including Guest Texts.</p>
      }
      <p class="lead">Limited to works with the keywords {string-join($filter, ', ')}.</p>
    </div>
<div class="col-md-12" id="ethioLitFlow{(if($type='works')
      then "W" else '')}"/>
<div class="col-md-12">

{for $group in $groups/local:group 
let $per := string($group/@key)
let $order := switch ($per) 
                            case 'PreAks' return 1 
                            case 'Eaks' return 2
                            case 'Aks' return 3
                            case 'Paks1' return 4
                            case 'Paks2' return 5
                            case 'Gon' return 6
                            case 'ZaMa' return 7
                            case 'MoPe' return 8
                            default return 0
order by $order
return 
<div class="col-md-2" style="max-height:600pt; overflow:auto">
<h2>{$per}</h2>
{for $g in $group/local:keysGroup
let $groupName := string($g/parent::local:group/@key) ||'/' || $g/text()
order by $groupName
return
<div >
<h3>{$groupName} ({string($g/@total)})</h3>
<table class="table table-responsive">

<tbody>
{for $work at $p in $g/local:work
return <tr><td>{$p}</td>
<td>
<a href="/{$work/local:id/text()}" class="MainTitle" data-value="{$work/local:id/text()}" target="_blank">{$work/local:id/text()}</a>
{if($type='works')
      then () else 
    (  ' in ',
<a href="/{$work/local:mss/text()}" class="MainTitle" data-value="{$work/local:mss/text()}" target="_blank">{$work/local:mss/text()}</a>)
}
</td></tr>}
</tbody>
</table>
</div>}
</div>}
</div>
</div>
};
