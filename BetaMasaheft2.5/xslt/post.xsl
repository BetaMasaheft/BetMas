<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output encoding="UTF-8" method="xml"/>
    <xsl:output indent="yes" method="xml"/>
    <xsl:variable name="BMurl">http://betamasaheft.eu/</xsl:variable>
    
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="comment()"/>
    
 <xsl:template match="processing-instruction('xml-model')">
     <xsl:if test="contains(.,'http://relaxng.org/ns/structure/1.0')">
            <xsl:processing-instruction name="xml-model">
    <xsl:text>href="https://raw.githubusercontent.com/SChAth/schema/master/tei-betamesaheft-expanded.rng" 
schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text>
  </xsl:processing-instruction>
        </xsl:if>
     <xsl:if test="contains(.,'http://purl.oclc.org/dsdl/schematron')">
            <xsl:processing-instruction name="xml-model">
    <xsl:text>href="https://raw.githubusercontent.com/SChAth/schema/master/tei-betamesaheft-expanded.rng" 
        type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text>
  </xsl:processing-instruction>
        </xsl:if>
 </xsl:template>
   

    <!--
    
    publicationStmt/date is added and contains date and time of upload. will constitute the first online publication date and be comparable to the last update stored in the change section
    -->
    <xsl:template match="t:publicationStmt">
        <xsl:comment>
            THIS IS A POSTPROCESSED FILE WHICH ADDS USEFUL 
            AND EXPLICIT
            DATA STORED IN OTHER COLLECTIONS WITH
            THE RESOURCE YOU ARE REQUESTING.
            THE ACTUAL SOURCE FILE FOR THIS ENTRY CAN BE 
            SEEN ADDING .XML AT THE END OF THE ENTRY URL.
            <xsl:value-of select="concat($BMurl, ./ancestor::t:TEI/@xml:id, '.xml')"/>
                </xsl:comment>
        <xsl:copy>
            <xsl:copy-of select="t:authority"/>
            <xsl:copy-of select="t:pubPlace"/>
            <xsl:copy-of select="t:publisher"/>
            <xsl:copy-of select="t:availability"/>
            <date>
                <xsl:value-of select="current-dateTime()"/>
            </date>
        </xsl:copy>
    </xsl:template>

    
    <xsl:template match="@corresp[(parent::t:ref | parent::t:witness[not(@type = 'external')])]">
        <xsl:attribute name="corresp">
            <xsl:value-of select="concat($BMurl, .)"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@resp | @who">
        
        <xsl:attribute name="{./name()}">
            <xsl:choose>
                <xsl:when test=". = 'AB'">Alessandro Bausi</xsl:when>
                <xsl:when test=". = 'ES'">Eugenia Sokolinski</xsl:when>
                <xsl:when test=". = 'DN'">Denis Nosnitsin</xsl:when>
                <xsl:when test=". = 'MV'">Massimo Villa</xsl:when>
                <xsl:when test=". = 'DR'">Dorothea Reule</xsl:when>
                <xsl:when test=". = 'SG'">Solomon Gebreyes</xsl:when>
                <xsl:when test=". = 'PL'">Pietro Maria Liuzzo</xsl:when>
                <xsl:when test=". = 'SA'">Stéphane Ancel</xsl:when>
                <xsl:when test=". = 'SD'">Sophia Dege</xsl:when>
                <xsl:when test=". = 'VP'">Vitagrazia Pisani</xsl:when>
                <xsl:when test=". = 'IF'">Iosif Fridman</xsl:when>
                <xsl:when test=". = 'SH'">Susanne Hummel</xsl:when>
                <xsl:when test=". = 'FP'">Francesca Panini</xsl:when>
                <xsl:when test=". = 'AA'">Abreham Adugna</xsl:when>
                <xsl:when test=". = 'EG'">Ekaterina Gusarova</xsl:when>
                <xsl:when test=". = 'IR'">Irene Roticiani</xsl:when>
                <xsl:when test=". = 'MB'">Maria Bulakh</xsl:when>
                <xsl:when test=". = 'VR'">Veronika Roth</xsl:when>
                <xsl:when test=". = 'MK'">Magdalena Krzyzanowska</xsl:when>
                <xsl:when test=". = 'DE'">Daria Elagina</xsl:when>
                <xsl:when test=". = 'NV'">Nafisa Valieva</xsl:when>
                <xsl:when test=". = 'RHC'">Ran HaCohen</xsl:when>
                <xsl:when test=". = 'SS'">Sisay Sahile</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($BMurl, .)"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@ref | @sameAs">
        <xsl:attribute name="{name()}">
            <xsl:choose>
                <xsl:when test="starts-with(., 'pleiades:')">
                    <xsl:value-of select="concat('https://pleiades.stoa.org/places/', substring-after(., 'pleiades:'))"/>
                </xsl:when>
                <xsl:when test="starts-with(., 'gn:')">
                    <xsl:value-of select="concat('http://sws.geonames.org/', substring-after(., 'gn:'))"/>
                </xsl:when>
                <xsl:when test="starts-with(., 'Q')">
                    <xsl:value-of select="concat('https://www.wikidata.org/wiki/', .)"/>
                </xsl:when>
            <xsl:otherwise>
                    <xsl:value-of select="concat($BMurl, .)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    
    
    <xsl:template match="@type[parent::t:witness]"/>

    <xsl:template match="t:term">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="doc(concat($BMurl, @key, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>

        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:idno">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
        <xsl:value-of select="."/>
        </xsl:copy>
    
    </xsl:template>
    
    <xsl:template match="@facs">
        <xsl:variable name="id" select="root(.)/t:TEI/@xml:id"/>
        <xsl:attribute name="{name()}">
        <xsl:choose>
            <xsl:when test="parent::t:*/name() = 'locus'">
