<xsl:stylesheet xmlns:pleiades="https://pleiades.stoa.org/" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:bm="http://betamasaheft.eu/" xmlns:wd="https://www.wikidata.org/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:oa="http://www.w3.org/ns/oa#" xmlns:rel="http://purl.org/vocab/relationship/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:pelagios="http://pelagios.github.io/vocab/terms#" xmlns:syriaca="http://syriaca.org/documentation/relations.html#" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" xmlns:saws="http://purl.org/saws/ontology#" xmlns:iha="http://islhornafr.tors.sc.ku.dk/" xmlns:funct="http://myfunction" xmlns:gn="http://www.geonames.org/ontology#" xmlns:agrelon="http://d-nb.info/standards/elementset/agrelon.owl#" xmlns:lawd="http://lawd.info/ontology/" xmlns:SdC="https://w3id.org/sdc/ontology#" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ecrm="http://erlangen-crm.org/current/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:snap="http://data.snapdrgn.net/ontology/snap#" xmlns:dc="http://purl.org/dc/elements/1.1/" exclude-result-prefixes="funct" version="2.0">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    <xsl:function name="funct:date">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, '\d{4}-\d{2}-\d{2}')">
                <xsl:value-of select="$date"/>
            </xsl:when>
            <xsl:when test="matches($date, '\d{4}-\d{2}$')">
                <xsl:value-of select="concat($date, '-01')"/>
            </xsl:when>
            <xsl:when test="matches($date, '\d{4}$')">
                <xsl:value-of select="concat($date, '-01-01')"/>
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="funct:id">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="starts-with($id, 'http')">
                <xsl:value-of select="$id"/>
            </xsl:when>
            <xsl:when test="contains($id, 'SdC:')">
                <xsl:value-of select="concat('https://w3id.org/sdc/ontology#', substring-after($id, 'SdC:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'skos:')">
                <xsl:value-of select="concat('http://www.w3.org/2004/02/skos/core#', substring-after($id, 'skos:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'saws:')">
                <xsl:value-of select="concat('http://purl.org/saws/ontology#', substring-after($id, 'saws:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'snap:')">
                <xsl:value-of select="concat('http://data.snapdrgn.net/ontology/snap#', substring-after($id, 'snap:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'gn:')">
                <xsl:value-of select="concat('http://www.geonames.org/ontology#', substring-after($id, 'gn:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'dcterms:')">
                <xsl:value-of select="concat('http://purl.org/dc/terms/', substring-after($id, 'dcterms:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'bm:')">
                <xsl:value-of select="concat('http://betamasaheft.aai.uni-hamburg.de/docs.html#', $id)"/>
            </xsl:when>
            <xsl:when test="contains($id, 'lawd:')">
                <xsl:value-of select="concat('http://lawd.info/ontology/', substring-after($id, 'lawd:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'syriaca:')">
                <xsl:value-of select="concat('http://syriaca.org/documentation/relations.html#', substring-after($id, 'syriaca:'))"/>
               <!-- <xsl:text>http://syriaca.org/documentation/relations.html#</xsl:text>
                <xsl:value-of select="$id"/>-->
            </xsl:when>
            <xsl:when test="contains($id, 'agrelon:')">
                <xsl:value-of select="concat('http://d-nb.info/standards/elementset/agrelon.owl#', substring-after($id, 'agrelon:'))"/>
            </xsl:when>
            <xsl:when test="contains($id, 'rel:')">
                <xsl:value-of select="concat('http://purl.org/vocab/relationship/', substring-after($id, 'rel:'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="subid">
                    <xsl:choose>
                        <xsl:when test="contains($id, '#')">
                            <xsl:variable name="mainPart" select="substring-before($id,'#')"/>
                            <xsl:variable name="anchor" select="substring-after($id,'#')"/>
                            <xsl:variable name="type">
                                
                                <xsl:choose>
                                    <xsl:when test="starts-with($anchor, 'ms')">msitem</xsl:when>
                                    <xsl:when test="starts-with($anchor, 't')">title</xsl:when>
                                <xsl:when test="starts-with($anchor, 'q')">quire</xsl:when>
                                <xsl:when test="starts-with($anchor, 'h')">hand</xsl:when>
                                <xsl:when test="starts-with($anchor, 'b')">binding</xsl:when>
                                <xsl:when test="starts-with($anchor, 'd')">decoration</xsl:when>
                                <xsl:when test="starts-with($anchor, 'a')">addition</xsl:when>
                                <xsl:when test="starts-with($anchor, 'e')">addition</xsl:when>
                                <xsl:when test="starts-with($anchor, 'p')">
                                    <xsl:choose>
                                        <xsl:when test="contains($anchor, '_') and contains($anchor, 'coloph')">colophon</xsl:when>
                                        <xsl:when test="contains($anchor, '_') and contains($anchor, 'i')">msitem</xsl:when>
                                        <xsl:otherwise>mspart</xsl:otherwise>
                                    </xsl:choose>
                                   </xsl:when>
                                <xsl:when test="starts-with($anchor, 'f')">
                                    <xsl:choose>
                                        <xsl:when test="contains($anchor, '_') and contains($anchor, 'i')">msitem</xsl:when>
                                        <xsl:otherwise>msfrag</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:when test="starts-with($anchor, 'tr')">transformation</xsl:when>
                                <xsl:when test="starts-with($anchor, 'Uni')">
                                    <xsl:choose>
                                        <xsl:when test="contains($anchor, 'Prod')">UniProd</xsl:when>
                                        <xsl:when test="contains($anchor, 'Circ')">UniCirc</xsl:when>
                                        <xsl:when test="contains($anchor, 'Cah')">UniCah</xsl:when>
                                        <xsl:when test="contains($anchor, 'Cont')">UniCont</xsl:when>
                                        <xsl:when test="contains($anchor, 'Ecri')">UniEcri</xsl:when>
                                        <xsl:when test="contains($anchor, 'Main')">UniMain</xsl:when>
                                        <xsl:when test="contains($anchor, 'Marq')">UniMarq</xsl:when>
                                        <xsl:when test="contains($anchor, 'Mat')">UniMat</xsl:when>
                                        <xsl:when test="contains($anchor, 'MeP')">UniMeP</xsl:when>
                                        <xsl:when test="contains($anchor, 'Regl')">UniRegl</xsl:when>
                                        <xsl:otherwise>WrongUnitName</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                            <xsl:otherwise>part</xsl:otherwise>
                                </xsl:choose>
                                
                            </xsl:variable>
                            <xsl:value-of select="concat($mainPart, '/', $type, '/', $anchor)"/>
                        </xsl:when>
                        <xsl:otherwise><xsl:value-of select="$id"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="concat('http://betamasaheft.eu/', $subid)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="t:TEI">
        <rdf:RDF>
            <xsl:variable name="mainID" select="@xml:id"/>
            <!--<xsl:variable name="ids">
                <xsl:for-each select="current()/ancestor::t:TEI//@xml:id">
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:variable>-->
            <xsl:variable name="collection">
                <xsl:choose>
                    <xsl:when test="@type = 'mss'">manuscripts</xsl:when>
                    <xsl:when test="@type = 'work'">works</xsl:when>
                    <xsl:when test="@type = 'nar'">narratives</xsl:when>
                    <xsl:when test="@type = 'place'">places</xsl:when>
                    <xsl:when test="@type = 'pers'">persons</xsl:when>
                    <xsl:when test="@type = 'ins'">institutions</xsl:when>
                    <xsl:otherwise>authority-files</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="xmluri">
                <xsl:value-of select="concat('http://betamasaheft.eu/tei/', @xml:id, '.xml')"/>
            </xsl:variable>
            <xsl:variable name="mainurl">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $collection, '/', @xml:id, '/main')"/>
            </xsl:variable>
            <!--            main group of triples for one resource   -->
            <rdf:Description rdf:about="http://betamasaheft.eu/{@xml:id}">
                <!--                OPEN DATA LICENSE FOR THE RDF-->
                <dcterms:licence rdf:resource="http://opendatacommons.org/licenses/odbl/1.0/"/>
                <!--                general part, valid for all records -->
                <rdf:type rdf:resource="http://betamasaheft.eu/{@type}"/>
                <dcterms:source rdf:resource="{$xmluri}"/>
                <foaf:homepage rdf:resource="{$mainurl}"/>
                <crm:P48_has_preferred_identifier>
                    <xsl:value-of select="@xml:id"/>
                </crm:P48_has_preferred_identifier>
                <dc:publisher>
                    <xsl:value-of select="//t:publisher"/><xsl:text>,  </xsl:text><xsl:value-of select="//t:funder"/>
                </dc:publisher>
                <dcterms:isPartOf rdf:resource="http://betamasaheft.eu"/>
                <dcterms:bibliographicCitation><xsl:value-of select="@xml:id"/></dcterms:bibliographicCitation>
                <dc:format>xml</dc:format>
                <xsl:apply-templates select="//t:language"/>
                <xsl:apply-templates select="//t:editor"/>
                <xsl:apply-templates select="//t:keywords/t:term[@key]"/>
                <xsl:apply-templates select="//t:source/t:listBibl"/>

                <!--                specific parts in each main annotations group-->
                <xsl:if test="@type = 'mss'">
                    <rdf:type rdf:resource="http://lawd.info/ontology/AssembledWork"/>
                    <rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E18_Physical_Thing"/>
                    <rdf:type rdf:resource="http://pelagios.github.io/vocab/terms#AnnotatedThing"/>
