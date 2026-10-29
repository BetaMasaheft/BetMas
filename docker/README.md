# Configuration options

The following configuration options have to be added to various eXist-DB files:

* conf.xml
  * For element `db-connection/watchdog`, update the value of the attribute `@output-size-limit` to `5000000`.
  * For element `xquery`, add the attributes `@max-limit="1000"` and `min-limit="100"`.

