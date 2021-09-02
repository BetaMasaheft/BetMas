xquery version "3.1" encoding "UTF-8";
(:~
 : module with the main nav bar and the modals it calls
 : @author Pietro Liuzzo 
 :)
module namespace nav="https://www.betamasaheft.uni-hamburg.de/BetMas/nav";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
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


declare function nav:barNew(){
let $url := try{request:get-url()} catch*{''}
return
(<div class="w3-top">
  <div class="w3-bar w3-black w3-card">
    <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  w3-hide-medium w3-hide-large w3-right" href="javascript:void(0)" 
    onclick="myFunction()" title="Toggle Navigation Menu"><i class="fa fa-bars"></i></a>
  {if(ends-with($url, '.html') or ($url =  $config:appUrl) or ends-with($url ,  'BetMas/')) then locallogin:loginNew() else  ()}
                
<div class="w3-dropdown-hover w3-hide-small" id="about">
      <button class=" w3-button" title="about">
      {if(string-length($url) gt 1) then ('Hi ' || sm:id()//sm:username/text() || '!') else ('Home')}
      <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
      {if(sm:is-authenticated() and contains(sm:get-user-groups(sm:id()//sm:username/text()), 'Editors')) then
                        (
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/user/{sm:id()//sm:real/sm:username/string() }">Your personal page</a>
                            ,
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/clavismatching.html">Clavis Matching</a>
                            )
                        else ()}
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/">Home</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/team.html">Team</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="https://www.betamasaheft.uni-hamburg.de/team/partners.html">Partners</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/contacts.html">Contacts</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/Guidelines/">Guidelines and documentation</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/apidoc.html">Data API</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/lod.html">Linked Open Data</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/pid.html">Permalinks</a>
        
      </div>
    </div>
 <div class="w3-dropdown-hover w3-hide-small" id="works">
      <button class=" w3-button" title="Works">Clavis <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/works/list">Textual Units</a>
                              <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/narratives/list">Narrative Units</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red" href="/documentcorpora.html">Documents corpora</a>
                      </div>
    </div>  
    
    <div class="w3-dropdown-hover w3-hide-small" id="mss">
      <button class=" w3-button" title="manuscripts">Manuscripts <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/manuscripts/list">Manuscripts (search)</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/manuscripts/browse">Shelf marks (full list)</a>
                               <!--<a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/UniProd/browse">UniProd (full list)</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/UniCirc/browse">UniCirc (full list)</a>
                                --><a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/manuscripts/viewer">Manuscripts Images</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/catalogues/list">Catalogues</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/manuscripts/list?objectType=Inscription">Inscriptions</a>
                      </div>
    </div>
    <div class="w3-dropdown-hover w3-hide-small" id="places">
      <button class=" w3-button" title="Places">Places <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/places/list">Places</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/institutions/list">Repositories</a>
                                </div>
    </div>
   
    <a href="/persons/list" class="w3-bar-item w3-button  w3-hide-small"  id="persons">Persons</a>
    <div class="w3-dropdown-hover w3-hide-medium w3-hide-small" id="indexes">
      <button class=" w3-button" title="indexes">Indexes <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain" data-value="zoterolib"  href="https://www.zotero.org/groups/ethiostudies/items">Zotero Library</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/bibliography">List of cited publications</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/IndexPersons">Persons</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/IndexPlaces">Places</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/titles">Titles/Colophon/Supplications</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/calendar.html">Calendar</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/decorations">Decorations</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/bindings">Bindings</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/additions">Additions</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"  href="/authority-files/list">Keywords</a>
                                <div id="navexplanations" class="w3-row">
                            <span id="zoterolib" class="w3-hide w3-red w3-center">
                               This button will take you to the EthioStudies Group Library in Zotero. This group library is openly available, please use it. Further guidelines on the use of it and the CSL styles of the Hiob Ludolf Center for Eritrean and Ethiopian Studies can be accessed from the 'help' page.
                               </span>
                               </div>
                          </div>
    </div>
    <div class="w3-dropdown-hover w3-hide-medium w3-hide-small" id="resources">
      <button class=" w3-button " title="resources">Resources <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/compare">Compare manuscripts of a given work</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/workmap">Map of manuscripts with a given content</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/litcomp">Related Textual Units</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/LitFlow">Literature Flow Sankey view</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/xpath">XPath search</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/sparql">SPARQL Endpoint</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/collate">Collate passages with Collatex</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/gender">Gender and Manuscripts</a>
                     </div>
    </div>
    <div class="w3-dropdown-hover w3-hide-medium w3-hide-small" id="projects">
      <button class=" w3-button " title="projects">Projects <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar w3-card-4">
           <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/lectures.html">Lectures</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/chojnacki.html">The Stanislaw Chojnacki Photographic Database</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/tweed.html">The André Tweed Collection of Ethiopic Manuscripts</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/DSintro.html">The Dayr al-Suryān Collection</a>
                                <a class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"   href="/privateCollections.html">Private collections in Germany</a>
      </div>
      </div>
    <a href="/morpho" class="w3-bar-item w3-button  w3-hide-medium w3-hide-small" 
     data-toggle="tooltip" data-placement="bottom" title="Gǝʿǝz Morphological Parser (TraCES project)">Parser</a>
    <a href="/Dillmann" class="w3-bar-item w3-button  w3-hide-medium w3-hide-small" 
     data-toggle="tooltip" data-placement="bottom" title="Online Lexicon Linguae Aethiopicae (TraCES project)">Lexicon</a>
     <a href="/help.html" class="w3-bar-item w3-button  w3-hide-medium w3-hide-small" 
     data-toggle="tooltip" data-placement="bottom" title="How to navigate this website">Help</a>
    
               {nav:newentryNew()}
  
    {if(contains($url, 'as.html') ) then 
    <a href="/facet.html" class="w3-padding w3-hover-red w3-hide-small w3-right"><i class="fab fa-search"></i></a>
    else(<a href="/facet.html" class="w3-padding w3-hover-red w3-hide-small w3-right"><i class="fa fa-search"></i></a>, <a href="/as.html" class="w3-padding w3-hover-red w3-hide-small w3-right"><i class="fab fa-searchengin"></i></a>)}
  </div>
</div>,
<div id="navDemo" class="w3-bar-block w3-black w3-hide w3-hide-large w3-hide-medium w3-top" style="margin-top:46px">
            <a href="/" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Home</a>
            <a href="/works/list" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Clavis</a>
            <a href="/manuscripts/list" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Manuscripts</a>
            <a href="/facet.html" class="w3-bar-item w3-button w3-padding-large" onclick="myFunction()">Search</a>
        </div>
)
};


declare function nav:newentryNew(){
        if(contains(sm:get-user-groups(sm:id()//sm:real/sm:username/string() ), 'Editors')) then

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
                    <img alt="Creative Commons License" style="border-width:0" src="resources/images/88x31.png"/>
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
            <div class="w3-row w3-center">
            <p>The domain betamasaheft.eu is hosted by Universität Hamburg.</p>
            <p>This website is maintained by the project team.</p>
            <p><a href="/impressum.html">Impressum.</a></p>
            </div>
  <p class="w3-medium">Powered by <a href="https://www.w3schools.com/w3css/default.asp" target="_blank">w3.css</a></p>
</footer>

};
