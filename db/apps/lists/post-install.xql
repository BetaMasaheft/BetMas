xquery version "3.1";

declare namespace sm = "http://exist-db.org/xquery/securitymanager";

(: The following external variables are set by the repo:deploy function. :)
declare variable $home external;
declare variable $dir external;
declare variable $target external;

for $resource in (
	"editors.xml",
	"languages.xml",
	"listPrefixDef.xml",
	"catalogues.xml",
	"domlib.xml",
	"canonicaltaxonomy.xml",
	"institutions.xml",
	"deleted.xml"
)
return sm:chmod(xs:anyURI($target || "/" || $resource), "rw-r--r--")
