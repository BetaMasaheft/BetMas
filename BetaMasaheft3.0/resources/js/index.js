/*$('#academics').on('ready', function () {

(: ~ lists all persons with occupation type academic :)
declare function app:academics($node as node()*, $model as map(*)){
<div id="academics">
<h4>Scholars in Ethiopian Studies</h4>
<div class="card-columns">{
for $academic in collection($config:data-rootPr)//t:occupation[@type='academic']
let $title := normalize-space(string(titles:printTitle($academic)))
let $zoterurl := 'https://www.zotero.org/groups/ethiostudies/items/q/'||xmldb:encode-uri($title)
let $root := root($academic)
let $id := $root//t:TEI/@xml:id
let $date := ($root//t:body//t:*[@notBefore or @notAfter or @when], $root//t:floruit)
let $dates := ($date/@notBefore, $date/@notAfter, $date/@when)
let $years := for $d in $dates return if (contains(string($d), '-')) then substring-before(string($d),'-') else string($d)
let $mindate := min($years)
order by $mindate
return
<div class="card">
    <div class="card-block">
      <h4 class="card-title"><a href="/{string($id)}" target="_blank">{$title}</a></h4>
      <p class="card-text">{$academic/text()}</p>
      <p class="card-text"><small class="text-muted">{$mindate || ' - '||max($years)}</small></p>
      <p class="card-text academicBio">{transform:transform($root, 'xmldb:exist:///db/apps/BetMas/xslt/bio.xsl',())}</p>
      <p class="card-text"><a  href="{$zoterurl}" target="_blank">Items in Zotero EthioStudies</a></p>
 <p class="card-text">{if(starts-with($root//t:person/@sameAs, 'Q')) then app:wikitable(string($root//t:person/@sameAs)) else ($root//t:person/@sameAs)}</p>

    </div>
  </div>}
  </div>
  </div>
};

});

$('#latest').on('ready', function () {


(:collects all the latest changes made to the collections and prints a list of twenty items:)
declare function app:latest($node as element(), $model as map(*)){

let $twoweekago := current-date() - xs:dayTimeDuration('P15D')
let $changes := collection($config:data-root)//t:change[@when]
let $latests := 
    for $alllatest in $changes[xs:date(@when) > $twoweekago]
    order by xs:date($alllatest/@when) descending
    return $alllatest

for $latest at $count in subsequence($latests, 1, 20)
let $id := string(root($latest)/t:TEI/@xml:id)
return
<li><a href="{$id}">{titles:printTitle($latest)}</a>: on {string($latest/@when)}, {editors:editorKey($latest/@who)} [{$latest/text()}]</li>

};


});
*/
$(document).on('ready', function () {

$.getJSON('/api/latest', function(data){
    var latest = $('#latest')
    var length = data.length
    for (i = 0; i < length; i++) { 
    $(latest).append('<li><a href="'+data[i].id+'">'+data[i].title+'</a>: on '+data[i].when+', '+data[i].who+' ['+data[i].what+']</li>')
    }
});

/*(:displaies on the hompage the totals of the portal:)*/
$.getJSON('/api/count', function(data){
    var count = $('#count')
    var total = data.total
    var tms = data.totalMS
    var tp = data.totalPersons
    var tw = data.totalWorks
    var ti = data.totalInstitutions
    var diff = total - (tms + tp + tw + ti)
    $(count).append('<p>There are <b class="lead">'+total+'</b> searchable and browsable items in the app. </p>')
    $(count).append("<p><b  class='lead'>"+ti+"</b> are Repositories holding Ethiopian Manuscripts. </p>")
    $(count).append("<p><b  class='lead'>"+tms+"</b> are Manuscript's Catalogue Records.  </p>")
    $(count).append("<p><b  class='lead'>"+tw+"</b> are Text units, Narrative units or literary works.</p>")
    $(count).append("<p><b  class='lead'>"+tp+"</b> are Records about people, groups, ethnic or linguistic groups. </p>")
    $(count).append("<p>The other " +diff+" records are Authority files and places which are not repositories. </p>")
    
});

$.getJSON('/api/academics', function(data){
    var acs = $('#academicscards')
    var length = data.length
    
    for (i = 0; i < length; i++) {
    var id = data[i].id
var tit = data[i].title
var txt = data[i].text
var dd = data[i].dates
var bio = data[i].bio
var zot = data[i].zoturl
var wd = data[i].wd

    $(acs).append('<div class="card"><div class="card-block"><h4 class="card-title"><a href="/'+id+'" target="_blank">'+tit+'</a></h4><p class="card-text">'+txt+'</p><p class="card-text"><small class="text-muted">'+dd+'</small></p><p class="card-text academicBio">'+bio+'</p><p class="card-text"><a  href="'+zot+'" target="_blank">Items in Zotero EthioStudies</a></p><p class="card-text">'+wd+'</p></div></div>')
    }
    });

});