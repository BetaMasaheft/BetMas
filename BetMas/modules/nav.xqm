xquery version "3.1" encoding "UTF-8";
(:~
 : module with the main nav bar and the modals it calls
 : @author Pietro Liuzzo 
 :)
module namespace nav="https://www.betamasaheft.uni-hamburg.de/BetMas/nav";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace apprest="https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace locallogin="https://www.betamasaheft.eu/login" at "xmldb:exist:///db/apps/BetMas/modules/login.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare function nav:modalsNew(){
<div id="versionInfo" class="w3-modal">
  <div class="w3-modal-content">
    <div class="w3-container">
      <span onclick="document.getElementById('versionInfo').style.display='none'" 
      class="w3-button w3-display-topright"><i class="fa fa-times"></i></span>
     <p> You are looking at work in progress version of this website. 
                        For questions <a href="mailto:pietro.liuzzo@uni-hamburg.de?Subject=Issue%20Report%20BetaMasaheft">contact the dev team</a>.</p>    
                        
                        <p> Hover on words to see search options.</p> 
                        <p>Double-click to see morphological parsing.</p>
                        <p> Click on left pointing hands and arrows to load related items and click once more to view the result in a popup.</p>

                        </div>
  </div>
</div>
        };

declare function nav:searchhelpNew(){
<div id="searchHelp" class="w3-modal">
  <div class="w3-modal-content">
    <header class="w3-container w3-red"> 
      <span onclick="document.getElementById('searchHelp').style.display='none'" 
      class="w3-button w3-display-topright"><i class="fa fa-times"></i></span>
      <h2>Search Help</h2>
    </header>
    
    <div class="w3-container">
      
      <div>
                    <h3>Search</h3>
                        <p>This app is built with exist-db, and uses Lucene as the standard search engine. This comes with several options available. A full list is <a href="https://lucene.apache.org/core/2_9_4/queryparsersyntax.html#Fuzzy Searches" target="_blank">here</a>
                        </p>
                        <p>Below very few examples.</p>
                        <table class="table table-hover table-responsive">
                            <thead>
                                <tr>
                                    <th/>
                                    <th>sample</th>
                                    <th>result</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>*</td>
                                    <td>*custodir*</td>
                                    <td>add wildcards to unlimit your string search</td>
                                </tr>
                                <tr>
                                    <td>?</td>
                                    <td>custodir?</td>
                                    <td>Will find any match for the position with the question mark.</td>
                                </tr>
                                <tr>
                                    <td>~</td>
                                    <td>ምሕረትከ~</td>
                                    <td>Will make a fuzzy search. you can decide also how much fuzzy, by saying for example ምሕረትከ~0.9 which will match only 90% similar terms.</td>
                                </tr>
                                <tr>
                                    <td>""</td>
                                    <td>"ምሕረትከ፡ ይትኖለወኒ፡"</td>
                                    <td>Will find the exact string contained between quotes.</td>
                                </tr>
                                <tr>
                                    <td>()</td>
                                    <td>(verbo OR notionem) AND ይትኖለወኒ</td>
                                    <td>Will find one of the two between brackets and the other string.</td>
                                </tr>
                            </tbody>
                        </table>
                        </div>
                        <div>
                        <h3>Input</h3>
                        <p>If you want to transcribe some fidal into latin or update your transcription, you can <a target="_blank" href="https://betamasaheft.github.io/transliteration/">have a go with our transcription tools</a>.</p>
                        <p>If you are using the keyboard provided, please note that there are four layers, the normal one and those activated by Shift, Alt, Alt+Shift.</p>
                        <p>Normal and Shift contain mainly Fidal. Alt and Alt-Shift diacritics.</p>
                        <p>To enter letters in Fidal and the diacritics with this keyboard, which is independent of your local input selection, you can use two methods.</p>
                        <p>Orthographic variants of the Ethiopic language are searched as a standard if not otherwise
                specified. The following are the options considered by the search engine. </p>
            <ul>
                <li>'s','s', 'ḍ'</li>
               <li> 'e','ǝ','ə','ē'</li>
                <li>'w','ʷ'</li>
                <li>'ʾ', 'ʿ'</li>
                <li>'`', 'ʾ', 'ʿ' (note that you can use the tick if you are not sure about the two, but none will be inferred for you)</li>
                <li>'ሀ', 'ሐ', 'ኀ', 'ሃ', 'ሓ', 'ኃ'</li>
                <li>'ሀ', 'ሐ', 'ኀ'</li>
                <li>'ሁ', 'ሑ', 'ኁ'</li>
               <li> 'ሂ', 'ሒ', 'ኂ'</li>
                <li>'ሄ', 'ሔ', 'ኄ'</li>
               <li> 'ህ', 'ሕ', 'ኅ'</li>
               <li> 'ሆ', 'ሖ', 'ኆ'</li>
               <li> 'ሠ','ሰ'</li>
               <li> 'ሡ','ሱ'</li>
                <li>'ሢ','ሲ'</li>
                <li>'ሣ','ሳ'</li>
               <li> 'ሥ','ስ'</li>
                <li>'ሦ','ሶ'</li>
                <li>'ሤ','ሴ'</li>
               <li> 'ጸ', 'ፀ'</li>
                <li>'ጹ', 'ፁ'</li>
                <li>'ጺ', 'ፂ'</li>
               <li> 'ጻ', 'ፃ'</li>
                <li>'ጼ', 'ፄ'</li>
               <li> 'ጽ', 'ፅ'</li>
                <li>'ጾ', 'ፆ'</li>
               <li> 'አ', 'ዐ', 'ኣ', 'ዓ'</li>
               <li> 'ኡ', 'ዑ'</li>
               <li> 'ኢ', 'ዒ'</li>
               <li> 'ኤ', 'ዔ'</li>
                <li>'እ', 'ዕ'</li>
               <li> 'ኦ', 'ዖ'</li>
            </ul>
            <p>Some examples</p>
           <ul><li>If you search Taammera, you will not find Taʾammǝra or Taʿammera but only Taammera. Try Ta`ammera
instead or use the keyboard provided to enter aleph and ayn. </li>
<li>If you are searching for Yāʿǝqob, you will not have a lot of luck searching Yaqob, unless some kind cataloguer has actually added it into the data as simplified spelling form. Try instead entering Yaqob~0.5 which is a fuzzy search, this will return also Yāʿǝqob. Also Ya`eqob is fine for example. </li></ul>
                        <h4>Keys Combinations</h4>
                        <p>With this method you use keys combinations to trigger specific characters.
                        <a target="_blank" href="/combos.html">Click here for a list of the available combos.</a>
                        This can be expanded<a target="_blank" href="https://github.com/BetaMasaheft/Documentation/issues/new?labels=keyboard&amp;assignee=PietroLiuzzo&amp;body=Please%20add%20a%20combo%20in%20the%20input%20keyboard">, do not hesitate to ask (click here to post a new issue).</a>
                        </p>
                         <h4>Hold and choose</h4>
                         <p>If you hold a key optional values will appear in a list. You can click on the desiderd value or use arrows and enter to select it. The options are the same as those activated by combinations.</p>
                         <p>With this method you do not have to remember or lookup combos, but it does take many more clicks...</p>
                        </div>
                    </div>
      
      <footer class="w3-container w3-teal w3-red">
      <span onclick="document.getElementById('searchHelp').style.display='none'" 
      class="w3-button w3-display-topright"><i class="fa fa-times"></i></span>
    </footer>
      </div>
      </div>
      
        

};