<!--                    the present state of a mss is always a UniProd and a UniCirc-->
                    <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniProd"/>
                    <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniCirc"/>
                    <SdC:hasCertainty rdf:resource="https://w3id.org/sdc/ontology#certain"/>
                    <!--                    the physDesc can be BOTH at top level and in each msPart, it needs to be called here anyway, then also in each msPart if there is any-->
                    <xsl:apply-templates select="//t:msDesc/t:msIdentifier"/>
                    <xsl:apply-templates select="//t:msDesc/t:physDesc">
                        <xsl:with-param name="mainID">
                            <xsl:value-of select="$mainID"/>
                        </xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:choose>
                        <!--                        if the manuscript has parts, count them and add a pointer to them, a further call below will call the template in mode="parturis" producing the uris to which this will refer
                        if there are parts 
                        -->
                        <xsl:when test="//t:msDesc/t:msPart or //t:msDesc/t:msFrag">
                            <crm:P57_has_number_of_parts rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">
                                <xsl:value-of select="count(//t:msDesc/t:msPart) + count(//t:msDesc/t:msFrag)"/>
                            </crm:P57_has_number_of_parts>
                            <xsl:apply-templates select="//t:msDesc/t:msPart | //t:msDesc/t:msFrag">
                                <xsl:with-param name="mainID">
                                    <xsl:value-of select="$mainID"/>
                                </xsl:with-param>
                            </xsl:apply-templates>
                        </xsl:when>
                        <xsl:otherwise>
                            <!--                        if there are parts, there should be no msContent inside msDesc, if there are not parts, then contents are listed in msContents directly in msDesc-->
                            <xsl:if test="//t:msDesc/t:msContents/t:msItem">
                                <crm:P57_has_number_of_parts rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">
                                    <xsl:value-of select="count(//t:msDesc/t:msContents/t:msItem)"/>
                                </crm:P57_has_number_of_parts>
                                <xsl:apply-templates select="//t:msDesc/t:msContents/t:msItem">
                                    <xsl:with-param name="mainID">
                                        <xsl:value-of select="$mainID"/>
                                    </xsl:with-param>
                                </xsl:apply-templates>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="@type = 'work'">
                    <rdf:type rdf:resource="http://pelagios.github.io/vocab/terms#AnnotatedThing"/>
                    <rdf:type rdf:resource="http://lawd.info/ontology/ConceptualWork"/>
                    <rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E28_Conceptual_Object"/>
                    <xsl:apply-templates select="//t:listBibl[@type = 'clavis']"/>
                    <xsl:apply-templates select="//t:titleStmt/t:title">
                        <xsl:with-param name="mainID">
                            <xsl:value-of select="$mainID"/>
                        </xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="//t:witness"/>
                    <xsl:apply-templates select="//t:div[@type='edition']/t:div">
                        <xsl:with-param name="mainID">
                            <xsl:value-of select="$mainID"/>
                        </xsl:with-param>
                    </xsl:apply-templates>
                </xsl:if>
                <xsl:if test="@type = 'place' or @type = 'ins'">
                    <xsl:if test="@type = 'place'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E53_Place"/></xsl:if>
                    <xsl:if test="@type = 'ins'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E29_Actor"/></xsl:if>
                    <rdf:type rdf:resource="http://lawd.info/ontology/Place"/>
                    <xsl:if test="//t:location/t:geo">
                        <geo:location>
                            <rdf:Description>
                                <geo:lat>
                                    <xsl:value-of select="substring-before(//t:location/t:geo, ' ')"/>
                                </geo:lat>
                                <geo:long>
                                    <xsl:value-of select="substring-after(//t:location/t:geo, ' ')"/>
                                </geo:long>
                            </rdf:Description>
                        </geo:location>
                    </xsl:if>
                    <foaf:primaryTopicOf rdf:resource="{$mainurl}"/>
                    <xsl:if test="//t:place/@sameAs">
                        <skos:exactMatch rdf:resource="https://www.wikidata.org/entity/{//t:place/@sameAs}"/>
                    </xsl:if>
                    <xsl:if test="//t:place/@type">
                        <xsl:choose> <xsl:when test="matches(//t:place/@type, '\s')"><xsl:for-each select="tokenize(normalize-space(//t:place/@type), ' ')">
                            <pleiades:hasFeatureType rdf:resource="http://betamasaheft.eu/authority-files/{current()}"/>
                        </xsl:for-each></xsl:when>
                        <xsl:otherwise>
                            <pleiades:hasFeatureType rdf:resource="http://betamasaheft.eu/authority-files/{//t:place/@type}"/>
                        </xsl:otherwise></xsl:choose>
                    </xsl:if>
                    <xsl:apply-templates select="//t:state"/>
                    <xsl:apply-templates select="@type | @subtype"/>
                    <xsl:apply-templates select="//t:place/t:placeName" mode="pn"/>
                </xsl:if>
                <xsl:if test="@type = 'pers'">
                    <rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E29_Actor"/>
                    <rdf:type rdf:resource="http://lawd.info/ontology/Person"/>
                    <xsl:if test="//t:person/@sameAs">
                        <skos:exactMatch rdf:resource="https://www.wikidata.org/entity/{//t:person/@sameAs}"/>
                    </xsl:if>
                    <xsl:apply-templates select="@type | @subtype"/>
                    <xsl:apply-templates select="//t:person/t:persName" mode="pn"/>
                    <xsl:if test="//t:birth">
                          <xsl:apply-templates select="//t:birth"/>
                    </xsl:if>
                    <xsl:if test="//t:death">
                            <xsl:apply-templates select="//t:death"/>
                    </xsl:if>
                    <xsl:if test="//t:floruit">
                        <xsl:apply-templates select="//t:floruit"/>
                    </xsl:if>
                    <xsl:if test="//t:occupation">
                        <xsl:for-each select="//t:occupation">
                            <snap:occupation><xsl:value-of select="."/></snap:occupation>
                        </xsl:for-each>
                    </xsl:if>

                </xsl:if>
            </rdf:Description>

            <!--            independent annotations relating entities -->

            <!--            general -->
            <!--            for each relation in the TEI document, whereever it occurs it will print a RDF:Description with one property called by the @name of the relation 
            this does not need to pass on the main id as a parameter because that will be in attributed stated in the relation
            -->
            <xsl:apply-templates select="//t:relation">
