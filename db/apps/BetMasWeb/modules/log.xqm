xquery version "3.1";
(:This module adds messages to the log file it is based on the example from the exist book page 62-64:)
module namespace log="http://www.betamasaheft.eu/log";

declare namespace test="http://exist-db.org/xquery/xqsuite";


declare function log:add-log-message($message as xs:string)
as empty-sequence()
{
   let $logfile-collection := '/db/apps/log'
   let $logfile-name := 'bm-log'||format-date(current-date(), '[Y0][M0][D0]')||'.xml'
   let $logfile-full := concat($logfile-collection, '/', $logfile-name)
   let $logfile-created := if(doc-available($logfile-full)) then $logfile-full else 
   (xmldb:store($logfile-collection, $logfile-name, <betmaslog/>), 
   sm:chgrp(xs:anyURI($logfile-full), 'Cataloguers'), 
sm:chmod(xs:anyURI($logfile-full), 'rwxrwxrw-'))
   
   return
       
       update insert
       <logentry timestamp="{current-dateTime()}">{$message}</logentry>
    into
    doc($logfile-full)/*
};


declare function log:add-log-message($url as xs:string, $user as xs:string, $type as xs:string)
as empty-sequence()
{
if($user = 'guest') then ()
else
   let $logfile-collection := '/db/apps/log'
   let $logfile-name := 'bm-log'||format-date(current-date(), '[Y0][M0][D0]')||'.xml'
   let $logfile-full := concat($logfile-collection, '/', $logfile-name)
   let $logfile-created := if(doc-available($logfile-full)) then $logfile-full else 
   (xmldb:store($logfile-collection, $logfile-name, <betmaslog xmlns="http://log.log"/>), 
   sm:chgrp(xs:anyURI($logfile-full), 'Cataloguers'), 
sm:chmod(xs:anyURI($logfile-full), 'rwxrwxrw-'))
   
   return
       
       update insert
              <logentry xmlns="http://log.log" timestamp="{current-dateTime()}">
                   <user>{ $user }</user>
                   <type>{ $type }</type>
                   <url>{ $url }</url>
              </logentry>
    into
    doc($logfile-full)/*
};
