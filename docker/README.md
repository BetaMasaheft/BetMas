# Configuration options

The following configuration options have to be added to various eXist-DB files:

* conf.xml
  * For element `db-connection`, the child element
  ```xml
  <watchdog output-size-limit="5000000" query-timeout="-1"/>
  ```
  * For element `xquery`, the attributes `@max-limit="1000"` and `min-limit="100"`.