<!--                <xsl:with-param name="ids"><xsl:value-of select="$ids"/></xsl:with-param>-->
            </xsl:apply-templates>


            <!--            for each placeName produces a OA:Annotation a la Pelagios this will all point to the main id
            /{$mainID}/annotation/{$position}
            -->
            <xsl:for-each select="//t:placeName[@ref]">
                <xsl:sort/>
                <xsl:call-template name="places">
                    <xsl:with-param name="mainID">
                        <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                    <xsl:with-param name="n">
                        <xsl:value-of select="position()"/>
                    </xsl:with-param>
                    <xsl:with-param name="passage">
                        <xsl:if test="ancestor::t:ab">
                            <xsl:if test="ancestor::t:*[@n][1]/ancestor::t:*[@n][name() != 'lb'][1]">
                                
                                <xsl:value-of select="string(ancestor::t:*[@n][name() != 'lb'][1]/ancestor::t:*[@n][name() != 'lb'][1]/@n)"/>
                                <xsl:text>.</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="string(ancestor::t:*[@n][name() != 'lb'][1]/@n)"/>
                        </xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="citation">
                        <xsl:choose>
                            <xsl:when test="//t:titleStmt/t:title[@type='short']">
                                <xsl:value-of select="//t:titleStmt/t:title[@type='short']"/>
                            </xsl:when>
                            
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="//t:titleStmt/t:title[@type='main']">
                                        <xsl:value-of select="//t:titleStmt/t:title[@type='main']"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="//t:titleStmt/t:title[@xml:id='t1']"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:for-each select="//t:persName[@ref[. != 'PRS00000']][not(parent::t:person)][not(ancestor::t:place)][not(ancestor::t:respStmt)]">
                
                <xsl:sort select="position()"/>
                <xsl:call-template name="persons">
                    <xsl:with-param name="mainID">
                        <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                    <xsl:with-param name="n">
                        <xsl:value-of select="position()"/>
                    </xsl:with-param>
                    <xsl:with-param name="passage">
                        <xsl:if test="ancestor::t:ab">
                            <xsl:if test="ancestor::t:*[@n][1]/ancestor::t:*[@n][name() != 'lb'][1]">
                                
                                <xsl:value-of select="string(ancestor::t:*[@n][name() != 'lb'][1]/ancestor::t:*[@n][name() != 'lb'][1]/@n)"/>
                                <xsl:text>.</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="string(ancestor::t:*[@n][name() != 'lb'][1]/@n)"/>
                        </xsl:if>
                    </xsl:with-param>
                    <xsl:with-param name="citation">
                        <xsl:choose>
                            <xsl:when test="//t:titleStmt/t:title[@type='short']">
                                <xsl:value-of select="//t:titleStmt/t:title[@type='short']"/>
                            </xsl:when>
                           
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="//t:titleStmt/t:title[@type='main']">
                                        <xsl:value-of select="//t:titleStmt/t:title[@type='main']"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                <xsl:value-of select="//t:titleStmt/t:title[@xml:id='t1']"/>
                            </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:for-each>

            <!--            entity type specific independent annotations with uris -->
            <xsl:if test="@type = 'mss'">
                <!--                only call templates for direct children of msDesc, for the children of msParts the template will create those uris-->
                <!--                additions all have a unique id, the uris can be thus created all here-->
                <xsl:apply-templates select="                     //t:msDesc/t:msPart |                      //t:msDesc/t:msFrag |                      //t:msDesc/t:msContents/t:msItem |                      //t:item[ancestor::t:additions] |                     //t:item[ancestor::t:collation] |                      //t:item[ancestor::t:foliation] |                      //t:handNote |                      //t:layout |                      //t:decoNote[ancestor::t:bindingDesc] |                      //t:decoNote[ancestor::t:decoDesc]" mode="parturis">
                    <xsl:with-param name="mainID">
                        <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            
            
                <!--            entity type specific independent annotations with uris -->
                <xsl:if test="@type = 'work'">
                    <!--                only call templates for direct children of div[edition]-->
                    <xsl:apply-templates select="//t:div[@type='edition']/t:div" mode="parturis">
                        <xsl:with-param name="mainID">
                            <xsl:value-of select="$mainID"/>
                        </xsl:with-param>
                    </xsl:apply-templates>
                

               
            </xsl:if>

        </rdf:RDF>
    </xsl:template>


    <xsl:template match="t:physDesc">
        <xsl:param name="mainID"/>
        <xsl:apply-templates select="preceding-sibling::t:msIdentifier"/>
        <xsl:apply-templates select="descendant::t:extent"/>
        <xsl:apply-templates select="descendant::t:objectDesc//t:material[@key]"/>
        <xsl:apply-templates select="descendant::t:objectDesc//t:objectType[@ref]"/>
        <xsl:apply-templates select="descendant::t:rs[@type='execution'][@ref]"/>
        <xsl:apply-templates select="descendant::t:objectDesc[@form]"/>
        <xsl:apply-templates select="descendant::t:origDate"/>
<!--        hands -->
        <xsl:apply-templates select="descendant::t:handDesc">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
<!--        layout -->
        <xsl:apply-templates select="descendant::t:layout">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
<!--        quires -->
        <xsl:apply-templates select="descendant::t:item[ancestor::t:collation]">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <!--        UniMarq -->
        <xsl:apply-templates select="descendant::t:item[ancestor::t:foliation]">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
<!--       text items -->
        <xsl:apply-templates select="descendant::t:msItem">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
        
        <!--       decorations -->
        <xsl:apply-templates select="descendant::t:decoNote[ancestor::t:decoDesc]">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
        
        <!--       binding -->
        <xsl:apply-templates select="descendant::t:decoNote[ancestor::t:bindingDesc]">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
<!--        additions -->
        <xsl:apply-templates select="descendant::t:item[ancestor::t:additions]">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="         t:msPart |          t:msFrag |          t:msItem |          t:colophon |         t:item[ancestor::t:additions] |          t:item[ancestor::t:collation] |          t:item[ancestor::t:foliation] |          t:handNote |          t:layout |          t:decoNote[ancestor::t:bindingDesc] |          t:decoNote[ancestor::t:decoDesc]  | t:div[ancestor::t:div[@type='edition']]">
        <xsl:param name="mainID"/>
        <xsl:variable name="type">
               <xsl:call-template name="URItype">
                   <xsl:with-param name="name"><xsl:value-of select="if(current()/parent::t:list/parent::t:additions) then 'ADD' else if (current()/parent::t:list/parent::t:collation) then 'COL' else if (current()/parent::t:list/parent::t:foliation) then 'FOL' else if (current()//parent::t:binding) then 'BIND' else ()"/><xsl:value-of select="name()"/></xsl:with-param>
                  </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="elemname" select="name()"/>
