xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
let $IDpart := "[contains(@xml:id, 'BNF')]"
let $wt := "[@type = 'mss']"
let $repository := "[descendant::t:repository[@ref = 'INS0303BNF']]"
let $path := concat("collection('/db/apps/BetMas/data/')//t:TEI", $IDpart, $wt)
let $path1 := concat("collection('/db/apps/BetMas/data/')//t:TEI", $repository)
let $selection := util:eval($path)
let $selection1 := util:eval($path1)
             (:
             $repository, $mss, $texts, $script, $support, $material, $bmaterial, $placeType, $personType, $relationType, $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, $binders, $contents, $authors, $tabots, $genders, $dateRange, $leaves, $wL, $references, $height, $width, $depth, $marginTop, $marginBot, $marginL, $marginR, $marginIntercolumn, $nOfP
             :)
for $hit in $selection  
return $hit 