declare function nav:barNew(){
let $url := try{request:get-url()} catch*{''}
return
(<div class="w3-top">
  <div class="w3-bar w3-black w3-card">
    <a class="w3-bar-item w3-button  w3-hide-medium w3-hide-large w3-right" href="javascript:void(0)" 
    onclick="myFunction()" title="Toggle Navigation Menu"><i class="fa fa-bars"></i></a>
  {if(ends-with($url, '.html') or ($url =  $config:appUrl) or ends-with($url ,  'BetMas/')) then locallogin:loginNew() else  ()}
                
<div class="w3-dropdown-hover w3-hide-small" id="about">
      <button class=" w3-button" title="about">
      {if(string-length($url) gt 1) then ('Hi ' || sm:id()//sm:username/text() || '!') else ('Home')}
      <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
      {if(sm:is-authenticated() and contains(sm:get-user-groups(sm:id()//sm:username/text()), 'Editors')) then
                        (
                                <a class="w3-bar-item w3-button" href="/user/{xmldb:get-current-user()}">Your personal page</a>
                            ,
                                <a class="w3-bar-item w3-button" href="/clavismatching.html">Clavis Matching</a>
                            )
                        else ()}
                                <a class="w3-bar-item w3-button" href="/">Home</a>
                                <a class="w3-bar-item w3-button" href="/team.html">Team</a>
                                <a class="w3-bar-item w3-button" href="/partners.html">Partners</a>
                                <a class="w3-bar-item w3-button" href="/contacts.html">Contacts</a>
                                <a class="w3-bar-item w3-button" href="/Guidelines/">Guidelines and documentation</a>
                                <a class="w3-bar-item w3-button" href="/apidoc.html">Data API</a>
                                <a class="w3-bar-item w3-button" href="/lod.html">Linked Open Data</a>
        
      </div>
    </div>
 <div class="w3-dropdown-hover w3-hide-small" id="works">
      <button class=" w3-button" title="Works">Clavis <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
                                <a class="w3-bar-item w3-button" href="/works/list">Textual Units</a>
                              <a class="w3-bar-item w3-button" href="/narratives/list">Narrative Units</a>
                                <a class="w3-bar-item w3-button" href="/documentcorpora.html">Documents corpora</a>
                      </div>
    </div>  
    
    <div class="w3-dropdown-hover w3-hide-small" id="mss">
      <button class=" w3-button" title="manuscripts">Manuscripts <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
                                <a class="w3-bar-item w3-button"  href="/manuscripts/list">Manuscripts (search)</a>
                                <a class="w3-bar-item w3-button"  href="/manuscripts/browse">Shelf marks (full list)</a>
                                <a class="w3-bar-item w3-button"  href="/UniProd/browse">UniProd (full list)</a>
                                <a class="w3-bar-item w3-button"  href="/UniCirc/browse">UniCirc (full list)</a>
                                <a class="w3-bar-item w3-button"  href="/manuscripts/viewer">Manuscripts Images</a>
                                <a class="w3-bar-item w3-button"  href="/catalogues/list">Catalogues</a>
                      </div>
    </div>
    <div class="w3-dropdown-hover w3-hide-small" id="places">
      <button class=" w3-button" title="Places">Places <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
                                <a class="w3-bar-item w3-button"   href="/places/list">Places</a>
                                <a class="w3-bar-item w3-button"   href="/institutions/list">Repositories</a>
                                </div>
    </div>
   
    <a href="/persons/list" class="w3-bar-item w3-button  w3-hide-small"  id="persons">Persons</a>
    <div class="w3-dropdown-hover w3-hide-medium w3-hide-small" id="indexes">
      <button class=" w3-button" title="indexes">Indexes <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
                                <a class="w3-bar-item w3-button"  href="https://www.zotero.org/groups/ethiostudies/items">Zotero Library</a>
                                <a class="w3-bar-item w3-button"  href="/bibliography">List of cited publications</a>
                                <a class="w3-bar-item w3-button"  href="/IndexPersons">Persons</a>
                                <a class="w3-bar-item w3-button"  href="/IndexPlaces">Places</a>
                                <a class="w3-bar-item w3-button"  href="/decorations">Decorations</a>
                                <a class="w3-bar-item w3-button"  href="/bindings">Bindings</a>
                                <a class="w3-bar-item w3-button"  href="/additions">Additions</a>
                                <a class="w3-bar-item w3-button"  href="/authority-files/list">Keywords</a>
                          </div>
    </div>
    <div class="w3-dropdown-hover w3-hide-medium w3-hide-small" id="resources">
      <button class=" w3-button " title="resources">Resources <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
                                <a class="w3-bar-item w3-button"   href="/compare">Compare manuscripts of a given work</a>
                                <a class="w3-bar-item w3-button"   href="/workmap">Map of manuscripts with a given content</a>
                                <a class="w3-bar-item w3-button"   href="/litcomp">Related Textual Units</a>
                                <a class="w3-bar-item w3-button"   href="/LitFlow">Literature Flow Sankey view</a>
                                <a class="w3-bar-item w3-button"   href="/xpath">XPath search</a>
                                <a class="w3-bar-item w3-button"   href="/sparql">SPARQL Endpoint</a>
                                <a class="w3-bar-item w3-button"   href="/collate">Collate passages with Collatex</a>
                                <a class="w3-bar-item w3-button"   href="/academics.html">Scholars in Ethiopian Studies</a>
                                <a class="w3-bar-item w3-button"   href="/chojnacki/viewer">Chojnacki Collection</a>
                     </div>
    </div>
    <a href="/morpho" class="w3-bar-item w3-button  w3-hide-medium w3-hide-small" 
     data-toggle="tooltip" data-placement="bottom" title="Gǝʿǝz Morphological Parser (TraCES project)">Parser</a>
    <a href="/Dillmann" class="w3-bar-item w3-button  w3-hide-medium w3-hide-small" 
     data-toggle="tooltip" data-placement="bottom" title="Online Lexicon Linguae Aethiopicae (TraCES project)">Lexicon</a>
    
               {nav:newentryNew()}
   <a href="#" class=" w3-hover-red w3-padding w3-hide-small w3-hide-medium w3-right"
                                    onclick="document.getElementById('versionInfo').style.display='block'">
                                        <i class="fa fa-info-circle"/>
                                    </a>
    {if(contains($url, 'as.html') ) then () else<a href="/as.html" class="w3-padding w3-hover-red w3-hide-small w3-right"><i class="fa fa-search"></i></a>}
  </div>
</div>,
<div id="navDemo" class="w3-bar-block w3-black w3-hide w3-hide-large w3-hide-medium w3-top" style="margin-top:46px">
            <a href="/" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Home</a>
            <a href="/works/list" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Clavis</a>
            <a href="/manuscripts/list" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Manuscripts</a>
            <a href="/as.html" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Search</a>
        </div>
)
};


declare function nav:newentryNew(){
        if(contains(sm:get-user-groups(xmldb:get-current-user()), 'Editors')) then

         <form  action="/newentry.html" class="w3-bar-item w3-hide-medium w3-hide-small" style="margin:0;padding:0" role="tag">
           <select  name="collection" required="required" class="w3-bar-item w3-select  w3-twothird">
                 <option value="manuscripts">manuscript</option>
                 <option value="persons">person</option>
                 <option value="works">work</option>
                 <option value="narratives">narrative</option>
                 <option value="places">place</option>
                 <option value="authority-files">authority file</option>
                 <option value="institutions">institution</option>
                 </select>
              <button type="submit" class="w3-bar-item w3-button  w3-red  w3-third">new</button>
              </form>
                        else ()
                        };
       
                        
declare function nav:footerNew(){ 

<footer class="w3-container w3-padding-64 w3-center" id="footer">
<div class="w3-container">
      <p class="w3-center">Copyright © <span property="http://purl.org/dc/elements/1.1/publisher">Akademie der Wissenschaften in Hamburg,
                Hiob-Ludolf-Zentrum für Äthiopistik</span>.  Sharing and remixing permitted under terms of the <br/>
                <a rel="license"  property="http://creativecommons.org/ns#license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">
                    <img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png"/>
                </a></p>
                <br/>
 <p  class="w3-center"><a rel="license"  property="http://creativecommons.org/ns#license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
                </p ><br/>
<p  class="w3-center">DOI: {$config:DOI}</p>
                <hr/>
                <p  class="w3-center">Many thanks for their wonderful work to all the developers of free software for the code we use throughout the website.</p>
                    </div>
                    <div class="w3-row w3-center">
             <a class="poweredby" 
             property="http://purl.org/dc/elements/1.1/publisher" 
             href="http://www.awhamburg.de/" target="_blank">
                <img src="resources/images/logo-adw.png" 
                alt="Akademie der Wissenschaften in Hamburg logo"/>
            </a>
            <a class="poweredby" 
            property="http://purl.org/dc/elements/1.1/publisher" 
            href="https://www.betamasaheft.uni-hamburg.de/" 
            target="_blank">
                <img src="resources/images/logo.png" 
                alt="Beta maṣāḥǝft Project logo"/>
            </a>
            <a class="poweredby" 
            href="http://exist-db.org">
                <img 
                src="$shared/resources/images/powered-by.svg" 
                alt="Powered by eXist-db"/>
            </a>
            <a class="poweredby" href="http://www.tei-c.org/">
                <img src="resources/images/We-use-TEI.png" alt="We use TEI"/>
            </a>
            <a class="poweredby" href="http://commons.pelagios.org/">
                <img src="resources/images/Pelagios-logo.png" alt="Proud members of the Linked Pasts Network"/>
            </a>
            <a  href="https://iipimage.sourceforge.io/" >
                <img src="resources/images/iip_logo.png" width="90px" alt="We use the IIP Image Server"/>
            </a>
            <a  href="https://iiif.io/" >
                <img src="resources/images/iiif.png" width="90px" alt="Providing and resuing images with IIIF presentation API 2.0"/>
            </a>
            <a  href="https://www.zotero.org/groups/358366/ethiostudies/items" >
                <img src="resources/images/zotero_logo.png" width="90px" alt="All bibliography is managed with Zotero."/>
            </a>
            <a  href="https://github.com/BetaMasaheft" >
                <img src="resources/images/GitHub-Mark-120px-plus.png" width="90px" alt="Our data is all in GitHub!"/>
            </a>
            
          </div>
  <p class="w3-medium">Powered by <a href="https://www.w3schools.com/w3css/default.asp" target="_blank">w3.css</a></p>
</footer>

};