<xsl:variable name="id" select="if(@xml:id) then @xml:id else concat(name(), (count(preceding-sibling::t:*[name() = $elemname])+1))"/>
        <dcterms:hasPart>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/', $type, '/', $id)"/>
            </xsl:attribute>
        </dcterms:hasPart>

    </xsl:template>

    <xsl:template match="t:msPart | t:msFrag" mode="parturis">
        <xsl:param name="mainID"/>
        <xsl:variable name="type">
            <xsl:call-template name="URItype">
                <xsl:with-param name="name"><xsl:value-of select="name()"/></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <rdf:Description>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/', $type, '/', @xml:id)"/>
            </xsl:attribute>
            <rdf:type rdf:resource="http://betamasaheft.eu/{$type}"/>
            <!--            a msPart or  msFrag is so encoded because recognized as UniProd. Units it contains might decide wheather it is a UniProd-MC, UniProd-C, UniProd-C-MC, UniProd-M -->
            <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniProd"/>
            <SdC:hasCertainty rdf:resource="https://w3id.org/sdc/ontology#certain"/>
            <rdf:type rdf:resource="http://purl.org/saws/ontology#ManuscriptPart"/>
            <xsl:apply-templates select="t:physDesc">
                <xsl:with-param name="mainID">
                    <xsl:value-of select="$mainID"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:if test="t:msContents/t:msItem">
                <crm:P57_has_number_of_parts rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">
                    <xsl:value-of select="count(t:msContents/t:msItem)"/>
                </crm:P57_has_number_of_parts>
                <xsl:apply-templates select="t:msContents/t:msItem">
                    <xsl:with-param name="mainID">
                        <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:if test="t:msPart">
                <xsl:apply-templates select="t:msPart | t:msFrag">
                    <xsl:with-param name="mainID">
                        <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
            <xsl:apply-templates select="t:locus"/>
            <xsl:apply-templates select="t:listBibl"/>
            <xsl:apply-templates select="descendant::t:term[@key]"/>
        </rdf:Description>
        <xsl:apply-templates select="t:msPart | t:msFrag" mode="parturis">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:apply-templates select="t:msContents/t:msItem" mode="parturis">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="t:colophon" mode="parturis">
        <xsl:param name="mainID"/>
        <rdf:Description>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/colophon/', @xml:id)"/>
            </xsl:attribute>
            <rdf:type rdf:resource="http://betamasaheft.eu/colophon"/>
            <xsl:apply-templates select="t:locus"/>
            <xsl:apply-templates select="t:listBibl"/>
            <xsl:apply-templates select="descendant::t:date"/>
            <xsl:apply-templates select="descendant::t:persName[@ref]"/>
            <xsl:apply-templates select="descendant::t:ref[@type]"/>
            <xsl:apply-templates select="descendant::t:term[@key]"/>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="t:msItem" mode="parturis">
        <xsl:param name="mainID"/>
        <rdf:Description>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/msitem/', @xml:id)"/>
            </xsl:attribute>
            <rdf:type rdf:resource="http://betamasaheft.eu/msitem"/>
            <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniCont"/>
            <xsl:if test="t:title[@xml:lang]">
                <dc:language>
                    <xsl:value-of select="t:title/@xml:lang"/>
                </dc:language>
            </xsl:if>
            <dcterms:hasPart>
                <xsl:choose>
                    <xsl:when test="t:title[@ref]">
                        <xsl:attribute name="rdf:resource">
                            <xsl:value-of select="concat('http://betamasaheft.eu/', t:title/@ref)"/>
                        </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="t:title"/>
                    </xsl:otherwise>
                </xsl:choose>
            </dcterms:hasPart>
            <crm:P57_has_number_of_parts rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">
                <xsl:value-of select="count(t:msItem)"/>
            </crm:P57_has_number_of_parts>
            <xsl:apply-templates select="t:msItem | t:colophon">
                <xsl:with-param name="mainID">
                    <xsl:value-of select="$mainID"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:locus"/>
            <xsl:apply-templates select="t:listBibl"/>
            <xsl:apply-templates select="descendant::t:date"/>
            <xsl:apply-templates select="descendant::t:persName[@ref]"/>
            <xsl:apply-templates select="descendant::t:ref[@type]"/>
            <xsl:apply-templates select="descendant::t:term[@key]"/>
        </rdf:Description>
        <xsl:apply-templates select="t:msItem | t:colophon" mode="parturis">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>


    <xsl:template match="t:item[ancestor::t:additions]" mode="parturis">
        <xsl:param name="mainID"/>
        <rdf:Description>
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/addition/', @xml:id)"/>
            </xsl:attribute>
            
            <rdf:type rdf:resource="http://betamasaheft.eu/addition"/>
            <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniCont"/>
            <xsl:if test="t:desc[@type]">
                <rdf:type rdf:resource="http://betamasaheft.eu/{t:desc/@type}"/>
            </xsl:if>
            <xsl:if test="t:q[@xml:lang]">
                <dc:language>
                    <xsl:value-of select="t:title/@xml:lang"/>
                </dc:language>
            </xsl:if>
            <xsl:apply-templates select="descendant::t:date"/>
            <xsl:apply-templates select="descendant::t:persName[@ref]"/>
            <xsl:apply-templates select="descendant::t:ref[@type]"/>
            <xsl:apply-templates select="t:locus"/> 
            <xsl:apply-templates select="@corresp">
                <xsl:with-param name="mainID">
                    <xsl:value-of select="$mainID"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:listBibl"/>
            <xsl:apply-templates select="descendant::t:term[@key]"/>
        </rdf:Description>
    </xsl:template>

    <xsl:template match="     t:div[ancestor::t:div[@type='edition']]  |   t:item[ancestor::t:collation] |          t:item[ancestor::t:foliation] |          t:handNote |          t:layout |          t:decoNote[ancestor::t:bindingDesc] |          t:decoNote[ancestor::t:decoDesc]" mode="parturis">
        <xsl:param name="mainID"/>
        <xsl:variable name="type">
            <xsl:call-template name="URItype">
                <xsl:with-param name="name"><xsl:value-of select="if(current()/parent::t:list/parent::t:additions) then 'ADD' else if (current()/parent::t:list/parent::t:collation) then 'COL' else if (current()/parent::t:list/parent::t:foliation) then 'FOL' else if (current()//ancestor::t:binding) then 'BIND' else ()"/><xsl:value-of select="name()"/></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <rdf:Description>
            <xsl:variable name="elemname" select="name()"/>
            <xsl:variable name="id" select="if(@xml:id) then @xml:id else concat(name(), (count(preceding-sibling::t:*[name() = $elemname])+1))"/>
            
            <xsl:attribute name="rdf:about">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/', $type, '/', $id)"/>
            </xsl:attribute>
            <dcterms:isPartOf rdf:resource="{concat('http://betamasaheft.eu/', $mainID)}"/>
            <rdf:type rdf:resource="http://betamasaheft.eu/{$type}"/>
            <xsl:apply-templates select="descendant::t:date"/>
            <xsl:apply-templates select="descendant::t:persName[@ref]"/>
            <xsl:apply-templates select="descendant::t:title[@ref]" mode="rel"/>
            <xsl:apply-templates select="descendant::t:ref[@type]"/>
            <xsl:apply-templates select="t:locus"/>
            <xsl:if test="t:ab[@type='ruling']">
