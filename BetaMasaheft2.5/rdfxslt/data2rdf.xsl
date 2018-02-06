<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:pleiades="https://pleiades.stoa.org/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:agrelon="http://d-nb.info/standards/elementset/agrelon.owl#" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:bm="http://betamasaheft.eu/docs.html#" xmlns:wd="https://www.wikidata.org/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:lawd="http://lawd.info/ontology/" xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#" xmlns:oa="http://www.w3.org/ns/oa#" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ecrm="http://erlangen-crm.org/current/" xmlns:rel="http://purl.org/vocab/relationship/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:pelagios="http://pelagios.github.io/vocab/terms#" xmlns:syriaca="http://syriaca.org/documentation/relations.html#" xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" xmlns:saws="http://purl.org/saws/ontology#" xmlns:snap="http://data.snapdrgn.net/ontology/snap#" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
<!--
    <xsl:template match="t:classDecl">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:lawd="http://lawd.info/ontology/" xmlns:oa="http://www.w3.org/ns/oa#"
            xmlns:gn="http://www.geonames.org/ontology#"
            xmlns:agrelon="http://d-nb.info/standards/elementset/agrelon.owl#"
            xmlns:rel="http://purl.org/vocab/relationship/"
            xmlns:dcterms="http://purl.org/dc/terms/" xmlns:bm="http://betamasaheft.eu/docs.html#"
            xmlns:pelagios="http://pelagios.github.io/vocab/terms#"
            xmlns:syriaca="http://syriaca.org/documentation/relations.html#"
            xmlns:saws="http://purl.org/saws/ontology#"
            xmlns:snap="http://data.snapdrgn.net/ontology/snap#"
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:skos="http://www.w3.org/2004/02/skos/core#"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:crm = "http://www.cidoc-crm.org/cidoc-crm/">
            <xsl:for-each select="//t:category[t:desc]">
                <rdf:Description rdf:about="http://betamasaheft.eu/{replace(t:desc, ' ', '_')}">
                    <rdf:type>taxonomy</rdf:type>
                </rdf:Description>
            </xsl:for-each>
            <xsl:for-each select="//t:category[t:catDesc]">
                <rdf:Description rdf:about="http://betamasaheft.eu/{t:catDesc}">
                    <rdfs:subClassOf
                        rdf:resource="http://betamasaheft.eu/{if(parent::t:category/t:desc) then replace(parent::t:category/t:desc, ' ', '_') else replace(parent::t:category/t:catDesc, ' ', '_')}"
                    />
                </rdf:Description>
            </xsl:for-each>
        </rdf:RDF>

    </xsl:template>
