xquery version "3.0" encoding "UTF-8";
(:~
 : new entry form 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace new="https://www.betamasaheft.uni-hamburg.de/BetMas/new";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console";


(:this is a small form that points to the xquery generating the new file and prompting the editor to save it in the correct location:)
declare function new:newentry($node as node()*, $model as map(*)) {
     let $option := switch($app:collection) 
     case 'manuscripts' return ''
     default return 'last part of the'
     return
         
    
<form id="createnew" action="edit/save-new-entity.xql">
<p>Great! So you are creating a new record in <span class="lead">{$app:collection}</span>!</p>
<fieldset class="form-group">
<legend>General data</legend>
<div class="form-group">
<input class="form-control" type="hidden" name="collection" value="{$app:collection}" />
</div>
<div class="form-group">
<label for="suffix" class="col-md-2 col-form-label">ID</label>
<div class="col-md-10"><input  class="form-control" id="suffix" name="suffix"  required="required"></input>
<small class="form-text text-muted">type here the {$option} new id</small></div>
</div>
<div class="form-group">
<label for="title"  class="col-md-2 col-form-label">Title</label>
<div class="col-md-10"><input  class="form-control"  id="title" name="title" required="required"></input>
<small class="form-text text-muted">type here the  title of the new file (will go to //titleStmt/title)</small></div>
</div>
{if($app:collection = 'persons' or  $app:collection = 'places') then (
<div class="form-group">

<label class="col-md-2" for="WData">WikiData</label>
    <div class="form-check col-md-10">
      <input placeholder="enter the Q item id" class="form-control" list="WDhits" id="Wdata" name="WD" type="text"/>
      </div>
      </div>
      ) else ()
      }
{if($app:collection = 'authority-files') then () else( if($app:collection = 'persons') then (

(<div class="form-group">
<label for="keywords"  class="col-md-2 col-form-label">Faith</label>
<div class="col-md-10"><select  class="form-control"  id="keywords" name="keywords" multiple="multiple">
                {
                
                let $categories :=  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Confessions']//t:catDesc/text()
                 for $k in $categories
                order by $k
                return
                <option value="{$k}">{collection($config:data-rootA)//id($k)//t:titleStmt/t:title[1]}</option>
                }
</select>

<small class="form-text text-muted">give the file at least one keyword</small>
</div>
</div>,
<div class="form-group">
<label for="occupation"  class="col-md-2 col-form-label">Occupation</label>
<div class="col-md-10"><select  class="form-control"  id="occupation" name="occupation">
<option value="" selected="selected">choose</option>
                {
                
                let $categories :=  doc($config:app-root || '/schema/tei-betamesaheft.xml')//t:elementSpec[@ident='occupation']//t:attDef[@ident='type']//t:valItem
                 for $k in $categories
                order by $k/@ident
                return
                <option value="{$k/@ident}">{$k//t:desc}</option>
                }
</select>

<small class="form-text text-muted">give the file at least one keyword</small>
</div>
</div>,
<div class="form-group">
<label for="nationality"  class="col-md-2 col-form-label">Nationality</label>
<div class="col-md-10"><select  class="form-control"  id="nationality" name="nationality">
<option value="" selected="selected">choose</option>
                {
                
                let $categories :=  doc($config:app-root || '/schema/tei-betamesaheft.xml')//t:elementSpec[@ident='nationality']//t:attDef[@ident='type']//t:valItem
                 for $k in $categories
                 let $i := $k/@ident
                order by $i
                return
                <option value="{$i}">{string($i)}</option>
                }
</select>

<small class="form-text text-muted">give the file at least one keyword</small>
</div>
</div>
)
) else (
<div class="form-group">
<label for="keywords"  class="col-md-2 col-form-label">Keywords</label>
<div class="col-md-10"><select  class="form-control"  id="keywords" name="keywords" multiple="multiple">
                {
                
                let $categories := 
                switch($app:collection)
                case 'narratives' return  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Subjects']//t:catDesc/text()
                case 'works' return  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Subjects']//t:catDesc/text()
                case 'manuscripts' return  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Subjects']//t:catDesc/text()
                case 'places' return  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Place types']//t:catDesc/text()
                case 'institutions' return  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Place types']//t:catDesc/text()
               default return doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy//t:catDesc/text()
                for $k in $categories
                order by $k
                return
                <option value="{$k}">{collection($config:data-rootA)//id($k)//t:titleStmt/t:title[1]}</option>
                }
</select>

<small class="form-text text-muted">give the file at least one keyword</small>
</div>
</div>),
<div class="form-group">
<label for="note"  class="col-md-2 col-form-label">Note</label>
<div class="col-md-10"><input  class="form-control"  id="note" name="note"></input>
<small class="form-text text-muted">anything to add? just type what you want to put to the records.</small>
</div>
</div>,
<div class="form-group">
<label for="relations"  class="col-md-2 col-form-label">Relations</label>
<div class="col-md-10">
<select  class="form-control"  id="relations" name="relations" multiple="multiple">
<option value="saws:isCopierOf">saws:isCopierOf</option>
<option value="saws:hasOwned">saws:hasOwned</option>
<option value="bm:wifeOf">bm:wifeOf</option>
<option value="bm:husbandOf">bm:husbandOf</option>
<option value="lawd:hasAttestation">lawd:hasAttestation</option>
syriaca:has-relation-to-place
<option value="snap:AllianceWith">snap:AllianceWith</option>
<option value="bm:ordainedBy">bm:ordainedBy</option>
<option value="ecrm:P129i_is_subject_of">ecrm:P129i_is_subject_of</option>
<option value="rel:enemyOf">rel:enemyOf</option>
<option value="snap:SonOf">snap:SonOf</option>
<option value="snap:FatherOf">snap:FatherOf</option>

<option value="saws:isAttributedToAuthor">saws:isAttributedToAuthor</option>
<option value="saws:formsPartOf">saws:formsPartOf</option>
<option value="saws:isVersionInAnotherLanguageOf">saws:isVersionInAnotherLanguageOf</option>
<option value="ecrm:P129_is_about">ecrm:P129_is_about</option>
<option value="dcterms:creator">dcterms:creator</option>
<option value="saws:contains">saws:contains</option>
<option value="dcterms:hasPart">dcterms:hasPart</option>
<option value="ecrm:CLP46i_may_form_part_of">ecrm:CLP46i_may_form_part_of</option>
<option value="saws:isDifferentTo">saws:isDifferentTo</option>
<option value="saws:isShorterVersionOf">saws:isShorterVersionOf</option>

<option value="saws:isAncestorOf">saws:isAncestorOf</option>
<option value="saws:isRelatedTo">saws:isRelatedTo</option>
<option value="ecrm:P57_has_number_of_parts">ecrm:P57_has_number_of_parts</option>
<option value="saws:follows">saws:follows</option>
<option value="ecrm:P57_has_number_of_parts">ecrm:P57_has_number_of_parts</option>
                </select>
                <small class="form-text text-muted">Any relation needed for sure? select as many as you want. You will have to complete these in your file after download with passive attribute values</small>
                </div>
                </div>)}
                </fieldset>
                <fieldset class="form-group">
<legend>Resource specific fields</legend>
{if($app:collection = 'persons') then
(
<div class="form-group">
<label class="col-md-2 col-form-label">Gender</label>
    <div class="form-check col-md-10"><label class="form-check-label">
        <input type="checkbox" class="form-check-input" name="group" id="group" value="group"/>
        Group
      </label>
      </div>
      </div>,
  
    <div class="form-group">
  <label for="birth" class="col-md-2 col-form-label">Birth</label>
  <div class="col-md-10">
    <input class="form-control" type="text" id="birth" name="birth"/>
    
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>
</div>,
<div class="form-group">
  <label for="death" class="col-md-2 col-form-label">Death</label>
  <div class="col-md-10">
    <input class="form-control" type="text" id="death"  name="death"/>
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>
</div>,
<div class="form-group">
  <label for="death" class="col-md-2 col-form-label">Floruit</label>
  <div class="col-md-10">
    <input class="form-control" type="text" id="floruit"  name="floruit"/>
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>
</div>,
<div class="form-group">
<label for="attested" class="col-md-2 col-form-label">Attested in</label>
<div class="col-md-10">
<input placeholder="select..." class="form-control" id="GoTo" list="gotohits" autocomplete="on" name="attested" data-value="works"/>
<datalist xmlns="http://www.w3.org/1999/xhtml"  id="gotohits">
        
            </datalist>
<small class="form-text text-muted">Do you know where is this entity attested?</small></div>
</div>,
<div class="form-group">
<label class="col-md-2 col-form-label">Gender</label>
    <div class="form-check col-md-10" id="gender">
      <label class="form-check-label">
        <input type="radio" class="form-check-input" name="gender" id="male" value="1"/>
        Male
      </label>
    <label class="form-check-label">
        <input type="radio" class="form-check-input" name="gender" id="female" value="2"/>
        Female
      </label>
    </div>
    
  </div>
)
else if($app:collection = 'manuscripts') then (
<div class="form-group">
<label for="institution"  class="col-md-2 col-form-label">Institution</label>
<div class="col-md-10"><select  class="form-control"  id="institution" name="institution">
                {
                for $i in collection($config:data-rootIn)//t:TEI/@xml:id
                let $title := titles:printTitleID($i)
                order by $title
                return
                <option value="{$i}">{$title}</option>
                }
</select><small class="form-text text-muted">select institution where manuscript is stored. If this is a new institution, <a target="_blank" href="/newentry.html?collection=institutions">please first create the institution record</a></small></div>
</div>,
<div class="form-group">
<label for="idno"  class="col-md-2 col-form-label">Identifier</label>
<div class="col-md-10"><input  class="form-control" id="idno" name="idno"  required="required"></input>
<small class="form-text text-muted">type here the canonical identifier for this manuscript</small></div>
</div>,
<div class="form-group">
<label for="msParts"  class="col-md-2 col-form-label">Number of msParts needed</label>
<div class="col-md-10"><input  class="form-control" id="msParts" name="msParts"  type="number"></input>
<small class="form-text text-muted">You might specify here how many msParts you think you will need. Default is none.</small></div>
</div>
)
else if ($app:collection = 'places' or $app:collection = 'institutions') then (
<div class="form-group">
<label for="attested" class="col-md-2 col-form-label">Attested in</label>
<div class="col-md-10">
<input placeholder="select..." class="form-control" id="GoTo" list="gotohits" autocomplete="on" name="attested" data-value="works"/>
<datalist xmlns="http://www.w3.org/1999/xhtml"  id="gotohits">
        
            </datalist>
<small class="form-text text-muted">Do you know where is this entity attested?</small></div>
</div>
)
else ()}

</fieldset>
    
    <button id="confirmcreatenew" type="submit" class="btn btn-primary"  disabled="disabled">create new entry</button>
    </form>
};
