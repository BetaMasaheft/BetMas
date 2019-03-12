 xquery version "3.1";
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";

 (:following list was obtained with the query
 SELECT ?id 
WHERE {
?mss crm:P48_has_preferred_identifier ?id;
a bm:mss ;
dc:contributor 'Nafisa Valieva' .
}
in https://betamasaheft.eu/sparql
:)

let $mss := (
'BAVcerulli37',
'BAVcerulli223',
'BLorient718',
'BLorient719',
'BLEthiopic4',
'BNFabb139',
'EMML6964',
'EMML6931',
'EMML6451',
'EMML6921',
'EMML2836',
'EMML6770',
'EMML7051',
'EMML6592',
'EMML1614',
'DabSey001',
'BetLib001',
'NazMar001',
'MasKa003',
'Parm3852')

(:
Nafisa clear request:
I would like to have a representation of:
which kind of titles contain different manuscripts if contain.
In case of multiple titles manuscripts, which textual units have titles. 

however what we had on the board was
- a table for each msItem with the different titles in it
- a table for each manuscript with the msItems in it
- a table grouping all manuscripts and for each matching msItem the presence or not of any title
- a table with all parts marking the presence or not of different types of titles for that part



BAVcerulli37,
BAVcerulli223,
BLorient718,
BLorient719,
BLEthiopic4,
BNFabb139,
EMML6964,
EMML6931,
EMML6451,
EMML6921,
EMML2836,
EMML6770,
EMML7051,
EMML6592,
EMML1614,
DabSey001,
BetLib001,
NazMar001,
MasKa003,
Parm3852

:)
return
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Gadla Lalibela Textual Units Analysis</title>
        <meta property="dcterms:creator schema:creator" content="Pietro Maria Liuzzo"></meta>
        <meta property="dcterms:creator schema:creator" content="Nafisa Valieva"></meta>
        <meta property="dcterms:rights" content="http://creativecommons.org/licenses/by-sa/4.0/"></meta>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous"></link>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous"></link>
        <link rel="stylesheet" type="text/css" href="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css"></link>
            <link rel="stylesheet" type="text/css" href="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css"></link>
                <script type="text/javascript" src="http://code.jquery.com/jquery-1.11.1.min.js"></script>
                <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>
                <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
        <script type="text/javascript" src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script></head>
      
    <body>{
(<div  class="alert alert-info col-md-12 ">

<ul>
{for $ms in $mss return <li>{titles:printTitleMainID($ms)}</li>}
</ul>
</div>,
<div class="alert alert-success col-md-12 ">The comparison view of Beta maṣāḥǝft, puts side by side the contents of the manuscripts according to how they appear in each ms, i.e. relying on the nested structure of the information.</div>
,
<div><div class="msscomparison col-md-12">
{
        for $ms in $mss
        return
    try {    let $manuscript := $config:collection-rootMS//id($ms)
        let $msid := string($manuscript/@xml:id)
        let $minnotBefore := min($manuscript//@notBefore)
        let $maxnotAfter := min($manuscript//@notAfter)
        order by $minnotBefore
        return

                <div class="card">
                      <div class="card-block">
                                    <h3 class="card-title">
                                        <a href="{('/'||$msid)}">{titles:printTitleMainID($ms)}</a>
                                        ({string($minnotBefore)}-{string($maxnotAfter)})
                                     </h3>
                                    <p class="card-text">
                                        <ul class="nodot">
                                            {for $msitem at $p in $manuscript//t:msItem
                                            (:  store in a variable the ref in the title or nothing:)
                                            let $title := if ($msitem/t:title[@ref]) then $msitem/t:title[1]/@ref else ''
                                            let $placement := if ($msitem/t:locus) then ( ' ('|| (let $locs :=for $loc in $msitem/t:locus return string:tei2string($loc) return string-join($locs, ' ')) || ')') else ''
                                            order by $p
                                            return
                                                    <li style="{if(matches($msitem/@xml:id, '\d+\.\d+\.\d+'))
                                                                            then 'text-indent: 4%;'
                                                                            else if(matches($msitem/@xml:id, '\d+\.\d+'))
                                                                            then 'text-indent: 2%;'
                                                                            else ()}">
                                                        {string($msitem/@xml:id )}
                                                        {if($msitem/t:title/@type)
                                                          then ( ' (' || string($msitem/t:title[1]/@type) || ')')
                                                            else ()}
                                                        {if ($msitem/t:title[not(@ref)]/text())
                                                          then (normalize-space(string-join(string:tei2string($msitem/t:title/node()))), $placement)
                                                          else (<a class="itemtitle" data-value="{$title}" href="{$title}">{
                                                                                if($title = '')
                                                                                then <span class="label label-warning">{'no ref in title'}</span>
                                                                                 else (try{titles:printTitleID($title)} catch * {$title})}</a>, $placement)
                                                                   }
                                                      </li>
                                              }
                                         </ul>
                                     </p>
                     </div>
              </div>
              } catch * {($ms, $err:description)} 
             }
</div></div>
,
<div class="col-md-12 alert alert-success">NAFISA: which kind of titles contain different manuscripts if contain. Pietro Interpretation: 
list distinct counted kinds of title for each manuscript</div>
,
<div class="whichTitlesInMss col-md-12">{
<table class="table table-responsive">
        <thead>
        <tr>
        <th>Kind of Title</th>
        <th>total</th>
        {for $ms in $mss return <th>{$ms}</th>}
        </tr>
        </thead>
        <tbody>{
        let $mssfiles := for $ms in $mss return $config:collection-rootMS//id($ms)
        let $titledstuff := ($mssfiles//t:msItem/t:*[@subtype]/@subtype, $mssfiles//t:msItem/t:*[@type]/@type)
        let $KindsOfTitle := distinct-values($titledstuff)
        for $titleKind in $KindsOfTitle[. != 'complete'][. != 'incomplete'][. != '']
        return
        <tr>
        <td>{$titleKind}</td>
        <td>{count($mssfiles//t:*[@subtype = $titleKind or @type = $titleKind])}</td>
        {for $ms in $mss 
        let $manuscript := $config:collection-rootMS//id($ms)
        let $msCount := count($manuscript//t:*[@subtype = $titleKind or @type = $titleKind])
        return 
        <td>
        <p>{if($msCount le 0 ) then () else 
        ('total: ', 
       count($manuscript//t:msItem/t:*[@subtype = $titleKind or @type = $titleKind])
       ,
       'elements: ',distinct-values($manuscript//t:msItem/t:*[@subtype = $titleKind or @type = $titleKind]/name())
       )
       }</p>
        <ul>
{
for $item in $manuscript//t:msItem/t:*[@subtype = $titleKind or @type = $titleKind]
let $printableTitle := titles:printTitleMainID(string($item/@ref))
return
<li>{string($item/parent::t:msItem/@xml:id)}{' '}{$printableTitle}</li>

}
        </ul>
        </td>}
        
        </tr>
      }</tbody></table> 
        }</div>,
        <div class="alert alert-success col-md-12">
 Look only at identified textual units and see in which mss they have titles with subtype (subscription, inscription, margin, etc.)</div>
,
<div class="whichTextualUnitsHaveTitles col-md-12">{

        let $manuscripts := for $ms in $mss return $config:collection-rootMS//id($ms)
       let $identifiedTU := distinct-values($manuscripts//t:msItem/t:title/@ref)
       return
       (<div class="alert alert-info col-md-12"><p>There are {count($identifiedTU)} identified Textual Units in the manuscripts.</p></div>,
      
       <table class="table table-responsive">
       <thead>
       <tr>
       <th>TU</th>
       {for $ms in $mss return <th>{$ms}</th>}
       </tr>
       </thead>
       <tbody>
        {for $TU in $identifiedTU
       return
       <tr>
       <td>{titles:printTitleMainID($TU)}</td>
       {for $ms in $mss 
       let $manuscriptFile := $config:collection-rootMS//id($ms)
       return 
       <td>
       {
       let $refs := $manuscriptFile//t:title[@ref =$TU]
       return
       if(count($refs) ge 1) then (
       for $r in $refs 
       let $msItem := $r/parent::t:msItem
       group by $MI := $msItem
       let $id := string($MI/@xml:id)
       return
       ($id, <br/>,
       for $tit at $p in $MI/t:title[@subtype] return (if($tit/@subtype) then <b>{string($tit/@subtype)}</b> else ())
       )
       
       ) else ' '}
       </td>
       }
       </tr>
       }
       </tbody>
       </table>
      )
        }</div>,
        <div class="alert alert-success col-md-12">
 Look only at identified textual units and see in which mss they have incipit/explicit/colophon with subtype (subscription, inscription, margin, etc.)</div>
,
<div class="whichTextualUnitsHaveSupplications col-md-12">{

        let $manuscripts := for $ms in $mss return $config:collection-rootMS//id($ms)
       let $identifiedTU := distinct-values($manuscripts//t:msItem/t:title/@ref)
       return
       (<div class="alert alert-info col-md-12"><p>There are {count($identifiedTU)} identified Textual Units in the manuscripts.</p></div>,
      
       <table class="table table-responsive">
       <thead>
       <tr>
       <th>TU</th>
       {for $ms in $mss return <th>{$ms}</th>}
       </tr>
       </thead>
       <tbody>
        {for $TU in $identifiedTU
       return
       <tr>
       <td>{titles:printTitleMainID($TU)}</td>
       {for $ms in $mss 
       let $manuscriptFile := $config:collection-rootMS//id($ms)
       return 
       <td>
       {
       let $refs := $manuscriptFile//t:title[@ref =$TU]
       return
       if(count($refs) ge 1) then (
       for $r in $refs 
       let $msItem := $r/parent::t:msItem
       group by $MI := $msItem
       let $id := string($MI/@xml:id)
       return
       ($id, <br/>,
       if($MI/t:incipit[@type]) then  for $in at $p in $MI/t:incipit[@type] return (if($in/@type) then <b>{string($in/@type)}</b> else ()) else (), <br/>,
       if($MI/t:explicit[@type]) then for $ex at $p in $MI/t:explicit[@type] return  (if($ex/@type) then <b>{string($ex/@type)}</b> else ()) else (), <br/>,
       if($MI/t:colophon[@type]) then for $col at $p in $MI/t:colophon[@type] return (if($col/@type) then <b>{string($col/@type)}</b> else ()) else (),<br/>
       )
       
       ) else ' '}
       </td>
       }
       </tr>
       }
       </tbody>
       </table>
      )
        }</div>

)
}
 <script type="text/javascript">{"
             $(document).ready(function(){
  $('.msscomparison').slick({
    infinite: true,
    swipeToSlide: true,
  slidesToShow: 5,
  slidesToScroll: 5,
  dots: true,
  responsive: [
    {
      breakpoint: 1024,
      settings: {
        slidesToShow: 5,
        slidesToScroll: 5,
        infinite: true,
        dots: true
      }
    },
    {
      breakpoint: 600,
      settings: {
        slidesToShow: 3,
        slidesToScroll: 3
      }
    },
    {
      breakpoint: 480,
      settings: {
        slidesToShow: 1,
        slidesToScroll: 1
      }
    }
    // You can unslick at a given breakpoint now by adding:
    // settings: 'unslick'
    // instead of a settings object
  ]
  });
});
"}        </script>
</body>
</html>
