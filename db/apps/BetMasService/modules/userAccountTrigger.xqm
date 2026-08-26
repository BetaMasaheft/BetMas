xquery version "3.1" encoding "UTF-8";

(:~
 : XQueryTrigger entry points for the account-persistence trigger.
 :
 : eXist's XQueryTrigger only looks up callback functions in the fixed
 : namespace http://exist-db.org/xquery/trigger (confirmed empirically
 : against a live eXist-db 6.4.1 instance - the "local:" binding-prefix
 : convention some docs describe did not work here), so this module has to
 : declare itself in that exact namespace. The real logic lives in
 : userAccountSync.xqm, kept separate so it can be imported normally under
 : its own descriptive namespace elsewhere (e.g. BetMasInitInstance).
 :
 : Registered via the collection.xconf finish.xq installs on
 : /db/system/security/exist/accounts.
 :)
module namespace trigger = "http://exist-db.org/xquery/trigger";

import module namespace userAccountSync = "https://www.betamasaheft.uni-hamburg.de/BetMasService/userAccountSync"
	at "userAccountSync.xqm";

declare function trigger:after-create-document($uri as xs:anyURI) {
	userAccountSync:sync-account($uri)
};

declare function trigger:after-update-document($uri as xs:anyURI) {
	userAccountSync:sync-account($uri)
};

declare function trigger:after-delete-document($uri as xs:anyURI) {
	userAccountSync:remove-account($uri)
};
