xquery version "3.1" encoding "UTF-8";
(:~
 : module with the main nav bar and the modals it calls
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace nav="https://www.betamasaheft.uni-hamburg.de/BetMas/nav";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace apprest="https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace locallogin="https://www.betamasaheft.eu/login" at "xmldb:exist:///db/apps/BetMas/modules/login.xqm";


declare function nav:modals(){
   <div id="versionInfo" class="modal fade" role="dialog">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">close</button>
                        <h4 class="modal-title">This is a testing and dev website!</h4>
                    </div>
                    <div class="modal-body">
                        <p>        You are looking at a pre-alpha version of this website. If you are not an editor you should not even be seeing it at all. For questions <a href="mailto:pietro.liuzzo@uni-hamburg.de?Subject=Issue%20Report%20BetaMasaheft">contact the dev team</a>.</p>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
        };

declare function nav:searchhelp(){
        <div class="modal fade" id="searchHelp" tabindex="-1" role="dialog" aria-hidden="true">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">Search and Input Help</h5>
                    </div>
                    <div class="modal-body">
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
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>

};

declare function nav:bar(){
let $url := try{request:get-url()} catch*{''}
return
<nav class="navbar navbar-default" role="navigation">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-collapse-1">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"/>
                    <span class="icon-bar"/>
                    <span class="icon-bar"/>
                </button>
            </div>
            <div class="navbar-collapse collapse" id="navbar-collapse-1">
                <ul class="nav navbar-nav">
                {if(ends-with($url, 'BetMas/')) then locallogin:login() else ()
(:login is possible only from homepage and user name is displayed only on templating pages, not on the rest modules:)
}

                {nav:newentry()}
                    <li class="dropdown" id="about" >
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                      <span>   {if(string-length($url) gt 1) then ('Hi ' || xmldb:get-current-user() || '!') else ('Home')}</span>
                        </a>
                        <ul class="dropdown-menu  list-group">
                        {if(sm:is-authenticated() and contains(sm:get-user-groups(xmldb:get-current-user()), 'Editors')) then
                        (<li class="list-group-item">
                                <a href="/user/{xmldb:get-current-user()}">Your personal page</a>
                            </li>,
                            <li class="list-group-item">
                                <a href="/clavismatching.html">Clavis Matching</a>
                            </li>)
                        else ()}
                            <li class="list-group-item">
                                <a href="/">Home</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/team.html">Team</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/partners.html">Partners</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/contacts.html">Contacts</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/Guidelines/">Guidelines and documentation</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/apidoc.html">Data API</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/lod.html">Linked Open Data</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown" id="works">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Clavis</a>
                        <ul class="dropdown-menu list-group">
                            <li class="list-group-item">
                                <a href="/works/list">Textual Units</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/narratives/list">Narrative Units</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/documentcorpora.html">Documents corpora</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown" id="mss">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Manuscripts</a>
                        <ul class="dropdown-menu  list-group">
                            <li class="list-group-item">
                                <a href="/manuscripts/list">Manuscripts (search)</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/manuscripts/browse">Shelf marks (full list)</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/UniProd/browse">UniProd (full list)</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/UniCirc/browse">UniCirc (full list)</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/manuscripts/viewer">Manuscripts Images</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/catalogues/list">Catalogues</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown" id="places">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Places</a>
                        <ul class="dropdown-menu  list-group">
                            <li class="list-group-item">
                                <a href="/places/list">Places</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/institutions/list">Repositories</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown" id="persons">
                        <a href="/persons/list">Persons</a>
                    </li>
<li id="indexes" class="dropdown">
                        <a  href="#" class="dropdown-toggle" data-toggle="dropdown">Indexes</a>
                        <ul class="dropdown-menu  list-group">
                        <li id="bibl" class="list-group-item dropdown-submenu">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown">Bibliography</a>
                        <ul class="dropdown-menu  list-group">
                            <li class="list-group-item">
                                <a href="https://www.zotero.org/groups/ethiostudies/items">Zotero Library</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/bibliography">List of cited publications</a>
                            </li>
                        </ul>
                    </li>
                            <li class="list-group-item">
                                <a href="/IndexPersons">Persons</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/IndexPlaces">Places</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/decorations">Decorations</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/bindings">Bindings</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/additions">Additions</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/authority-files/list">Keywords</a>
                            </li>
                        </ul>
                    </li>
                    <li class="dropdown" id="resources">
                        <a  href="#" class="dropdown-toggle" data-toggle="dropdown">Resources</a>
                        <ul class="dropdown-menu  list-group">
                         
                    <li class="list-group-item">
                                <a href="/compare">Compare manuscripts of a given work</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/LitFlow">Literature Flow Sankey view</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/xpath">XPath search</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/sparql">SPARQL Endpoint</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/collate">Collate passages with Collatex</a>
                            </li>
                            <li class="list-group-item">
                                <a href="/academics.html">Scholars in Ethiopian Studies</a>
                            </li>
                        </ul>
                    </li>

                </ul>

                {
                let $url := try {request:get-url()} catch * {''}
                return
                if(contains($url, 'as.html') ) then () else
                <form action="/search.html" class="navbar-form navbar-left" role="search">
                    <div class="form-group">
                    <div class="input-group input-group-sm mb-3">
                        <input type="text" class="form-control diacritics" 
                        placeholder="search" name="query" id="q"></input>
                         <script type="application/javascript" src="resources/js/preventformsubmission.js"></script>
                        <div id="furtherSearchOptions" class="input-group-btn">
                            <a class="kb btn btn-success">
                                <i class="fa fa-keyboard-o" aria-hidden="true"></i>
                                </a>
                            <button id="f-btn-search" type="submit" class="btn btn-info">
                                <i class="fa fa-search" aria-hidden="true"></i>
                            </button>
                            <a href="/as.html" title="advanced search" class="btn btn-info">
                                <i class="fa fa-plus" aria-hidden="true"></i>
                            </a>
                            <a href="/Dillmann/" title="search lexicon" class="btn btn-default">
                                <i class="fa fa-book" aria-hidden="true"/>
                            </a>
                            <a href="#" class="btn btn-default" data-toggle="modal" data-target="#searchHelp">
                                <i class="fa fa-info-circle" aria-hidden="true"></i>
                            </a>
                            <a class="btn btn-warning"  target="_blank" href="https://github.com/BetaMasaheft/Documentation/issues/new?labels=app&amp;assignee=PietroLiuzzo&amp;body=There%20is%20an%20issue%20with%20a%20list%20view">
                            <i class="fa fa-exclamation-circle"></i>
                            </a>
                            <a  class="btn btn-info"  target="_blank" href="mailto:pietro.liuzzo@uni-hamburg.de">
                            <i class="fa fa-envelope-o" aria-hidden="true"></i>
                            </a>
               
                        </div>
                    </div>
                    </div>
                </form>

                }
            </div>
      </nav>};

declare function nav:newentry(){
        if(contains(sm:get-user-groups(xmldb:get-current-user()), 'Editors')) then

       <form  action="/newentry.html" class="navbar-form navbar-right" role="tag">
            <div class="form-group">
            <select class="form-control" name="collection" required="required">
                 <option value="manuscripts">manuscript</option>
                 <option value="persons">person</option>
                 <option value="works">work</option>
                 <option value="narratives">narrative</option>
                 <option value="places">place</option>
                 <option value="authority-files">authority file</option>
                 <option value="institutions">institution</option>
                 </select>
                 </div>
              <button type="submit" class="btn btn-success">new</button>
                	  </form>
                        else ()};

declare function nav:footer (){ <footer class="row-fluid">

      <div class="col-md-12">
      Copyright © <span property="http://purl.org/dc/elements/1.1/publisher">Akademie der Wissenschaften in Hamburg,
                Hiob-Ludolf-Zentrum für Äthiopistik</span>.  Sharing and remixing permitted under terms of the <br/>
                <a rel="license"  property="http://creativecommons.org/ns#license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">
                    <img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png"/>
                </a>
                <br/>
                <a rel="license"  property="http://creativecommons.org/ns#license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
                <br/>
                DOI: {$config:DOI}
                <hr/>
                <p>Many thanks for their wonderful work to all the developers of free software for the code we use throughout the website.</p>
                    </div>
              <div class="col-md-12">
<a class="poweredby" property="http://purl.org/dc/elements/1.1/publisher" href="http://www.awhamburg.de/" target="_blank">
                <img src="/BetMas/resources/images/logo-adw.png" alt="Akademie der Wissenschaften in Hamburg logo"/>
            </a>
            <a class="poweredby" property="http://purl.org/dc/elements/1.1/publisher" href="https://www.betamasaheft.uni-hamburg.de/" target="_blank">
                <img src="/resources/images/logo.png" alt="Beta maṣāḥǝft Project logo"/>
            </a>
            <a class="poweredby" href="http://exist-db.org">
                <img src="$shared/resources/images/powered-by.svg" alt="Powered by eXist-db"/>
            </a>
            <a class="poweredby" href="http://www.tei-c.org/">
                <img src="/resources/images/We-use-TEI.png" alt="We use TEI"/>
            </a>
            <a class="poweredby" href="http://commons.pelagios.org/">
                <img src="/resources/images/Pelagios-logo.png" alt="Proud members of the Linked Pasts Network"/>
            </a>
            <a  href="https://iipimage.sourceforge.io/" >
                <img src="/resources/images/iip_logo.png" width="90px" alt="We use the IIP Image Server"/>
            </a>
            <a  href="https://iiif.io/" >
                <img src="/resources/images/iiif.png" width="90px" alt="Providing and resuing images with IIIF presentation API 2.0"/>
            </a>
            <a  href="https://www.zotero.org/groups/358366/ethiostudies/items" >
                <img src="/resources/images/zotero_logo.png" width="90px" alt="All bibliography is managed with Zotero."/>
            </a>
            
          </div></footer>};
