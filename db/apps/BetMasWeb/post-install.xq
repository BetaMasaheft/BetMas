xquery version "3.1";

declare namespace sm="http://exist-db.org/xquery/securitymanager";

declare variable $target external;

sm:chown(xs:anyURI($target || '/modules/location.xqm'), "BetaMasaHeftAdmin"),
sm:chgrp(xs:anyURI($target || '/modules/location.xqm'), "dba"),
sm:chmod(xs:anyURI($target || '/modules/location.xqm'), "rwsr-sr-x")
