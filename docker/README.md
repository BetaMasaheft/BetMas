# Configuration options

The following configuration options have to be added to various eXist-DB files:

* etc/conf.xml
  * For element `db-connection/watchdog`, update the value of the attribute `@output-size-limit` to `5000000`.
  * For element `xquery`, add the attributes `@max-limit="1000"` and `min-limit="100"`.
* bin/startup.sh
  Update the „exec„ command to:
  ```shell
    exec "$JAVACMD" $JAVA_OPTS -Dsun.net.client.defaultConnectTimeout=10000 -Dsun.net.client.defaultReadTimeout=30000 -Xms512m -Xmx4g -XX:+UseG1GC -XX:+ParallelRefProcEnabled -Xlog:"gc=info:file="$BASEDIR"/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=20m" -Dfile.encoding=UTF-8 -Dlog4j.configurationFile="$BASEDIR"/etc/log4j2.xml -Dexist.home="$BASEDIR" -Dexist.configurationFile="$BASEDIR"/etc/conf.xml -Djetty.home="$BASEDIR" -Dexist.jetty.config="$BASEDIR"/etc/jetty/standard.enabled-jetty-configs -Djava.io.tmpdir="$BASEDIR"/tmp \
      -classpath "$CLASSPATH" \
      -Dapp.name="startup" \
      -Dapp.pid="$$" \
      -Dapp.repo="$REPO" \
      -Dapp.home="$BASEDIR" \
      -Dbasedir="$BASEDIR" \
      org.codehaus.mojo.appassembler.booter.AppassemblerBooter \
      "$@"
  ``` 

