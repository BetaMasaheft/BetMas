xquery version "3.1";
(:This module adds messages to the log file it is based on the example from the exist book page 62-64:)
module namespace log="http://www.betamasaheft.eu/log";

declare namespace test="http://exist-db.org/xquery/xqsuite";


declare function log:add-log-message($message as xs:string)
as empty-sequence()
{
   util:log('info', $message)
};


declare function log:add-log-message($url as xs:string, $user as xs:string, $type as xs:string)
as empty-sequence()
{
	util:log('info', 
		<logentry xmlns="http://log.log" timestamp="{current-dateTime()}">
			<user>{ $user }</user>
			<type>{ $type }</type>
			<url>{ $url }</url>
		</logentry>
	)
};