<!--                for a different ruling there should be a different layout, so in case the layout contains ruling information in a ab[@type="ruling"], it is **also** a UniRégl -->
                <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniRegl"/>
            </xsl:if>
            <xsl:if test="$type = 'layout'">
<!--                a layout note will always be also a UniMeP. The encoder will have for visible distinctions have encoded different layout elements-->
                <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniMeP"/>
                
                <xsl:apply-templates select="descendant::t:objectDesc//t:rs[@type='execution']"/>
            </xsl:if>
            <xsl:if test="$type = 'hand'">
                <!--                a handNote will always be also a UniMain. The encoder will have for visible distinctions have encoded different handNote elements
                Here although also for a different UniEcri there would be in the TEI a handNote... which practically kills the UniEcri
                -->
                <rdf:type rdf:resource="https://w3id.org/sdc/ontology#UniMain"/>
            </xsl:if>
            <xsl:if test="$type='binding'">
                <xsl:apply-templates select="t:material"/>
            </xsl:if>
            <xsl:if test="$type='hand' and @script">
                <rdf:type rdf:resource="http://betamasaheft.eu/{@script}"/>
            </xsl:if>
            <xsl:if test="name()='decoNote' and @type">
                <rdf:type rdf:resource="http://betamasaheft.eu/{@type}"/>
            </xsl:if>
            <xsl:if test="$type = 'quire'">
                <crm:P43_has_dimension>
                    <crm:E54_Dimension>
                        <crm:P90_has_value>
                    <xsl:value-of select="t:dim[@unit]"/>
                        </crm:P90_has_value>
                        <crm:P91_has_unit>
                            <xsl:value-of select="t:dim/@unit"/>
                        </crm:P91_has_unit>
                    </crm:E54_Dimension>
                </crm:P43_has_dimension>
            </xsl:if>
            <xsl:apply-templates select="@corresp">
                <xsl:with-param name="mainID">
                    <xsl:value-of select="$mainID"/>
                </xsl:with-param>
            </xsl:apply-templates>
            <xsl:apply-templates select="t:listBibl"/>
            <xsl:apply-templates select="descendant::t:term[@key]"/>
            <!--        in case div has got subdivs, then loop again, adding part-->
            <xsl:apply-templates select="t:div">
                <xsl:with-param name="mainID">
                    <xsl:value-of select="$mainID"/>
                </xsl:with-param>
            </xsl:apply-templates>
        </rdf:Description>
<!--        in case div has got subdivs, then loop again-->
        
        <xsl:apply-templates select="t:div" mode="parturis">
            <xsl:with-param name="mainID">
                <xsl:value-of select="$mainID"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="@corresp">
        <xsl:param name="mainID"/>
       <xsl:choose>
           <xsl:when test="contains(., ' ')">
               <xsl:variable name="node" select="."/>
               <xsl:for-each select="tokenize(.,' ')">
                   <xsl:choose>
                       <xsl:when test="starts-with(.,'#')">
<!--                           <xsl:message>using corresp template for <xsl:value-of select="."/></xsl:message>-->
                           <!--                it is an internal pointer-->
                           <xsl:variable name="corr" select="substring-after(., '#')"/>
                           <xsl:variable name="matchingElement" select="$node/ancestor::t:TEI//t:*[@xml:id = $corr]"/>
<!--                           <xsl:message><xsl:copy-of select="$matchingElement"/></xsl:message>-->
                           <xsl:variable name="type">
                               <xsl:call-template name="URItype">
                                   <xsl:with-param name="name"><xsl:value-of select="if($matchingElement/parent::t:list/parent::t:additions) then 'ADD' else if ($matchingElement/parent::t:list/parent::t:collation) then 'COL' else if ($matchingElement/parent::t:list/parent::t:foliation) then 'FOL' else if ($matchingElement//ancestor::t:binding) then 'BIND' else ()"/><xsl:value-of select="$matchingElement/name()"/></xsl:with-param>
                               </xsl:call-template>
                           </xsl:variable>
<!--                           <xsl:message><xsl:value-of select="$type"/></xsl:message>-->
                           <dc:relation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/', $type, '/', $corr)"/></xsl:attribute></dc:relation>
                       </xsl:when>
                       <xsl:otherwise>
                           <!--                it should point to another entity-->
                           <dc:relation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/', .)"/></xsl:attribute></dc:relation>
                       </xsl:otherwise>
                   </xsl:choose>
               </xsl:for-each>
           </xsl:when>
           <xsl:otherwise>
           <xsl:choose>
            <xsl:when test="starts-with(.,'#')">
<!--                <xsl:message>using corresp template for <xsl:value-of select="."/></xsl:message>-->
<!--                it is an internal pointer-->
        <xsl:variable name="corr" select="substring-after(., '#')"/>
        <xsl:variable name="matchingElement" select="current()/ancestor::t:TEI//t:*[@xml:id = $corr]"/>
<!--                <xsl:message><xsl:copy-of select="$matchingElement"/></xsl:message>-->
        <xsl:variable name="type">
            <xsl:call-template name="URItype">
                <xsl:with-param name="name"><xsl:value-of select="if($matchingElement//ancestor::t:additions) then 'ADD' else if ($matchingElement//ancestor::t:collation) then 'COL' else if ($matchingElement//ancestor::t:foliation) then 'FOL' else if ($matchingElement//ancestor::t:binding) then 'BIND' else ()"/><xsl:value-of select="$matchingElement/name()"/></xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
<!--                <xsl:message><xsl:value-of select="$type"/></xsl:message>-->
                <dc:relation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/', $mainID, '/', $type, '/', $corr)"/></xsl:attribute></dc:relation>
            </xsl:when>
            <xsl:otherwise>
<!--                it should point to another entity-->
                <dc:relation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/', .)"/></xsl:attribute></dc:relation>
            </xsl:otherwise>
        </xsl:choose>
           </xsl:otherwise>
       </xsl:choose>
    </xsl:template>
    
    <xsl:template name="URItype">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="$name = 'msPart'">mspart</xsl:when>
            <xsl:when test="$name = 'div'">part</xsl:when>
            <xsl:when test="$name = 'msFrag'">msfrag</xsl:when>
            <xsl:when test="$name = 'msItem'">msitem</xsl:when>
            <xsl:when test="$name = 'colophon'">colophon</xsl:when>
            <xsl:when test="$name = 'item'">addition</xsl:when>
            <xsl:when test="$name = 'ADDitem' ">addition</xsl:when>
            <xsl:when test="$name = 'COLitem' ">quire</xsl:when>
            <xsl:when test="$name = 'FOLitem' ">UniMarq</xsl:when>
            <xsl:when test="$name = 'msItem'">msitem</xsl:when>
            <xsl:when test="$name = 'handNote'">hand</xsl:when>
            <xsl:when test="$name = 'layout'">layout</xsl:when>
            <xsl:when test="$name = 'decoNote' ">decoration</xsl:when>
            <xsl:when test="$name = 'BINDdecoNote' ">binding</xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:locus">
