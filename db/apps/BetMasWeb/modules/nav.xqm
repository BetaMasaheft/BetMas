xquery version "3.1" encoding "UTF-8";
(:~
 : module with the main nav bar and the modals it calls
 : @author Pietro Liuzzo 
 :)
module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace locallogin = "https://www.betamasaheft.eu/login" at "xmldb:exist:///db/apps/BetMasWeb/modules/login.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
declare function nav:modalsNew() {
    <div
        id="versionInfo"
        class="w3-modal">
        <div
            class="w3-modal-content">
            <div
                class="w3-container">
                <span
                    onclick="document.getElementById('versionInfo').style.display='none'"
                    class="w3-button w3-display-topright"><i
                        class="fa fa-times"></i></span>
                <p> You are looking at work in progress version of this website.
                    For questions <a
                        href="mailto:pietro.liuzzo@uni-hamburg.de?Subject=Issue%20Report%20BetaMasaheft">contact the dev team</a>.</p>
                
                <p> Hover on words to see search options.</p>
                <p>Double-click to see morphological parsing.</p>
                <p> Click on left pointing hands and arrows to load related items and click once more to view the result in a popup.</p>
            
            </div>
        </div>
    </div>
};


declare function nav:barNew() {
    let $url := try {
        request:get-url()
    } catch * {
        ''
    }
    return
        (<div
            class="w3-top">
            <div
                class="w3-bar w3-black w3-card">
                <a
                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  w3-hide-medium w3-hide-large w3-right"
                    href="javascript:void(0)"
                    onclick="myFunction()"
                    title="Toggle Navigation Menu"><i
                        class="fa fa-bars"></i></a>
                {
                    if (ends-with($url, '.html') or ($url = $config:appUrl) or ends-with($url, 'BetMas/')) then
                        locallogin:loginNew()
                    else
                        ()
                }
                
                <div
                    class="w3-dropdown-hover w3-hide-small"
                    id="about">
                    <button
                        class=" w3-button"
                        title="about">
                        {
                            if (string-length($url) gt 1) then
                                ('Hi ' || sm:id()//sm:username/text() || '!')
                            else
                                ('Home')
                        }
                        <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content w3-bar w3-card-4">
                        {
                            if (sm:is-authenticated() and contains(sm:get-user-groups(sm:id()//sm:username/text()), 'Editors')) then
                                (
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                                    href="/user/{sm:id()//sm:real/sm:username/string()}">Your personal page</a>
                                ,
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                                    href="/clavismatching.html">Clavis Matching</a>
                                )
                            else
                                ()
                        }
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/">Home</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/about.html">About</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/Guidelines/">Guidelines</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/lod.html">Data</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/apidoc.html">API</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/pid.html">Permalinks</a>
                    
                    </div>
                </div>
                  
                <div
                    class="w3-dropdown-hover w3-hide-small"
                    id="mss">
                    <button
                        class=" w3-button"
                        title="manuscripts">Manuscripts <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content" style="background:transparent;">
                        <div
                            class="w3-threequarter">
                            <div
                                class=" w3-bar w3-card-4 w3-white">
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="shelfmarks"
                                    href="/manuscripts/browse">Shelf marks (full list)</a>
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="manuscriptsearch"
                                    href="/newSearch.html?searchType=text&amp;mode=any&amp;type=mss">Manuscripts (search)</a>
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="imagesviewer"
                                    href="/manuscripts/viewer">Images Viewer</a>
                                    <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="imagesviewer"
                                    href="/availableImages.html">List of Images Available Elsewhere</a>
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="cataloguesencoded"
                                    href="/catalogues/list">Catalogues Encoded</a>
                                <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="inscriptions"
                                    href="/newSearch.html?searchType=text&amp;mode=any&amp;form=Inscription">Inscriptions</a>
                            </div>
                            <div
                                id="navexplanationsmss"
                                class="w3-row">
                                <span
                                    id="shelfmarks"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    Here you can browse a full list of manuscripts available on the platform, arranged by repositories and shelf marks (clicking on the "show list" button will expand the list for each location). </span>
                             <span
                                    id="manuscriptsearch"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    In this search form you can search for (filter) all manuscripts encoded by the project. On the left side you get filters based on the indexes for that type of resources in the database, on the right side you will see, after searching, your results as in a table, paginated by 20 as per defaults. You can change the pagination option once you have done your search by entering a value in the "how many per page?" field of the pagination bar. Clicking on the hints button above will produce some additional blinking buttons which will provide additional guidance on the content.
For more guidance in lists and filters visit the help page.
</span>
                            <span
                                    id="imagesviewer"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    The Mirador viewer can show all images of manuscripts we are currently serving or we have a usable link to a manifest for. You can either directly view the images in this mirador instance or click on the info box and go to the record for that manuscript.
</span>
<span
                                    id="cataloguesencoded"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    The list of catalogue sources used for our manuscript descriptions. 
                                    Clicking on one of the titles will open a list view with all the manuscripts in that catalogue 
                                    for which we have a record.</span>
<span
                                    id="inscriptions"
                                    class="w3-hide w3-red w3-center w3-padding">
                                   While the Beta maṣāḥǝft project focuses on manuscripts, inscriptions 
                                   are often an inseparable part of the manuscript tradition and its direct precursors, 
                                   therefore we also offer the encoding of the known inscriptions from Ethiopia and Eritrea 
                                   wherever possible. Part of the encoding is carried out in Hamburg, part is the result of 
                                   cooperation with other projects, such as DASI: Digital Archive for the Study of pre-islamic
                                   Arabian Inscriptions (http://dasi.cnr.it/).
For more guidance in lists and filters visit the help page.</span>
                            </div>
                        </div>
                        <div
                            class="w3-quarter">
                            <div
                                class="w3-gray w3-padding"
                                id="manuscriptsmenuintro">Producing online descriptions of (predominantly) Christian manuscripts 
                                from Ethiopia and Eritrea is the main aim of the Beta maṣāḥǝft project. 
                                We (1) gradually encode descriptions from printed catalogues, beginning from the historical ones, 
                                (2) incorporate digital descriptions produced by other projects, adjusting them wherever possible, 
                                and (3) produce descriptions of previously unknown and/or uncatalogued manuscripts. 
                                The encoding follows the TEI XML standards (for the encoding specifics you can 
                                check our <a href="https://betamasaheft.eu/Guidelines/?id=manuscripts">guidelines</a>).</div>
                        </div>
                    </div>
                </div>
                 
                 <div
                    class="w3-dropdown-hover w3-hide-small"
                    id="works">
                    <button
                        class=" w3-button"
                        title="Works">Texts <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content"  
                        style="background:transparent;">
                        <div
                        class="w3-threequarter">
                      <div
                        class="w3-bar w3-card-4 w3-white">
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="clavis"
                            href="/works/list">Clavis Aethiopica (Works)</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="narratives"
                            href="/narratives/list">Narrative Units</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="documentary"
                            href="/documentcorpora.html">Documentary corpora</a>
                             <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="studies"
                            href="/studies/list">Studies</a>
                            </div>
                            <div id="explanationsTexts">
                            <span
                                    id="clavis"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    The project Beta maṣāḥǝft is working towards creating an exhaustive repertory of all works circulating in Ethiopian and Eritrean manuscript tradition. We consider a work any text with an independent circulation. Every clearly identifiable textual unit receives a unique number, which scholars now may use to univocally refer to a specific text in their publications. In case of multiple recensions or subtypes of a work, a Clavis ID is created for both the general record or the broader class of works and for each particular version.
In the filter search offered here one can search for a work by its label, a keyword, but also directly by its CAe identifier - or, wherever known and provided, identifier used by other claves, including Bibliotheca Hagiographica Graeca (BHG), Clavis Patrum Graecorum (CPG), Clavis Coptica (CC), Clavis Apocryphorum Veteris Testamenti (CAVT), Clavis Apocryphorum Novi Testamenti (CANT), etc.
                                    </span>
                                      <span
                                    id="narratives"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    The project additionally identifies Narrative Units to refer to recurring motifs or text types, where no clavis identification is possible or necessary. Frequently documentary additiones are assigned a Narrative Unit ID, or thematically clearly demarkated passages from various recensions of a larger work.
                                    </span>
                                      <span
                                    id="documentary"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    This particular category is the result of cooperation between the project Beta maṣāḥǝft and the project Ethiopian Manuscript Archives. The EMA project, initially developed in 2010 by Anaïs Wion, and now part of the later project EthioChrisProcess - Christianization and religious interactions in Ethiopia (6th-13th century) : comparative approaches with Nubia and Egypt (ANR, 2018-2022, https://anr.fr/Project-ANR-17-CE27-0020), aims to edit and equip the corpus of administrative acts
of the Christian kingdom of Ethiopia, for medieval and modern periods. The list view shows the documentary collections encoded.
For a list of documents contained in the additiones in the manuscripts described by the Beta maṣāḥǝft project see https://betamasaheft.eu/additions.
</span>
 <span
                                    id="studies"
                                    class="w3-hide w3-red w3-center w3-padding">
                                   Works of interest to Ethiopian and Eritrean studies.
                                   </span>
                            </div>
                            </div>
                            <div
                        class="w3-quarter">
                        <div
                        class="w3-gray w3-padding">
                        We clearly identify each unit of content in every manuscript. We consider any 
                        text with an independent circulation a work, with its own identification number within 
                        the Clavis Aethiopica (CAe, see below). Parts of texts (e.g. chapters) 
                        without independent circulation are assigned identifiers within a record. 
                        They are thus still univocally identifiable but are not part of the Clavis. 
                        Recurrent motifs and documentary additional texts, while not being considered individual works, 
                        are identified as Narrative Units - they are not part of the Clavis Aethiopica.
Additional relevant resources include the list of different <a href="/titles">types of text titles</a> encoded by the 
project, textual motifs as appearing in illuminations (see the Art themes 
filter in the <a href="/authority-files/list">keyword list</a> or the index of 
<a href="/decorations">decorations</a>), and the index 
of <a href="/additions">additional texts</a> of different types present in the manuscripts.
                        </div>
                        </div>
                    </div>
                </div>
            
            
                 <div
                    class="w3-dropdown-hover w3-hide-small">
                    <button
                        class=" w3-button"
                        title="Works">Art Themes <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content" style="background:transparent;">
                        <div
                        class="w3-threequarter">
                      <div
                        class="w3-bar w3-card-4 w3-white">
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="decorations"
                            href="/decorations">Index of decorations</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="artkeywords"
                            href="/authority-files/list">Art Keywords</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                            data-value="illuminations"
                            href="/newSearch.html">Illuminations</a>
                            </div>
                            <div id="explanationsAT">
                            <span
                                    id="decorations"
                                    class="w3-hide w3-red w3-center w3-padding">
                                   The decorations filtered search, originally designed with Jacopo Gnisci, looks at decorations and their features only. The filters on the left are relative only to the selected features, reading the legends will help you to figure out what you can filter. For example you can search for all encoded decorations of a specific art theme, or search the encoded legends. If the decorations are present, but not encoded, you will not get them in the results. If an image is available, you will also find a thumbnail linking to the image viewer for that manuscript.
                                   </span>
                                      <span
                                    id="artkeywords"
                                    class="w3-hide w3-red w3-center w3-padding">
                                    You can search for particular motifs or aspects, including style, also through the keyword search. Just click on "Art keywords" and "Art themes" on the left to browse through the options.</span>
                                       <span
                                    id="illuminations"
                                    class="w3-hide w3-red w3-center w3-padding">
                                   This is a short cut to a search for all those manuscripts which have miniatures of which we have images.</span>
                                      
                            </div>
                            </div>
                            <div
                        class="w3-quarter">
                        <div
                        class="w3-gray w3-padding">
                        While encoding the information on the decorations present
                        in the manuscripts, the project Beta maṣāḥǝft aims at creating an 
                        exhaustive repertory of art themes and techniques present in Ethiopian 
                        and Eritrean Christian tradition. You can check our encoding guidelines 
                        at https://betamasaheft.eu/Guidelines/?q=art%20theme&amp;id=decorationDescription.
Two types of searches for aspects of manuscript decoration are possible, the decorations filtered search and the general keyword search.
                        </div>
                        </div>
                    </div>
                </div>
            
            
               <div
                    class="w3-dropdown-hover w3-hide-small"
                    id="places">
                    <button
                        class=" w3-button"
                        title="Places">Places <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content"  style="background:transparent;">
                         <div
                        class="w3-threequarter">
                    <div
                        class=" w3-bar w3-card-4 w3-white" >
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
                            data-value="places"
                            href="/places/list">Places</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
                            data-value="repositories"
                            href="/institutions/list">Repositories</a>
                            </div>
                         <div id="explanationPl">
                         <span
                                    id="places"
                                    class="w3-hide w3-red w3-center w3-padding">
                                  This tab offers a filterable list of all available places. Geographical references of the type "land inhabited by people XXX" is encoded with the reference to the corresponding Ethnic unit (see below); ethnonyms, even those used in geographical contexts, do not appear in this list. For more guidance in lists and filters visit https://betamasaheft.eu/help.html.
                                  </span>
                                     <span
                                    id="repositories"
                                    class="w3-hide w3-red w3-center w3-padding">
                                 Repositories are those locations where manuscripts encoded by the project are or used to be preserved. While they are encoded in the same way as all places are, the view offered is different, showing a list of manuscripts associated with the place. For more guidance in lists and filters visit https://betamasaheft.eu/help.html. </span>
                        </div>
                    </div>  
                    <div
                        class="w3-quarter">
                        <div
                        class="w3-gray w3-padding">
                        We create metadata for all places associated with the manuscript production and circulation as well as those mentioned in the texts used by the project. The encoding of places in Beta maṣāḥǝft will thus result in a Gazetteer of the Ethiopian tradition. We follow the principles established by Pleiades (https://pleiades.stoa.org/places) and lined out in the Syriaca.org TEI Manual and Schema for Historical Geography (http://syriaca.org/geo/index.html) which allow us to distinguish between places, locations, and names of places.
Place records should ideally contain the attested names of the place in local languages and translation, including possible variants, as well as any information available on the foundation of the place, its existence and development. Coordinates can be added or will be retrieved if a reference to the place’s Wikidata ID is given.
As this is a work in progress, and many records were inherited from the Encyclopaedia Aethiopica, there are still many inconsistencies that we are trying to gradually fix.
                         
                        </div>
                        </div>
                    </div>
                </div>
                
                   <div
                    class="w3-dropdown-hover w3-hide-small"
                    id="persons">
                    <button
                        class=" w3-button"
                        title="Persons">Persons <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content"  style="background:transparent;">
                         <div
                        class="w3-threequarter">
                    <div
                        class=" w3-bar w3-card-4 w3-white">
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/persons/list">Persons and groups</a>
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
                            data-value="ethnics"
                            href="/persons/list">Ethnic units</a>
                            </div>
                         <div id="explanationPr">
                         <span
                                    id="ethnics"
                                    class="w3-hide w3-red w3-center w3-padding">
                                  We see ethnonyms as a subcategory of personal names, even when many are often used in literary works in the context of the "land inhabited by **". The present list of records has been mostly inherited from the Encyclopaedia Aethiopica, and there are still many inconsistencies that we are trying to gradually fix.</span>
                                    </div>
                    </div>  
                    <div
                        class="w3-quarter">
                        <div
                        class="w3-gray w3-padding">
                       We create metadata for all persons (and groups of persons) associated with the manuscript production and circulation (rulers, religious authorities, scribes, donors, and commissioners) as well as those mentioned in the texts used by the project. The encoding of persons in Beta maṣāḥǝft will thus result in a comprehensive Prosopography of the Ethiopian tradition. Records should contain the person’s original and transliterated names and basic information on their life and occupations as well as a reference to their Wikidata ID, if existing.
As this is a work in progress, and many records were inherited from the Encyclopaedia Aethiopica, there are still many inconsistencies that we are trying to gradually fix.
For more guidance in lists and filters visit https://betamasaheft.eu/help.html.  
                        </div>
                        </div>
                    </div>
                </div>
                    
                    
              <div
                    class="w3-dropdown-hover w3-hide-medium w3-hide-small"
                    id="resources">
                    <button
                        class=" w3-button "
                        title="resources">Resources <i
                            class="fa fa-caret-down"></i></button>
                    <div
                        class="w3-dropdown-content w3-bar w3-card-4">
                        
                        <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/bibliography">Bibliography</a>
                       <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/indexeslist.html">Indexes</a>
                           <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/projects.html">Projects</a>
                           <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/visualizations.html">Visualizations</a>
                       <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/morpho">Gǝʿǝz Morphological Parser (TraCES project)</a>
                       <a
                            class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
                            href="/Dillmann">Online <i>Lexicon Linguae Aethiopicae</i> (TraCES project)</a>     
                    </div>
                </div>
         
                <a
                    href="/help.html"
                    class="w3-bar-item w3-button  w3-hide-medium w3-hide-small"
                    data-toggle="tooltip"
                    data-placement="bottom"
                    title="How to navigate this website">Help</a>
                
                {nav:newentryNew()}
                
                {
                    if (contains($url, 'as.html')) then
                        <a
                            href="/facet.html"
                            class="w3-padding w3-hover-red w3-hide-small w3-right"><i
                                class="fab fa-search"></i></a>
                    else
                        (<a
                            href="/facet.html"
                            class="w3-padding w3-hover-red w3-hide-small w3-right"><i
                                class="fa fa-search"></i></a>,
                        <a
                            href="/as.html"
                            class="w3-padding w3-hover-red w3-hide-small w3-right"><i
                                class="fab fa-searchengin"></i></a>)
                }
            </div>
        </div>,
        <div
            id="navDemo"
            class="w3-bar-block w3-black w3-hide w3-hide-large w3-hide-medium w3-top"
            style="margin-top:46px">
            <a
                href="/"
                class="w3-bar-item w3-button w3-padding-large"
                onclick="myFunction()">Home</a>
            <a
                href="/works/list"
                class="w3-bar-item w3-button w3-padding-large"
                onclick="myFunction()">Texts</a>
            <a
                href="/manuscripts/list"
                class="w3-bar-item w3-button w3-padding-large"
                onclick="myFunction()">Manuscripts</a>
            <a
                href="/facet.html"
                class="w3-bar-item w3-button w3-padding-large"
                onclick="myFunction()">Search</a>
        </div>
        )
};


declare function nav:newentryNew() {
    if (contains(sm:get-user-groups(sm:id()//sm:real/sm:username/string()), 'Editors')) then
        
        <form
            action="/newentry.html"
            class="w3-bar-item w3-hide-medium w3-hide-small"
            style="margin:0;padding:0"
            role="tag">
            <select
                name="collection"
                required="required"
                class="w3-bar-item w3-select  w3-twothird">
                <option
                    value="manuscripts">manuscript</option>
                <option
                    value="persons">person</option>
                <option
                    value="works">work</option>
                <option
                    value="narratives">narrative</option>
                <option
                    value="places">place</option>
                <option
                    value="authority-files">authority file</option>
                <option
                    value="institutions">institution</option>
            </select>
            <button
                type="submit"
                class="w3-bar-item w3-button  w3-red  w3-third">new</button>
        </form>
    else
        ()
};


declare function nav:footerNew() {
    
    <footer
        class="w3-container w3-padding-64 w3-center"
       
        id="footer">
        <div class="w3-third">
        <div class="w3-margin">
        
        <p  style="text-align:left;">Copyright © <span
                    property="http://purl.org/dc/elements/1.1/publisher">Akademie der Wissenschaften in Hamburg,
                    Hiob-Ludolf-Zentrum für Äthiopistik</span>. Sharing and remixing permitted under terms of the 
                    <a
                    rel="license"
                    property="http://creativecommons.org/ns#license"
                    href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License <img  
                        alt="Creative Commons License"
                        style="border-width:0"
                        src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png"/></a>. Project DOI: {$config:DOI}.
               </p>
        <div id="wcb" class="carbonbadge w3-row"></div>
        </div>
        </div>
        <div class="w3-third">
        <div class=" w3-container w3-border-left w3-margin">
        <div class="w3-half"> 
        <div class="w3-bar-block">  
         <a class="w3-bar-item" 
                property="http://purl.org/dc/elements/1.1/publisher"
                href="http://www.awhamburg.de/"
                target="_blank">
                <img width="100%" style="border-width:0"
                    src="resources/images/logo-adw.png"
                    alt="Akademie der Wissenschaften in Hamburg logo"/>
            </a>
            <a class="w3-bar-item"
                property="http://purl.org/dc/elements/1.1/publisher"
                href="https://www.betamasaheft.uni-hamburg.de/"
                target="_blank">
                <img width="100%"  style="border-width:0"
                    src="resources/images/logo.png"
                    alt="Beta maṣāḥǝft Project logo"/>
            </a></div>
            </div>
        
        <div class="w3-half">
        <p style="text-align:left;">The domain betamasaheft.eu is hosted by Universität Hamburg.</p>
            <p  style="text-align:left;">This website is maintained by the project team at the <a
                    href="https://www.aai.uni-hamburg.de/en/ethiostudies.html">Hiob Ludolf Center for Ethiopian and Eritrean Studies</a>.</p>
            <p style="text-align:left;"><a
                    href="/impressum.html">Impressum.</a></p>
        </div>
        </div>
        </div>
        <div class="w3-third">
        <div class="w3-container w3-margin w3-border-left" style="text-align:left">
        <div class="w3-margin">
        
        <div class="w3-bar">
        <a
                class="w3-bar-item"
                href="http://www.tei-c.org/">
                <img width="100"
                    src="resources/images/We-use-TEI.png"
                    alt="We use TEI"/>
            </a>
            <a class="w3-bar-item"
                href="https://iiif.io/">
                <img 
                    src="resources/images/iiif.png"
                    width="50"
                    alt="Providing and resuing images with IIIF presentation API 2.0"/>
            </a>
            <a
                class=" w3-bar-item"
                href="http://exist-db.org">
                <img width="100"
                    src="$shared/resources/images/powered-by.svg"
                    alt="Powered by eXist-db"/>
            </a>
            </div>
            <div class="w3-bar">
             <a  class="w3-bar-item"
                href="https://www.zotero.org/groups/358366/ethiostudies/items">
                <img width="40"
                    src="resources/images/zotero_logo.png"
                    
                    alt="All bibliography is managed with Zotero."/>
            </a>
            <a  class="w3-bar-item"
                href="https://github.com/BetaMasaheft">
                <img
                    src="resources/images/GitHub-Mark-120px-plus.png"
                    width="40"
                    alt="Our data is all in GitHub!"/>
            </a>
            <a
                class=" w3-bar-item"
                href="http://commons.pelagios.org/">
                <img width="90"
                    src="resources/images/Pelagios-logo.png"
                    alt="Proud members of the Linked Pasts Network"/>
            </a>
            <a class="w3-bar-item"
                href="https://iipimage.sourceforge.io/">
                <img width="40"
                    src="resources/images/iip_logo.png"
                    alt="We use the IIP Image Server"/>
            </a>
            </div>
            <p>Powered by <a
                href="https://www.w3schools.com/w3css/default.asp"
                target="_blank">w3.css</a></p>
        <p >Many thanks for their wonderful work to all the developers of free software for the code we use throughout the website.</p>
        </div>
        </div>
        </div>
        
    </footer>

};
