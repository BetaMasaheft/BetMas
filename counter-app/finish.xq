
xmldb:create-collection($target, "data"),
xmldb:store($target || "/data" , "counter.xml", <counter>1</counter>),
sm:chown(xs:anyURI($target || "/data" || "/counter.xml"), "guest"),
util:log("info", "Counter app initialized")