<!--        to preserve EACH distinct locus, because there might be texts where an encoding is made as 
        from <locus> to <locus> is given, to provide also lines, for example-->
        <bm:hasLocus>
            <bm:Locus>
        <xsl:if test="@from">
            <bm:locusFrom>
                <xsl:value-of select="@from"/>
            </bm:locusFrom>
        </xsl:if>
        <xsl:if test="@to">
            <bm:locusTo>
                <xsl:value-of select="@to"/>
            </bm:locusTo>
        </xsl:if>
        <xsl:if test="@target">
            <xsl:choose>
                <xsl:when test="contains(@target, ' ')">
                    <xsl:for-each select="tokenize(@target, ' ')">
                        <bm:locusTarget>
                            <xsl:value-of select="substring-after(., '#')"/>
                        </bm:locusTarget>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <bm:locusTarget>
                        <xsl:value-of select="substring-after(@target, '#')"/>
                    </bm:locusTarget>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:if>
        <xsl:if test="@n">
            <bm:locusLine>
                <xsl:value-of select="@n"/>
            </bm:locusLine>
        </xsl:if>
        </bm:Locus>
        </bm:hasLocus>
    </xsl:template>

<xsl:template match="t:extent">
    <bm:hasTotalLeaves><xsl:value-of select="t:measure[@unit='leaf']"/></bm:hasTotalLeaves>
    <xsl:apply-templates select="t:dimensions"/>
    <xsl:apply-templates select="t:locus"/>
</xsl:template>
    
    <xsl:template match="t:dimensions">
        <xsl:variable name="unit" select="@unit"/>
        <xsl:for-each select="child::t:*">
        <crm:P43_has_dimension>
        <crm:E54_Dimension>
            <crm:P2_has_type><xsl:value-of select="name()"/></crm:P2_has_type>
            <crm:P90_has_value><xsl:value-of select="."/></crm:P90_has_value>
            <crm:P91_has_unit><xsl:value-of select="if(@unit) then @unit else $unit"/></crm:P91_has_unit>
        </crm:E54_Dimension>
    </crm:P43_has_dimension>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="newResource">
        <xsl:param name="thisid"/>
        <xsl:variable name="candidatenewsubid" select="substring-after($thisid, '#')"/>
        <xsl:if test="starts-with($candidatenewsubid, 'Uni') or starts-with($candidatenewsubid, 'tr')">
                <rdf:type>
                    <xsl:attribute name="rdf:resource">
                        <xsl:variable name="SdC">
                            <xsl:choose>
                                <xsl:when test="starts-with($candidatenewsubid, 'tr')">Transformation</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniCirc')">UniCirc</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniProd')">UniProd</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniMat')">UniMat</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniMeP')">UniMeP</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniRegl')">UniRegl</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniEcri')">UniEcri</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniMain')">UniMain</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniMarq')">UniMarq</xsl:when>