<!--                depending on the content of msIdentifier/idno/@facs, the format of uris to be added in @facs changes. -->
                <xsl:variable select="root(.)//t:idno[@facs]/@facs" name="mainFacs"/>
                <xsl:choose>
                    <xsl:when test="contains($mainFacs, 'vatlib')">
                        <xsl:variable name="msname" select="substring-after(substring-before($mainFacs, 'manifest.json'), 'MSS_')"/>
                        <xsl:variable name="iiif" select="concat('http://digi.vatlib.it/iiifimage/MSS_', $msname, substring-before($msname, '/'), '_')"/>
                        <xsl:value-of select="concat($iiif, .,'.jp2/info.json')"/>
                    </xsl:when>
                    <xsl:when test="contains($mainFacs, 'gallica')">
                        <xsl:variable name="iiif" select="replace($mainFacs,'/ark:', '/iiif/ark:')"/>
                        <xsl:value-of select="concat($iiif, '/', . ,'/info.json')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($BMurl, 'api/iiif/', $id, '/canvas/p', format-number(.,'###'))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="parent::t:*/name() = 'idno'">
<!--                the full manifest uri is present for the digital vatican library and ofr bnf.-->
                <xsl:choose>
                    <xsl:when test="contains(., 'vatlib')">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <xsl:when test="contains(., 'gallica')">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <!--                   for BM hosted images, there is in idno/@facs only the minimum required path for the images on the server, the manifest uri needs to be build  -->
                    <xsl:otherwise>
                        <xsl:value-of select="concat($BMurl, 'api/iiif/', $id, '/manifest')"/>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:when>
            <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
        </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <!--all names in meaningful items to be expanded-->
    <xsl:template match="t:title|t:persName|t:placeName|t:repository">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="@ref and not(./text())">
                    <xsl:choose>
                        <xsl:when test="doc-available(concat($BMurl, @ref, '.xml'))">
                            <xsl:if test=".[not(text())]">
                                <xsl:value-of select="doc(concat($BMurl, @ref, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@ref"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:ref">
        <xsl:copy>
            <xsl:apply-templates select="(@corresp | @type | @cRef | @target)"/>

