$(function() {
        Mirador({
          id: "viewer",
          data: data,
          "mainMenuSettings" : {
            "userLogo": {
              "label": "Beta maṣāḥǝft Image Viewer",
              "attributes": { "id": "bm-logo", "href": "https://betamasaheft.eu"}
            }
          },
           manifestsPanel: {
    name: "Collection tree browser",
    module: "CollectionTreeManifestsPanel"
  },
          openManifestsPage: true
        });
      });
      
      
      