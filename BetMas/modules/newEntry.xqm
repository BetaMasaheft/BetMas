xquery version "3.0" encoding "UTF-8";
(:~
 : new entry form 
 : @author Pietro Liuzzo 
 :)
module namespace new="https://www.betamasaheft.uni-hamburg.de/BetMas/new";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";



(:this is a small form that points to the xquery generating the new file and prompting the editor to save it in the correct location:)
declare function new:newentry($node as node()*, $model as map(*)) {
     let $option := switch($app:collection) 
     case 'manuscripts' return ''
     default return 'last part of the'
     return
         
    
<form id="createnew" action="edit/save-new-entity.xql">
<p>Great! So you are creating a new record in <span class="w3-tag w3-red w3-large">{$app:collection}</span>!</p>
<fieldset class="w3-container">
<legend>General data</legend>
<div class="w3-container w3-margin-bottom">
<input class="w3-input" type="hidden" name="collection" value="{$app:collection}" />
</div>
<div class="w3-container w3-margin-bottom">
<label>ID</label><br/>
<input  class="w3-input" id="suffix" name="suffix"  required="required"></input>
<small class="form-text text-muted">type here the {$option} new id <a target="_blank" href="https://betamasaheft.eu/Guidelines/?id=entities-id-structure">(assigning IDs guidelines page)</a></small>
</div>

<div class="w3-container w3-margin-bottom">
<label >Title</label><br/>
<input  class="w3-input"   id="title" name="title" required="required"></input><br/>
<small class="form-text text-muted">type here the  title of the new file (will go to //titleStmt/title)</small>
</div>
{if($app:collection = 'persons' or  $app:collection = 'places') then (
<div class="w3-container w3-margin-bottom">
<label>WikiData</label><br/>
      <input placeholder="enter the Q item id" class="w3-input"  list="WDhits" id="Wdata" name="WD" type="text"/>
      </div>
      ) else ()
      }
{if($app:collection = 'authority-files') then () 
else( 
if($app:collection = 'persons') then (

(<div class="w3-container w3-margin-bottom">
<label >Faith</label><br/>
<select  class="w3-select"  id="keywords" name="keywords" multiple="multiple">
                {
                
                let $categories :=  doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy/t:category[t:desc='Confessions']//t:catDesc/text()
                 for $k in $categories
                order by $k
                return
                <option value="{$k}">{$config:collection-rootA/id($k)//t:titleStmt/t:title[1]}</option>
                }
</select><br/>

<small class="form-text text-muted">give the file at least one keyword</small>
</div>,
<div class="w3-container w3-margin-bottom">
<label >Occupation</label><br/>
<select  class="w3-select"  id="occupation" name="occupation">
<option value="" selected="selected">choose</option>
                {
                
                let $categories :=  doc($config:app-root || '/schema/tei-betamesaheft.xml')//t:elementSpec[@ident='occupation']//t:attDef[@ident='type']//t:valItem
                 for $k in $categories
                order by $k/@ident
                return
                <option value="{$k/@ident}">{$k//t:desc}</option>
                }
</select>
<br/>
<small class="form-text text-muted">give the file at least one keyword</small>
</div>,
<div class="w3-container w3-margin-bottom">
<label>Nationality</label><br/>
<select  class="w3-select"  id="nationality" name="nationality">
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
<br/>
<small class="form-text text-muted">give the file at least one keyword</small>
</div>
)
) else (
<div class="w3-container w3-margin-bottom">
<label>Keywords</label><br/>
<div class="w3-container" id="formKeywords">
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
                <span class="w3-tag w3-gray w3-margin">
                
                <input type="checkbox" class="w3-check" value="{$k}" name="keywords"/>
                <label>{titles:printTitleMainID($k, $config:data-rootA)}</label>
                </span>
                }
<br/>
<small class="form-text text-muted">give the file at least one keyword</small>
</div>
</div>),
<div class="w3-container w3-margin-bottom">
<label >Note</label><br/>
<textarea  class="w3-input"  id="note" name="note"></textarea><br/>
<small class="form-text text-muted">anything to add? just type what you want to put to the records.</small>
</div>,
<div class="w3-container w3-margin-bottom">
<label>Relations</label><br/>
<select  class="w3-select"  id="relations" name="relations" multiple="multiple" style="height:400px">
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
                <br/>
                <small class="form-text text-muted">Any relation needed for sure? select as many as you want. You will have to complete these in your file after download with passive attribute values</small>
                </div>)}
                </fieldset>
                <fieldset class="w3-container">
<legend>Resource specific fields</legend>
{if($app:collection = 'persons') then
(
<div class="w3-container w3-margin-bottom">
    <label>
        <input type="checkbox" class="w3-check" name="group" id="group" value="group"/>
        Group
      </label>
      </div>,
  
    <div class="w3-container w3-margin-bottom">
  <label>Birth</label><br/>
    <input class="w3-input" type="text" id="birth" name="birth"/>
    <br/>
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>,
<div class="w3-container w3-margin-bottom">
  <label>Death</label><br/>
    <input class="w3-input" type="text" id="death"  name="death"/><br/>
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>,
<div class="w3-container w3-margin-bottom">
  <label>Period of activity</label><br/>
    <input class="w3-input" type="text" id="floruit"  name="floruit"/><br/>
<small class="form-text text-muted">Please, enter a well formatted date or a range and remember to update attributes </small>
  </div>,
<div class="w3-container w3-margin-bottom">
<label>Attested in</label><br/>
<label >
        <input type="radio" class="w3-check" name="AttestedInType" id="AttestedInTypeID" value="1" checked="checked"/>
        ID
      </label>
    <label class="form-check-label">
        <input type="radio" class="w3-check" name="AttestedInType" id="AttestedInTypeTITLE" value="2"/>
        Title
      </label>
<input placeholder="select..." class="form-control" id="GoTo" list="gotohits" autocomplete="on" data-value="works"/>
<select class="w3-select"  id="gotohits"  name="attested" >
        <option value="">Nothing yet to be selected</option>
            </select><br/>
<small class="form-text text-muted">Do you know where is this entity attested? Check the type of input you are giving then start typing an ID or a title to get a list.</small>
</div>,
<div class="w3-container w3-margin-bottom">
<label>Gender</label>
    <div  id="gender">
      <label >
        <input type="radio" class="w3-check" name="gender" id="male" value="1"/>
        Male
      </label>
    <label class="form-check-label">
        <input type="radio" class="w3-check" name="gender" id="female" value="2"/>
        Female
      </label>
    </div>
    
  </div>
)
else if($app:collection = 'manuscripts') then (
<div class="w3-container w3-margin-bottom">
<label>Institution</label>
<br/><select  class="w3-select"  id="institution" name="institution">
                {
                for $i in doc('/db/apps/BetMas/lists/institutions.xml')//t:item
                let $title := $i/text()
                order by $title
                return
                <option value="{string($i/@xml:id)}">{$title}</option>
                }
</select><br/>
<small class="form-text text-muted">select institution where manuscript is stored. If this is a new institution, <a target="_blank" href="/newentry.html?collection=institutions">please first create the institution record</a></small>

</div>,
<div class="w3-container w3-margin-bottom">
<label>Identifier</label><br/>
<input  class="w3-input" id="idno" name="idno"  required="required"></input><br/>
<small class="form-text text-muted">type here the canonical identifier for this manuscript</small>
</div>,
<div class="w3-container w3-margin-bottom">
<label>Number of msParts needed</label><br/>
<input  class="w3-input" id="msParts" name="msParts"  type="number"></input><br/>
<small class="form-text text-muted">You might specify here how many msParts you think you will need. Default is none.</small>
</div>
)
else if ($app:collection = 'places' or $app:collection = 'institutions') then (
<div class="w3-container w3-margin-bottom">
<label>Attested in</label><br/>
<label >
        <input type="radio" class="w3-check" name="AttestedInType" id="AttestedInTypeID" value="1" checked="checked"/>
        ID
      </label>
    <label >
        <input type="radio" class="w3-check" name="AttestedInType" id="AttestedInTypeTITLE" value="2"/>
        Title
      </label>
<input placeholder="select..." class="form-control" id="GoTo" list="gotohits" autocomplete="on" data-value="works"/>
<select class="form-control"  id="gotohits"  name="attested" multiple="multiple">
        <option value="">Nothing yet to be selected</option>
            </select><br/>
<small class="form-text text-muted">Do you know where is this entity attested? Check the type of input you are giving then start typing an ID or a title to get a list.</small>

</div>
)
else ()}

</fieldset>
    
    <button id="confirmcreatenew" type="submit" class="w3-button w3-red w3-xlarge"  disabled="disabled">create new entry</button>
    </form>
};
