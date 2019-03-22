
      function startIntroHome(){
        var intro = introJs();
          intro.setOptions(
            {
            steps: [

              {
                element: "#about",
                intro: "Click here for general information about the app and some documentation.",
                position: 'bottom'
              },
              {
                element: '#works',
                intro: 'The clavis browsing window will open clicking one of the links in this menu. The Documents corpora view will show you documents as organized in the EMA project.',
                position: 'bottom'
              },
              {
                element: '#mss',
                intro: "Here you can choose to search all manuscripts, get a list of all catalogues or jump to the images of manuscripts directly.",
                position: 'bottom'
              },
              {
                element: '#places',
                intro: 'You can find here access to pages listing all places in our gazetteer and all repositories containing manuscripts.',
                position: 'bottom'
              },
              {
                element: '#persons',
                intro: 'You can find here access to the list of all persons in our authority files.',
                position: 'bottom'
              },
              {
                element: '#resources',
                intro: 'There are a lot of bibliographical references in our data, none of which is indexed by text. You can use the bibliography \
                in the submenu to get a list of all the references each with a list of the entities where they are \
                used. The INDEXES submenu will provide you with further access to authority files and to selected features which are marked-up. You can search through all binding and all decorations for example.argument\
                There are also three further tools which might be used. The manuscript comparison tool for a given work, the XPATH search to Xpath directly the XML data and the SPARQL endpoint to query our RDF.',
                position: 'bottom '
              },
              {
                element: '#q',
                intro: 'This is an easy text search form. it will search some common indexed elements in our data like titles and shelfmarks. \
                Do not expect it to return you all occurrences of a given name, or all attestations of a person, use for that the appropriate tools.',
                position: 'bottom '
              },
              {
                  element : '#furtherSearchOptions',
                  intro: 'The first of these buttons is a keyword you can use in alternative to your local entry methods. The second button is the one to run the search. \
                  The third button redirects you to the advanced search, where you can use any of the filters in the specific views and add to them a simple string search in selected elements. \
                  To jump to the Dillmann Lexion, click the book. For more information on how the saerch works, click the last info button.',
                  position:'left'
              },
              {
                  element : '#JumpToRecord',
                  intro: 'Do you already know the ID or the title of what you are looking for? Use this form to jump to that record.',
                  position:'left'
              },
              {
                  element : '#map',
                  intro: 'In this map you can see the institutions holding manuscripts, click on them to get directly to the one you are interested in.',
                  position:'right'
              },
              {
                  element : '#origPlaces',
                  intro: 'You can also try this visualization with the Daria-DE Geobrowser of the places of origin of the manuscripts.',
                  position:'right'
              }
            ]
          }).setOption('showProgress', true)
    ;

          intro.start();
      };
      
       function startIntroItem(){
        var intro = introJs();
          intro.setOptions(
            {
            steps: [

              {
                  element : '#showattestations',
                  intro: 'Click here to load a list of all attestations of the current entity.',
                  position:'bottom'
              },  {
                  element : '#seealsoSelector',
                  intro: 'Here we list all keywords assigned to this entity. Click on any to load a list of other entities with the same keyword.',
                  position:'bottom'
              },
               {
                  element : '#options',
                  intro: 'We cannot display everything we know in one page, there is often too much. You can switch between these views however to get more and different insights.',
                  position:'right'
              },
              {
                  element : '#mainPDF',
                  intro: 'Click here to download a formatted PDF.',
                  position:'bottom'
              },
              {
                  element : '#mainEntryLink',
                  intro: 'Click here to go back to the main view from any of the others.',
                  position:'bottom'
              },
              {
                  element : '#TEILink',
                  intro: 'Click here to download a postprocessed and reusable TEI XML. This is not the same as putting .xml at the end of the url after the id, as that will get you the source TEI XML.',
                  position:'bottom'
              },
              {
                  element : '#GraphViewLink',
                  intro: 'Click here to see graphic visualizations, which are different according to the data available and type of entity.',
                  position:'bottom'
              },
               {
                  element : '#options',
                  intro: 'There might be for different entities also other tabs activated (comparison, images, analytics), click and explore!',
                  position:'top'
              },
               {
                  element : '#citation',
                  intro: 'Not sure how to cite this page? If you have a plugin able to do so, import the embedded metadata in this page into your favourite bibliography tool. We use Zotero and love it.',
                  position:'top'
              },
               {
                  element : '#citation',
                  intro: 'check the header to see what the status of this entry is.',
                  position:'right'
              },
              {
                element: "#about",
                intro: "Click here for general information about the app and some documentation.",
                position: 'bottom'
              },
              {
                element: '#works',
                intro: 'The clavis browsing window will open clicking one of the links in this menu. The Documents corpora view will show you documents as organized in the EMA project.',
                position: 'bottom'
              },
              {
                element: '#mss',
                intro: "Here you can choose to search all manuscripts, get a list of all catalogues or jump to the images of manuscripts directly.",
                position: 'bottom'
              },
              {
                element: '#places',
                intro: 'You can find here access to pages listing all places in our gazetteer and all repositories containing manuscripts.',
                position: 'bottom'
              },
              {
                element: '#persons',
                intro: 'You can find here access to the list of all persons in our authority files.',
                position: 'bottom'
              },
              {
                element: '#resources',
                intro: 'There are a lot of bibliographical references in our data, none of which is indexed by text. You can use the bibliography \
                in the submenu to get a list of all the references each with a list of the entities where they are \
                used. The INDEXES submenu will provide you with further access to authority files and to selected features which are marked-up. You can search through all binding and all decorations for example.argument\
                There are also three further tools which might be used. The manuscript comparison tool for a given work, the XPATH search to Xpath directly the XML data and the SPARQL endpoint to query our RDF.',
                position: 'bottom '
              },
              {
                  element : '#codicologicalInformationms',
                  intro: 'If there is a collation and we have enough information, you will see also diagrams for each quire. The SVG graphics are produces with visColl. Each diagram has a title which gives the absolute position in the description of the quire (counting also the protection sheets) and the actual number of leaves in the quire. So  "Quire 1 (2)" means that is the very first quire in the collation element in the source XML file, and it has two leaves.',
                  position:'left'
              }
              ]
          }).setOption('showProgress', true);

          intro.start();
      }
      