<xsl:choose>
            <!--    populate refs of all types with text -->
            <xsl:when test=".[not(text())]">
                        <xsl:choose>
                            <xsl:when test="doc-available(concat($BMurl, @corresp, '.xml'))">
                                <xsl:value-of select="doc(concat($BMurl, @corresp, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                                <!--this addes the reference identifier as text if the record does not yet exist-->
                            </xsl:otherwise>
                        </xsl:choose>
            </xsl:when>
                
                    <xsl:when test="@type = 'mss' or @type = 'hand' or @type = 'mspart' or @type = 'item' or @type = 'quire' or @type = 'binding' or @type = 'deco'">
                        <xsl:variable name="filename" select="                                 if (contains(@corresp, '#')) then                                     (substring-before(@corresp, '#'))                                 else                                     (@corresp)"/>
                        <xsl:variable name="id" select="                                 if (contains(@corresp, '#')) then                                     (substring-after(@corresp, '#'))                                 else                                     ('')"/>
                        <xsl:choose>
                            <xsl:when test="doc-available(concat('http://betamasaheft.aai.uni-hamburg.de/manuscripts/', $filename, '.xml'))">
                                <xsl:value-of select="doc(concat('http://betamasaheft.aai.uni-hamburg.de/manuscripts/', $filename, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>
                                <xsl:if test="$id != ''">
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="$id"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="."/>
                                <!--this addes the reference identifier as text if the record does not yet exist-->
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            
        </xsl:copy>
    </xsl:template>



    <!--    relations need to have uris in a ref rather than @name-->
    <xsl:template match="t:relation">
        <xsl:copy>
            <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
            <xsl:attribute name="ref">
                <xsl:choose>
                    <xsl:when test="contains(@name, 'saws:')">
                        <xsl:value-of select="concat('http://purl.org/saws/ontology#', substring-after(@name, 'saws:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'snap:')">
                        <xsl:value-of select="concat('http://data.snapdrgn.net/ontology/snap#', substring-after(@name, 'snap:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'gn:')">
                        <xsl:value-of select="concat('http://www.geonames.org/ontology#', substring-after(@name, 'gn:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'dcterms:')">
                        <xsl:value-of select="concat('http://purl.org/dc/terms/', substring-after(@name, 'dcterms:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'bm:')">
                        <xsl:value-of select="concat('http://betamasaheft.aai.uni-hamburg.de/docs.html#', @name)"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'lawd:')">
                        <xsl:value-of select="concat('http://lawd.info/ontology/', substring-after(@name, 'lawd:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'syriaca:')">
                        <xsl:text>http://syriaca.org/documentation/relations.html#</xsl:text>
                        <xsl:value-of select="@name"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'agrelon:')">
                        <xsl:value-of select="concat('http://d-nb.info/standards/elementset/agrelon.owl#', substring-after(@name, 'agrelon:'))"/>
                    </xsl:when>
                    <xsl:when test="contains(@name, 'rel:')">
                        <xsl:value-of select="concat('http://purl.org/vocab/relationship/', substring-after(@name, 'rel:'))"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="(@active|@mutual|@passive)"/>
            <xsl:apply-templates/>
            <!--            need to be transformed into uris of the project-->
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@active[parent::t:relation]">
        <xsl:variable name="norm" select="normalize-space(.)"/>
        <xsl:attribute name="active">
            <xsl:choose>
                <xsl:when test="contains($norm, ' ')">
                    <xsl:variable name="link">
                        <xsl:for-each select="tokenize($norm, ' ')">
                    <xsl:value-of select="concat($BMurl, ., ' ')"/>
                </xsl:for-each>
                    </xsl:variable>
                    <xsl:value-of select="string-join($link, ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($BMurl, .)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@passive[parent::t:relation]">
        <xsl:attribute name="passive">
            <xsl:variable name="norm" select="normalize-space(.)"/>
            <xsl:choose>
                <xsl:when test="contains($norm, ' ')">
                    <xsl:variable name="link">
                        <xsl:for-each select="tokenize($norm, ' ')">
                        <xsl:value-of select="concat($BMurl, ., ' ')"/>
                    </xsl:for-each>
                    </xsl:variable>
                    <xsl:value-of select="string-join($link, ' ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($BMurl, .)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>    
    <xsl:template match="@mutual[parent::t:relation]">
        
        <xsl:variable name="norm" select="normalize-space(.)"/>
        <xsl:attribute name="mutual">
            <xsl:variable name="link">
                <xsl:for-each select="tokenize($norm, ' ')">
                <xsl:value-of select="concat($BMurl, ., ' ')"/>
            </xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="string-join($link, ' ')"/>
        </xsl:attribute>
    </xsl:template>
    
    
    <xsl:template match="t:editor">
        <xsl:copy>
            
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
            <xsl:when test="@key = 'AB'">Alessandro Bausi</xsl:when>
            <xsl:when test="@key = 'ES'">Eugenia Sokolinski</xsl:when>
            <xsl:when test="@key = 'DN'">Denis Nosnitsin</xsl:when>
            <xsl:when test="@key = 'MV'">Massimo Villa</xsl:when>
            <xsl:when test="@key = 'DR'">Dorothea Reule</xsl:when>
            <xsl:when test="@key = 'SG'">Solomon Gebreyes</xsl:when>
            <xsl:when test="@key = 'PL'">Pietro Maria Liuzzo</xsl:when>
            <xsl:when test="@key = 'SA'">Stéphane Ancel</xsl:when>
            <xsl:when test="@key = 'SD'">Sophia Dege</xsl:when>
            <xsl:when test="@key = 'VP'">Vitagrazia Pisani</xsl:when>
            <xsl:when test="@key = 'IF'">Iosif Fridman</xsl:when>
            <xsl:when test="@key = 'SH'">Susanne Hummel</xsl:when>
            <xsl:when test="@key = 'FP'">Francesca Panini</xsl:when>
            <xsl:when test="@key = 'AA'">Abreham Adugna</xsl:when>
            <xsl:when test="@key = 'EG'">Ekaterina Gusarova</xsl:when>
            <xsl:when test="@key = 'IR'">Irene Roticiani</xsl:when>
            <xsl:when test="@key = 'MB'">Maria Bulakh</xsl:when>
            <xsl:when test="@key = 'VR'">Veronika Roth</xsl:when>
            <xsl:when test="@key = 'MK'">Magdalena Krzyzanowska</xsl:when>
            <xsl:when test="@key = 'DE'">Daria Elagina</xsl:when>
            <xsl:when test="@key = 'NV'">Nafisa Valieva</xsl:when>
            <xsl:when test="@key = 'RHC'">Ran HaCohen</xsl:when>
            <xsl:when test="@key = 'SS'">Sisay Sahile</xsl:when>
        </xsl:choose>
        </xsl:copy>
    </xsl:template>

    <!--    populate bibl in listbibl type mss with idnos-->

    <!--    populate witness with idnos-->
    
    <xsl:template match="t:bibl[not(@type = 'external')]">
      <!--  
        <xsl:apply-templates select="@xml:id"/>
      -->  <xsl:if test="t:ptr">
            <!--                      take all from the zotero record, but not the xml id, 
                            as a record can be cited more than once and would invalidate the file-->
            <xsl:variable name="zotero" select="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target, '&amp;format=tei'))//t:biblStruct"/>
            <bibl corresp="{$zotero/@corresp}" type="{$zotero/@type}">
                <xsl:apply-templates select="@xml:id"/>
                <xsl:copy-of select="$zotero//t:title"/>
                <xsl:copy-of select="$zotero//t:author"/>
                <xsl:copy-of select="$zotero//t:editor"/>
                <xsl:copy-of select="$zotero//t:pubPlace"/>
                <xsl:copy-of select="$zotero//t:publisher"/>
                <xsl:copy-of select="$zotero//t:date"/>
                <xsl:copy-of select="$zotero//t:series"/>
                <xsl:copy-of select="$zotero//t:biblScope"/>
                <xsl:copy-of select="$zotero//t:note"/>
                <xsl:if test="t:citedRange">
                    <xsl:copy-of select="t:citedRange"/>
                </xsl:if>
            </bibl>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="t:witness[not(@type = 'external')]">
        
        <xsl:choose>
            <xsl:when test="@corresp">
                <xsl:copy>
                    <xsl:apply-templates select="@corresp"/>
                    <xsl:apply-templates select="@xml:id"/>
                    
                    <xsl:variable name="filename">
                        <xsl:choose>
                            <xsl:when test="contains(@corresp, '#')">
                                <xsl:value-of select="substring-before(@corresp, '#')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="@corresp"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="file" select="document(concat('http://betamasaheft.aai.uni-hamburg.de/manuscripts/', $filename, '.xml'))"/>
                    <idno>
                        <xsl:value-of select="$file//t:msIdentifier/t:idno"/>
                    </idno>
                    <title>
                        <xsl:value-of select="$file//t:titleStmt/t:title"/>
                    </title>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                
                <xsl:if test="t:ptr">
                    <!--                      take all from the zotero record, but not the xml id, 
                            as a record can be cited more than once and would invalidate the file-->
                    <xsl:variable name="zotero" select="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target, '&amp;format=tei'))//t:biblStruct"/>
                    <bibl corresp="{$zotero/@corresp}" type="{$zotero/@type}">
                        <xsl:apply-templates select="@xml:id"/>
                        <xsl:copy-of select="$zotero//t:title"/>
                        <xsl:copy-of select="$zotero//t:author"/>
                        <xsl:copy-of select="$zotero//t:editor"/>
                        <xsl:copy-of select="$zotero//t:pubPlace"/>
                        <xsl:copy-of select="$zotero//t:publisher"/>
                        <xsl:copy-of select="$zotero//t:date"/>
                        <xsl:copy-of select="$zotero//t:series"/>
                        <xsl:copy-of select="$zotero//t:biblScope"/>
                        <xsl:copy-of select="$zotero//t:note"/>
                        <xsl:if test="t:citedRange">
                            <xsl:copy-of select="t:citedRange"/>
                        </xsl:if>
                    </bibl>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!--parchment not @key also in element binding-->
    <xsl:template match="t:material | t:condition">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="@key"/>
        </xsl:copy>
    </xsl:template>

    <!--    custEvent in element, not in type-->
    <xsl:template match="t:custEvent">
        <xsl:copy>
            <xsl:value-of select="@type"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>


    <!--    populate locus with text -->
    <xsl:template match="t:locus">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="not(text())">
                    <xsl:choose>
                        <xsl:when test="@target">
                            <xsl:choose>
                                <xsl:when test="contains(@target, ' ')">
                                    <xsl:choose>
                                        <xsl:when test="//t:extent/t:measure[@unit = 'page']">pp.</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>ff. </xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:for-each select="tokenize(@target, ' ')">
                                        <xsl:value-of select="concat(substring-after(., '#'), ' ')"/>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:choose>
                                        <xsl:when test="//t:extent/t:measure[@unit = 'page']">p.</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>f. </xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="substring-after(@target, '#')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="//t:extent/t:measure[@unit = 'page']">pp.</xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>ff. </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="@from"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@n">
                        <xsl:text>, l.</xsl:text>
                        <xsl:value-of select="@n"/>
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@target">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>