<!--                                the collation lists each quire, but the UniCah is made of several, so this can only be considered as Elements-->
                                <xsl:when test="starts-with($candidatenewsubid, 'UniCah')">ElCah</xsl:when>
                                <xsl:when test="starts-with($candidatenewsubid, 'UniCont')">UniCont</xsl:when>
                                <xsl:otherwise>part</xsl:otherwise>
                            </xsl:choose></xsl:variable>
                        <xsl:value-of select="concat('https://w3id.org/sdc/ontology#', $SdC)"/>
                    </xsl:attribute>
                </rdf:type>
        </xsl:if>
        <xsl:if test="starts-with($candidatenewsubid, 'http')">
            <rdf:type>
                <xsl:attribute name="rdf:resource"><xsl:value-of select="$candidatenewsubid"/></xsl:attribute>
            </rdf:type>
        </xsl:if>
        <xsl:if test="starts-with($candidatenewsubid, 'tr')">
            <rdf:type>
                <xsl:attribute name="rdf:resource">http://www.cidoc-crm.org/cidoc-crm/E11_Modification</xsl:attribute>
            </rdf:type>
        </xsl:if>
        <xsl:if test="starts-with($candidatenewsubid, 'UniCirc') or starts-with($candidatenewsubid, 'UniProd')">
            <rdf:type>
                <xsl:attribute name="rdf:resource">http://www.cidoc-crm.org/cidoc-crm/E18_Physical_Thing</xsl:attribute>
            </rdf:type>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:relation[@active][@passive]">
        <xsl:variable name="a" select="@active"/>
        <xsl:variable name="about">
            <xsl:value-of select="funct:id($a)"/>
        </xsl:variable>
        <xsl:variable name="n" select="@name"/>
        <xsl:choose>
            <xsl:when test="contains(@passive, ' ')">
                <rdf:Description rdf:about="{$about}"> 
                    <xsl:if test="contains($a, '#')">
                    <xsl:call-template name="newResource">
                        <xsl:with-param name="thisid"><xsl:value-of select="$a"/></xsl:with-param>
                    </xsl:call-template>    
                    </xsl:if>
                    <xsl:for-each select="tokenize(normalize-space(@passive), ' ')">
                    
                    <xsl:variable name="resource">
                        <xsl:value-of select="funct:id(.)"/>
                    </xsl:variable>
                    
                       <xsl:choose>
                           <xsl:when test="starts-with($n, 'snap:')">
                               <snap:hasBond rdf:resource="http://betamasaheft.eu/bond/{$n}-{.}"/>
                           </xsl:when>
                           <xsl:otherwise>
                               <xsl:element name="{$n}">
                                   <xsl:attribute name="rdf:resource">
                                       <xsl:value-of select="$resource"/>
                                   </xsl:attribute>
                               </xsl:element>
                           </xsl:otherwise>
                       </xsl:choose>
                       
                    
                </xsl:for-each>
                </rdf:Description>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:variable name="resource">
                    <xsl:value-of select="funct:id(@passive)"/>
                </xsl:variable>

                <rdf:Description rdf:about="{$about}">
                    <xsl:if test="contains($a, '#')">
                    <xsl:call-template name="newResource">
                        <xsl:with-param name="thisid"><xsl:value-of select="$a"/></xsl:with-param>
                    </xsl:call-template>    
                </xsl:if>
                    <xsl:choose>
                        <xsl:when test="starts-with($n, 'snap:')">
                            <snap:hasBond rdf:resource="http://betamasaheft.eu/bond/{$n}-{@passive}"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:element name="{$n}">
                                <xsl:attribute name="rdf:resource">
                                    <xsl:value-of select="$resource"/>
                                </xsl:attribute>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates select="t:desc"/>
                </rdf:Description>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="starts-with($n, 'snap:')">
            <xsl:variable name="resource">
            <xsl:value-of select="funct:id(@passive)"/>
        </xsl:variable>
            <rdf:Description rdf:about="http://betamasaheft.eu/bond/{$n}-{@passive}">
                <rdf:type rdf:resource="{replace($n, 'snap:', 'http://data.snapdrgn.net/ontology/snap#')}"/>
                <snap:bond-with>
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="$resource"/>
                    </xsl:attribute>
                </snap:bond-with>
            </rdf:Description>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:desc">
        <xsl:apply-templates select="t:locus"/>
        <xsl:apply-templates select="t:locus"/>
    </xsl:template>

    <xsl:template match="t:listBibl[@type = 'clavis']">
        <xsl:for-each select="t:bibl[@type][t:citedRange/text()]">
            <crm:P1_is_identified_by>
                <xsl:value-of select="concat(@type, ' ', t:citedRange/text())"/>
            </crm:P1_is_identified_by>
        </xsl:for-each>
    </xsl:template>
    
    
    <xsl:template match="t:listBibl[not(@type = 'clavis')]">
         <xsl:for-each select="t:bibl[t:ptr[@target]][t:citedRange/text()]">
             <dcterms:bibliographicCitation>
                 <xsl:value-of select="./t:ptr/@target"/>
             </dcterms:bibliographicCitation>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="t:msIdentifier">
        <crm:P1_is_identified_by>
            <xsl:value-of select="t:idno"/>
        </crm:P1_is_identified_by>
        <xsl:for-each select="t:altIdentifier">
            <crm:P1_is_identified_by>
                <xsl:value-of select="./t:idno"/>
            </crm:P1_is_identified_by>
        </xsl:for-each>
        <xsl:apply-templates select="t:repository"/>
    </xsl:template>

    <xsl:template match="t:material">
        <xsl:if test="@ref">
            <crm:P46_is_composed_of>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="@ref"/>
            </xsl:attribute>
        </crm:P46_is_composed_of>
        </xsl:if>
        <crm:P46_is_composed_of>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/vocabularies/material.html#',@key)"/>
            </xsl:attribute>
        </crm:P46_is_composed_of>
    </xsl:template>

    <xsl:template match="t:objectDesc">
        <rdf:type rdf:resource="http://betamasaheft.eu/{@form}"/>
    </xsl:template>

    <xsl:template match="t:objectType">
        <crm:P2_has_type rdf:resource="{@ref}"/>
    </xsl:template>
    
    <xsl:template match="t:rs[@type='execution']">
        <crm:P32_used_general_technique rdf:resource="{@ref}"/>
    </xsl:template>

    <xsl:template match="@type | @subtype">
        <rdf:type rdf:resource="http://betamasaheft.eu/{.}"/>
    </xsl:template>

    <xsl:template match="t:state[@type='existence']">
        <xsl:choose>
            <xsl:when test="@ref= 'Aks'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03wskd389m"/>
            </xsl:when>
            <xsl:when test="@ref = 'Paks1'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssrjvk"/>
            </xsl:when>
            <xsl:when test="@ref = 'Paks2'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvm7f"/>
            </xsl:when>
            <xsl:when test="@ref = 'Gon'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssdh3k"/>
            </xsl:when>
            <xsl:when test="@ref = 'ZaMa'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvtwm"/>
            </xsl:when>
            <xsl:when test="@ref = 'MoPe'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssfc3r"/>
            </xsl:when>
            <xsl:otherwise>
                <rdf:type rdf:resource="http://betamasaheft.eu/{@key}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="t:term">
        <xsl:choose>
            <xsl:when test="@key = 'Aks'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03wskd389m"/>
            </xsl:when>
            <xsl:when test="@key = 'Paks1'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssrjvk"/>
            </xsl:when>
            <xsl:when test="@key = 'Paks2'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvm7f"/>
            </xsl:when>
            <xsl:when test="@key = 'Gon'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssdh3k"/>
            </xsl:when>
            <xsl:when test="@key = 'ZaMa'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvtwm"/>
            </xsl:when>
            <xsl:when test="@key = 'MoPe'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssfc3r"/>
            </xsl:when>
            <xsl:when test="@ref">
                <crm:P103_was_intended_for rdf:resource="{@ref}"/>
            </xsl:when>
            <xsl:otherwise>
                <rdf:type rdf:resource="http://betamasaheft.eu/{@key}"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="t:ref[@type]">
        <dc:relation rdf:resource="http://betamasaheft.eu/{@corresp}"/>
    </xsl:template>

    <xsl:template match="t:language">
        <dc:language rdf:datatype="http://www.w3.org/2001/XMLSchema#language">
            <xsl:value-of select="@ident"/>
        </dc:language>
    </xsl:template>

    <xsl:template match="t:date | t:origDate | t:floruit | t:birth | t:death">
        <crm:P4_has_time_span>
            <xsl:choose>
                <xsl:when test="@when">
                    <crm:E52_Time-span>
                        <xsl:choose>
                            <xsl:when test="name() = 'birth'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E67_Birth"/></xsl:when>
                            <xsl:when test="name() = 'death'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E69_Death"/></xsl:when>
                        </xsl:choose>
                        <crm:P79_beginning_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                            <xsl:value-of select="funct:date(@when)"/>
                        </crm:P79_beginning_is_qualified_by>
                        <crm:P80_end_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                            <xsl:value-of select="funct:date(@when)"/>
                        </crm:P80_end_is_qualified_by>
                    </crm:E52_Time-span>
                </xsl:when>
                <xsl:when test="@notBefore or @notAfter">
                    <crm:E52_Time-span>
                        <xsl:choose>
                        <xsl:when test="name() = 'birth'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E67_Birth"/></xsl:when>
                        <xsl:when test="name() = 'death'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E69_Death"/></xsl:when>
                    </xsl:choose>
                        <xsl:if test="@notBefore">
                            <crm:P79_beginning_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                                <xsl:value-of select="funct:date(@notBefore)"/>
                            </crm:P79_beginning_is_qualified_by>
                        </xsl:if>
                        <xsl:if test="@notAfter">
                            <crm:P80_end_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                                <xsl:value-of select="funct:date(@notAfter)"/>
                            </crm:P80_end_is_qualified_by>
                        </xsl:if>
                    </crm:E52_Time-span>
                </xsl:when>
                <xsl:otherwise>
                    <crm:E52_Time-span>
                        <xsl:choose>
                        <xsl:when test="name() = 'birth'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E67_Birth"/></xsl:when>
                        <xsl:when test="name() = 'death'"><rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E69_Death"/></xsl:when>
                    </xsl:choose>
                        <crm:P78_is_identified_by>
                            <xsl:value-of select="."/>
                        </crm:P78_is_identified_by>
                    </crm:E52_Time-span>
                </xsl:otherwise>
            </xsl:choose>

        </crm:P4_has_time_span>
    </xsl:template>


    <xsl:template match="t:title">
        <xsl:param name="mainID"/>
        <dc:title>
            <xsl:if test="@xml:lang">
                <xsl:copy-of select="@xml:lang"/>
            </xsl:if>
            <xsl:value-of select="."/>
        </dc:title>
        <xsl:if test="@xml:id">
            <crm:P102_has_title rdf:resource="{funct:id(concat($mainID, '#',@xml:id))}">
            <xsl:if test="@xml:lang">
                <xsl:copy-of select="@xml:lang"/>
            </xsl:if>
            </crm:P102_has_title>
        </xsl:if>
    </xsl:template>

    <xsl:template match="t:placeName" mode="pn">
        <lawd:hasName>
            <rdf:Description>
                <xsl:choose>
                    <xsl:when test="@xml:id = 'n1'">
                        <lawd:variantForm>
                            <xsl:value-of select="."/>
                        </lawd:variantForm>
                    </xsl:when>
                    <xsl:otherwise>
                        <lawd:primaryForm>
                            <xsl:value-of select="."/>
                        </lawd:primaryForm>
                    </xsl:otherwise>
                </xsl:choose>
            </rdf:Description>
        </lawd:hasName>
    </xsl:template>

    <xsl:template match="t:repository">
        <crm:P55_has_current_location>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/', @ref)"/>
            </xsl:attribute>
        </crm:P55_has_current_location>
    </xsl:template>

    <xsl:template match="t:persName" mode="pn">
        <foaf:name>
            <xsl:copy-of select="@xml:lang"/>
            <xsl:value-of select="."/>
        </foaf:name>
    </xsl:template>

    <xsl:template match="t:witness">
        <dc:source>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="funct:id(@corresp)"/>
            </xsl:attribute>
        </dc:source>
    </xsl:template>

    <xsl:template name="places">
        <xsl:param name="mainID"/>
        <xsl:param name="n"/>
        <xsl:param name="passage"/>
        <xsl:param name="citation"/>
        <oa:Annotation rdf:about="http://betamasaheft.eu/{$mainID}/place/annotation/{$n}">
            <oa:hasTarget rdf:resource="http://betamasaheft.eu/{$mainID}"/>
            <oa:hasBody rdf:resource="{if(starts-with(@ref, 'pleiades:')) then concat('https://pleiades.stoa.org/places/', substring-after(@ref, 'pleiades:')) else if (starts-with(@ref, 'Q')) then concat('https://www.wikidata.org/entity/', @ref) else concat('http://betamasaheft.eu/',@ref)}"/>
            <oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="current-date()"/>
            </oa:annotatedAt>
            <xsl:if test="$passage != ' ' and $citation != ''">
                <lawd:hasAttestation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/api/dts/document?id=urn:dts:betmas:',$mainID,':',$passage)"/></xsl:attribute></lawd:hasAttestation>
            <lawd:hasCitation><xsl:value-of select="$citation"/><xsl:text> </xsl:text><xsl:value-of select="$passage"/></lawd:hasCitation>
            </xsl:if>
            <xsl:if test="normalize-space(string-join(text(), '')) != ''"><lawd:hasName><xsl:value-of select="normalize-space(string-join(text(), ' '))"/></lawd:hasName></xsl:if>
            
        </oa:Annotation>
    </xsl:template>

    <xsl:template name="persons">
        <xsl:param name="mainID"/>
        <xsl:param name="n"/>
        <xsl:param name="passage"/>
        <xsl:param name="citation"/>
        <oa:Annotation rdf:about="http://betamasaheft.eu/{$mainID}/person/annotation/{$n}">
            <xsl:if test="@type"><rdf:type rdf:resource="http://betamasaheft.eu/{@type}"/></xsl:if>
            <xsl:if test="@role"><rdf:type rdf:resource="http://betamasaheft.eu/{@role}"/></xsl:if>
            <oa:hasTarget rdf:resource="http://betamasaheft.eu/{$mainID}"/>
            <oa:hasBody rdf:resource="{if(starts-with(@ref, 'pleiades:')) then concat('https://pleiades.stoa.org/places/', substring-after(@ref, 'pleiades:')) else if (starts-with(@ref, 'Q')) then concat('https://www.wikidata.org/entity/', @ref) else concat('http://betamasaheft.eu/',@ref)}"/>
            <oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="current-date()"/>
            </oa:annotatedAt>
            <xsl:if test="$passage != ' ' and $citation != ''"><lawd:hasAttestation><xsl:attribute name="rdf:resource"><xsl:value-of select="concat('http://betamasaheft.eu/api/dts/document?id=urn:dts:betmas:',$mainID,':',$passage)"/></xsl:attribute></lawd:hasAttestation>
            <lawd:hasCitation><xsl:value-of select="$citation"/><xsl:text> </xsl:text><xsl:value-of select="$passage"/></lawd:hasCitation>
            </xsl:if><xsl:if test="t:roleName">
                <xsl:for-each select="t:roleName">
                    <bm:hasRole>
                        <bm:Role>
                            <bm:roleType rdf:resource="http://betamasaheft.eu/role/{@type}"/>
                            <bm:roleName><xsl:value-of select="."/></bm:roleName>
                        </bm:Role>
                    </bm:hasRole>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="normalize-space(string-join(text(), '')) != ''"><lawd:hasName><xsl:value-of select="normalize-space(string-join(text(), ' '))"/></lawd:hasName></xsl:if>
        </oa:Annotation>
    </xsl:template>

    <xsl:template match="t:persName">
        <dc:relation>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/', @ref)"/>
            </xsl:attribute>
        </dc:relation>
    </xsl:template>
    
    <xsl:template match="t:title" mode="rel">
        <dc:relation>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/', @ref)"/>
            </xsl:attribute>
        </dc:relation>
    </xsl:template>

    <xsl:template match="t:editor">
        <dc:contributor>
            <xsl:call-template name="editorKey">
                <xsl:with-param name="k">
                    <xsl:value-of select="@key"/>
                </xsl:with-param>
            </xsl:call-template>
        </dc:contributor>
    </xsl:template>

    <xsl:template name="editorKey">
        <xsl:param name="k"/>
        <xsl:choose>
            <xsl:when test="$k = 'AB'">Alessandro Bausi</xsl:when>
            <xsl:when test="$k = 'ES'">Eugenia Sokolinski</xsl:when>
            <xsl:when test="$k = 'DN'">Denis Nosnitsin</xsl:when>
            <xsl:when test="$k = 'MV'">Massimo Villa</xsl:when>
            <xsl:when test="$k = 'DR'">Dorothea Reule</xsl:when>
            <xsl:when test="$k = 'SG'">Solomon Gebreyes</xsl:when>
            <xsl:when test="$k = 'PL'">Pietro Maria Liuzzo</xsl:when>
            <xsl:when test="$k = 'SA'">Stéphane Ancel</xsl:when>
            <xsl:when test="$k = 'SD'">Sophia Dege</xsl:when>
            <xsl:when test="$k = 'VP'">Vitagrazia Pisani</xsl:when>
            <xsl:when test="$k = 'IF'">Iosif Fridman</xsl:when>
            <xsl:when test="$k = 'SH'">Susanne Hummel</xsl:when>
            <xsl:when test="$k = 'FP'">Francesca Panini</xsl:when>
            <xsl:when test="$k = 'AA'">Abreham Adugna</xsl:when>
            <xsl:when test="$k = 'EG'">Ekaterina Gusarova</xsl:when>
            <xsl:when test="$k = 'IR'">Irene Roticiani</xsl:when>
            <xsl:when test="$k = 'MB'">Maria Bulakh</xsl:when>
            <xsl:when test="$k = 'VR'">Veronika Roth</xsl:when>
            <xsl:when test="$k = 'MK'">Magdalena Krzyzanowska</xsl:when>
            <xsl:when test="$k = 'DE'">Daria Elagina</xsl:when>
            <xsl:when test="$k = 'NV'">Nafisa Valieva</xsl:when>
            <xsl:when test="$k = 'RHC'">Ran HaCohen</xsl:when>
            <xsl:when test="$k = 'SS'">Sisay Sahile</xsl:when>
            <xsl:when test="$k = 'SJ'">Sibylla Jenner</xsl:when>
            <xsl:when test="$k = 'JG'">Jacopo Gnisci</xsl:when>
            <xsl:when test="$k = 'MP'">Michele Petrone</xsl:when>
            <xsl:when test="$k = 'SF'">Sara Fani</xsl:when>
            <xsl:when test="$k = 'IP'">Irmeli Perho</xsl:when>
            <xsl:when test="$k = 'RBO'">Rasmus Bech Olsen</xsl:when>
            <xsl:when test="$k = 'AR'">Anne Regourd</xsl:when>
            <xsl:when test="$k = 'AH'">Adday Hernández</xsl:when>
            <xsl:when test="$k = 'JS'">Joshua Sabih</xsl:when>
            <xsl:when test="$k = 'AW'">Andreas Wetter</xsl:when>
            <xsl:when test="$k = 'JML'">John Møller Larsen</xsl:when>
            <xsl:when test="$k = 'AG'">Alessandro Gori</xsl:when>
            <xsl:when test="$k = 'JK'">Jonas Karlsson</xsl:when>
            <xsl:when test="$k = 'EDS'">Eliana Dal Sasso</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>