-->

    <xsl:template match="t:TEI">
        <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/">
            <xsl:variable name="mainID" select="@xml:id"/>
            <xsl:variable name="collection">
                <xsl:choose>
                    <xsl:when test="@type =  'mss'">manuscripts</xsl:when>
                    <xsl:when test="@type =  'work'">works</xsl:when>
                    <xsl:when test="@type =  'nar'">narratives</xsl:when>
                    <xsl:when test="@type =  'place'">places</xsl:when>
                    <xsl:when test="@type =  'pers'">persons</xsl:when>
                    <xsl:when test="@type =  'ins'">institutions</xsl:when>
                    <xsl:otherwise>authority-files</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
            <xsl:variable name="xmluri">
                <xsl:value-of select="concat('http://betamasaheft.eu/tei/',@xml:id,'.xml')"/>
            </xsl:variable>
            <xsl:variable name="mainurl">
                <xsl:value-of select="concat('http://betamasaheft.eu/', $collection, '/',@xml:id,'/main')"/>
            </xsl:variable>
            <rdf:Description rdf:about="http://betamasaheft.eu/{@xml:id}">
                <rdf:type>
                    <xsl:value-of select="@type"/>
                </rdf:type>
                <dcterms:source rdf:resource="{$xmluri}"/>
                <foaf:homepage rdf:resource="{$mainurl}"/>
                
                <crm:P48_has_preferred_identifier>
                   <xsl:value-of select="@xml:id"/>
                </crm:P48_has_preferred_identifier>
                
                <dc:creator>
                    <xsl:value-of select="//t:publisher"/>
                </dc:creator>
                <dc:publisher>
                    <xsl:value-of select="//t:funder"/>
                </dc:publisher>
                <dc:format>xml</dc:format>
                <xsl:apply-templates select="//t:language"/>
                <xsl:apply-templates select="//t:editor"/>
                <xsl:apply-templates select="//t:term[@key]"/>
                <xsl:apply-templates select="//t:persName[@ref]"/>
                <xsl:apply-templates select="//t:date"/>
                <xsl:apply-templates select="//t:origDate"/>
                <xsl:apply-templates select="//t:ref[@type]"/>
                <xsl:if test="@type = 'mss'">
                    <rdf:type rdf:resource="http://pelagios.github.io/vocab/terms#AnnotatedThing"/>
                    <xsl:apply-templates select="//t:material[@key]"/>
                    <xsl:apply-templates select="//t:objectDesc[@form]"/>
                    <xsl:apply-templates select="//t:msItem"/>
                    <xsl:if test="//t:msPart">
                        <crm:P57_has_number_of_parts>
                        <crm:E60_Number>
                                <xsl:value-of select="count(//t:msPart)"/>
                            </crm:E60_Number>
                    </crm:P57_has_number_of_parts>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="@type = 'work'">
                    <rdf:type rdf:resource="http://pelagios.github.io/vocab/terms#AnnotatedThing"/>
                    <xsl:apply-templates select="//t:listBibl[@type = 'clavis']"/>
                    <xsl:apply-templates select="//t:titleStmt/t:title"/>
                    <xsl:apply-templates select="//t:witness"/>
                </xsl:if>
                <xsl:if test="@type = 'place' or @type = 'ins'">
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
                    <xsl:apply-templates select="@type | @subtype"/>
                    <xsl:apply-templates select="//t:place/t:placeName" mode="pn"/>
                </xsl:if>
                <xsl:if test="@type = 'pers'">
                    <xsl:if test="//t:person/@sameAs">
                        <skos:exactMatch rdf:resource="https://www.wikidata.org/entity/{//t:person/@sameAs}"/>
                    </xsl:if>
                    <xsl:apply-templates select="@type | @subtype"/>
                    <xsl:apply-templates select="//t:person/t:persName" mode="pn"/>
                </xsl:if>
            </rdf:Description>
            <xsl:apply-templates select="//t:relation"/>
            <xsl:for-each select="//t:placeName[@ref]">
                <xsl:sort/>
                <xsl:call-template name="places">
                    <xsl:with-param name="mainID"> <xsl:value-of select="$mainID"/>
                    </xsl:with-param>
                    <xsl:with-param name="n"> <xsl:value-of select="position()"/>
                    </xsl:with-param>
                    
                </xsl:call-template>
            </xsl:for-each>
            <xsl:if test="@type = 'mss'">
            <xsl:for-each select="//t:persName[@type][@ref !='PRS00000']">
                <xsl:sort/>
                <xsl:call-template name="persons">
                    <xsl:with-param name="mainID"> <xsl:value-of select="$mainID"/>
                        </xsl:with-param>
                    <xsl:with-param name="n"> <xsl:value-of select="position()"/>
                        </xsl:with-param>
                   </xsl:call-template>
            </xsl:for-each>
            </xsl:if>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="t:relation[@active][@passive]">
        <xsl:variable name="a" select="@active"/>
        <xsl:variable name="n" select="@name"/>
        <xsl:choose>
            <xsl:when test="contains(@passive, ' ')">
            <xsl:for-each select="tokenize(normalize-space(@passive), ' ')">
                <rdf:Description rdf:about="http://betamasaheft.eu/{$a}">
            <xsl:element name="{$n}">
                <xsl:attribute name="rdf:resource">
                    <xsl:value-of select="concat('http://betamasaheft.eu/',.)"/>
                </xsl:attribute>
            </xsl:element>
        </rdf:Description>
                </xsl:for-each>
            </xsl:when>
        <xsl:otherwise>
            <rdf:Description rdf:about="http://betamasaheft.eu/{$a}">
                <xsl:element name="{$n}">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="concat('http://betamasaheft.eu/',@passive)"/>
                    </xsl:attribute>
                </xsl:element>
            </rdf:Description>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:listBibl[@type = 'clavis']">
        <xsl:for-each select="t:bibl[@type][t:citedRange/text()]">
            <P1_is_identified_by>
               <xsl:value-of select="concat(@type, ' ', t:citedRange/text())"/>
            </P1_is_identified_by>
        </xsl:for-each>
    </xsl:template>


    <xsl:template match="t:msItem">
        <dcterms:hasPart>
            <xsl:choose>
                <xsl:when test="t:title[@ref]">
                    <xsl:attribute name="rdf:resource">
                        <xsl:value-of select="concat('http://betamasaheft.eu/',t:title/@ref)"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="t:title"/>
                </xsl:otherwise>
            </xsl:choose>
        </dcterms:hasPart>
    </xsl:template>
    
    <xsl:template match="t:material">
        <crm:P46_is_composed_of>
            <xsl:value-of select="@key"/>
        </crm:P46_is_composed_of>
    </xsl:template>
    
    <xsl:template match="t:objectDesc">
        <rdf:type>
            <xsl:value-of select="@form"/>
        </rdf:type>
    </xsl:template>
    
    <xsl:template match="@type | @subtype">
        <rdf:type rdf:resource="http://betamasaheft.eu/{.}"/>
    </xsl:template>

    <xsl:template match="t:term">
        <xsl:choose>
            <xsl:when test="@key='Aks'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03wskd389m"/>
            </xsl:when>
            <xsl:when test="@key='Paks1'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssrjvk"/>
            </xsl:when>
            <xsl:when test="@key='Paks2'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvm7f"/>
            </xsl:when>
            <xsl:when test="@key='Gon'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssdh3k"/>
            </xsl:when>
            <xsl:when test="@key='ZaMa'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssvtwm"/>
            </xsl:when>
            <xsl:when test="@key='MoPe'">
                <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03tcssfc3r"/>
            </xsl:when>
            <xsl:otherwise> <rdf:type>
            <xsl:attribute name="rdf:resource">http://betamasaheft.eu/<xsl:value-of select="@key"/>
                    </xsl:attribute>
        </rdf:type>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="t:ref[@type]">
        <dc:relation>
            <xsl:attribute name="rdf:resource">http://betamasaheft.eu/<xsl:value-of select="@corresp"/>
            </xsl:attribute>
        </dc:relation>
    </xsl:template>

    <xsl:template match="t:language">
        <dc:language rdf:datatype="http://www.w3.org/2001/XMLSchema#language">
            <xsl:value-of select="@ident"/>
        </dc:language>
    </xsl:template>

    <xsl:template match="t:date | t:origDate">
        <crm:P4_has_time_span>
        <xsl:choose>
            <xsl:when test="@when">
                <crm:E52_Time-span>
                    <crm:P79_beginning_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
            <xsl:value-of select="@when"/>
                </crm:P79_beginning_is_qualified_by>
                    <crm:P79_end_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                        <xsl:value-of select="@when"/>
                    </crm:P79_end_is_qualified_by>
                </crm:E52_Time-span>
            </xsl:when>
        <xsl:when test="@notBefore or @notAfter">
            <crm:E52_Time-span>
            <xsl:if test="@notBefore">
                <crm:P79_beginning_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="@notBefore"/>
            </crm:P79_beginning_is_qualified_by>
            </xsl:if>
            <xsl:if test="@notAfter">
                <crm:P80_end_is_qualified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="@notAfter"/>
            </crm:P80_end_is_qualified_by>
        </xsl:if>
        </crm:E52_Time-span>
        </xsl:when>
            <xsl:otherwise>
                <crm:E52_Time-span>
                    <crm:P78_is_identified_by rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                            <xsl:value-of select="."/>
                        </crm:P78_is_identified_by>
                </crm:E52_Time-span>
            </xsl:otherwise>
        </xsl:choose>
            
        </crm:P4_has_time_span>
    </xsl:template>
    
    
    <xsl:template match="t:title">
        <dc:title>
            <xsl:value-of select="."/>
        </dc:title>
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
    
    <xsl:template match="t:persName" mode="pn">
        <dc:title>
            <xsl:value-of select="."/>
        </dc:title>
    </xsl:template>
    
    <xsl:template match="t:witness">
        <dc:source>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/',@corresp)"/>
            </xsl:attribute>
        </dc:source>
    </xsl:template>
    
    <xsl:template name="places">
        <xsl:param name="mainID"/>
        <xsl:param name="n"/>
                    <oa:Annotation rdf:about="http://betamasaheft.eu/{$mainID}/annotations/{$n}">
                        <oa:hasTarget rdf:resource="http://betamasaheft.eu/{$mainID}"/>
                        <oa:hasBody rdf:resource="{if(starts-with(@ref, 'pleiades:')) then concat('https://pleiades.stoa.org/places/', substring-after(@ref, 'pleiades:')) else if (starts-with(@ref, 'Q')) then concat('https://www.wikidata.org/entity/', @ref) else concat('http://betamasaheft.eu/',@ref)}"/>
                        <oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="current-date()"/>
            </oa:annotatedAt>
                    </oa:Annotation>
    </xsl:template>
    
    <xsl:template name="persons">
        <xsl:param name="mainID"/>
        <xsl:param name="n"/>
        <oa:Annotation rdf:about="http://betamasaheft.eu/{$mainID}/annotations/{$n}">
            <rdf:type>
                <xsl:value-of select="@type"/>
            </rdf:type>
            <oa:hasTarget rdf:resource="http://betamasaheft.eu/{$mainID}"/>
            <oa:hasBody rdf:resource="{if(starts-with(@ref, 'pleiades:')) then concat('https://pleiades.stoa.org/places/', substring-after(@ref, 'pleiades:')) else if (starts-with(@ref, 'Q')) then concat('https://www.wikidata.org/entity/', @ref) else concat('http://betamasaheft.eu/',@ref)}"/>
            <oa:annotatedAt rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                <xsl:value-of select="current-date()"/>
            </oa:annotatedAt>
        </oa:Annotation>
    </xsl:template>
    
    <xsl:template match="t:persName">
        <dc:relation>
            <xsl:attribute name="rdf:resource">
                <xsl:value-of select="concat('http://betamasaheft.eu/',@ref)"/>
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

    <!-- <dcterms:temporal rdf:resource="http://n2t.net/ark:/99152/p03wskd389m"/> period-->
    <!--<dcterms:temporal>date</dcterms:temporal>-->
    <!--relations-->

</xsl:stylesheet>