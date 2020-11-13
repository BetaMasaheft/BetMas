<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:post="http://myfunction" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output encoding="UTF-8" method="xml"/>
    <xsl:output indent="yes" method="xml"/>
    <xsl:variable name="BMurl">https://betamasaheft.eu/</xsl:variable>
    <xsl:variable name="editorslist" select="doc('xmldb:exist:///db/apps/BetMas/lists/editors.xml')//t:list"/>
    <xsl:variable name="canontax" select="doc('xmldb:exist:///db/apps/BetMas/lists/canonicaltaxonomy.xml')"/>
    <xsl:variable name="listPrefixDef" select="//t:listPrefixDef"/>
 
    <xsl:function name="post:id">
        <xsl:param name="id"/>
        <xsl:choose>
            <xsl:when test="starts-with($id, 'http')">
                <xsl:value-of select="$id"/>
            </xsl:when>
            <xsl:when test="contains($id, ':')">
                <xsl:variable name="prefix" select="substring-before($id,':')"/>
                <xsl:variable name="pdef" select="$listPrefixDef//t:prefixDef[@ident=$prefix]"/>
                <xsl:choose>
                    <xsl:when test="$pdef">
                        <xsl:value-of select="replace(substring-after($id, ':'), $pdef/@matchPattern, $pdef/@replacementPattern)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat('no matching prefix ',$prefix, ' found for ', $id)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat($BMurl, $id)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="post:token">
        
        <xsl:param name="val"/>
        <xsl:choose>
            <xsl:when test="contains($val, ' ')">
                <xsl:variable name="link">
                    <xsl:for-each select="tokenize($val, ' ')">
                        <xsl:value-of select="concat(post:id(.), ' ')"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="string-join($link, ' ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="post:id($val)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:template match="@* | text() | element()">
        <xsl:copy>
            <xsl:apply-templates select="@* | text() | element()"/>
        </xsl:copy>
    </xsl:template>
    
  <xsl:template match="comment()"/>
    
 <xsl:template match="processing-instruction('xml-model')">
     <xsl:if test="contains(.,'http://relaxng.org/ns/structure/1.0')">
            <xsl:processing-instruction name="xml-model">
    <xsl:text>href="https://raw.githubusercontent.com/BetaMasaheft/schema/master/tei-betamesaheft-expanded.rng" 
schematypens="http://relaxng.org/ns/structure/1.0"</xsl:text>
  </xsl:processing-instruction>
        </xsl:if>
     <xsl:if test="contains(.,'http://purl.oclc.org/dsdl/schematron')">
            <xsl:processing-instruction name="xml-model">
    <xsl:text>href="https://raw.githubusercontent.com/BetaMasaheft/schema/master/tei-betamesaheft-expanded.rng" 
        type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:text>
  </xsl:processing-instruction>
        </xsl:if>
 </xsl:template>
   
   <xsl:template match="t:TEI">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="t:teiHeader"/>
            <standOff>
                <listRelation>
                    <xsl:apply-templates select="//t:relation" mode="standoff"/>
                </listRelation>
            </standOff>
            <xsl:apply-templates select="t:facsimile"/>
            <xsl:apply-templates select="t:text"/>
        </xsl:copy>
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
            OBTAINED ADDING .XML AT THE END OF THE ENTRY URL.
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
    <xsl:template match="t:text">
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="t:teiHeader">
        <xsl:copy>
            <xsl:apply-templates select="t:fileDesc"/>
            <xsl:choose>
                <xsl:when test="not(t:encodingDesc)">
                <encodingDesc>
                        <xsl:copy-of select="$canontax"/>
                </encodingDesc>
            </xsl:when>
            <xsl:otherwise>
                    <xsl:apply-templates select="t:encodingDesc"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="t:profileDesc"/>
            <xsl:apply-templates select="t:revisionDesc"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:encodingDesc">
        <xsl:copy>
           <xsl:apply-templates/>
                    <xsl:apply-templates select="$canontax"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:titleStmt">
        <xsl:copy>
            <xsl:apply-templates/>
            <xsl:variable name="ekeys" select="//t:editor/@key"/>
            <xsl:variable name="cwhos" select="//t:change/@who"/>
            <xsl:for-each select="distinct-values($cwhos[not(.=$ekeys)])">
                <respStmt xml:id="{.}" corresp="https://betamasaheft.eu/team.html#{.}">
                    <resp>contributor</resp>
                    <name>
                        <xsl:value-of select="$editorslist//t:item[@xml:id=current()]"/>
                    </name>
                </respStmt>
            </xsl:for-each>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:category"/>

<xsl:template match="t:profileDesc">
    <xsl:copy>
    <xsl:apply-templates/>
   <xsl:if test="//@calendar">
       <calendarDesc>
        <calendar xml:id="world">
            <p>ʿĀmata ʿālam/ʿĀmata ʾəm-fəṭrat (Era of the World)</p>
        </calendar>
        <calendar xml:id="ethiopian">
            <p> ʿĀmata śəggāwe (Era of the Incarnation –
                Ethiopian)</p>
        </calendar>
        <calendar xml:id="grace">
            <p>ʿĀmata məḥrat (Era of Grace)</p>
        </calendar>
        <calendar xml:id="diocletian">
            <p>ʿĀmata samāʿtāt (Era of Martyrs (Diocletian))</p>
        </calendar>
        <calendar xml:id="alexander">
            <p> Era of Alexander</p>
        </calendar>
        <calendar xml:id="evangelists">
            <p>Evangelists' years</p>
        </calendar>
        <calendar xml:id="islamic">
            <p>Hiǧrī (Islamic)</p>
        </calendar>
        <calendar xml:id="hijri">
            <p>Hiǧrī (Islamic) in IslHornAfr</p>
        </calendar>
        <calendar xml:id="julian">
            <p>Julian</p>
        </calendar>
    </calendarDesc>
            </xsl:if>
    </xsl:copy>
</xsl:template>
    
    <xsl:template match="@corresp[(parent::t:origDate |parent::t:div |parent::t:ref | parent::t:witness[not(@type = 'external')])]">
        <xsl:attribute name="corresp">
            <xsl:value-of select="concat($BMurl, .)"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@resp | @who">
        <xsl:variable name="value" select="data(.)"/>
        <xsl:attribute name="{./name()}">
            
            <xsl:choose>
                <xsl:when test="string-length($value) le 3">
                    <xsl:value-of select="concat('#', $value)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="post:id($value)"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="t:listprefixDef"/>
    
    <xsl:template match="@ref | @sameAs">
        <xsl:choose>
            <xsl:when test=".='PRS00000' or .='PRS0000'"/>
            <xsl:otherwise>
        <xsl:attribute name="{name()}">
            <xsl:value-of select="post:id(.)"/>
        </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <xsl:template match="@calendar">
        <xsl:attribute name="{name()}">
            <xsl:value-of select="concat('#', .)"/>
        </xsl:attribute>
    </xsl:template>
    <xsl:template match="@type[parent::t:witness]"/>

    <xsl:template match="t:term">
        <xsl:copy>
            <xsl:attribute name="ana">
                <xsl:value-of select="concat('#',@key)"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="not(text())">
                    <xsl:value-of select="doc(concat($BMurl, @key, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>
                </xsl:when>
        <xsl:otherwise>
                    <xsl:value-of select="text()"/>
                </xsl:otherwise>
            </xsl:choose>
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
            <xsl:variable name="facs" select="if(contains(@facs, ' ')) then tokenize(normalize-space(@facs), ' ') else @facs"/>
       
            <xsl:choose>
            <xsl:when test="parent::t:*/name() = 'locus'">
       
<!--                depending on the content of msIdentifier/idno/@facs, the format of uris to be added in @facs changes. -->
                 <xsl:for-each select="$facs">
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
                 </xsl:for-each>
            </xsl:when>
            <xsl:when test="parent::t:*/name() = 'idno'">
<!--                the full manifest uri is present for the digital vatican library and ofr bnf.-->
                <xsl:for-each select="$facs">
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
                </xsl:for-each>
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
                            <xsl:when test="doc-available(concat('https://betamasaheft.eu/manuscripts/', $filename, '.xml'))">
                                <xsl:value-of select="doc(concat('https://betamasaheft.eu/manuscripts/', $filename, '.xml'))/t:TEI//t:titleStmt/t:title[1]"/>
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


    <xsl:template match="t:listRelation"/>
    <!--    relations need to have uris in a ref rather than @name-->
    <xsl:template match="t:relation" mode="standoff">
        <xsl:copy>
            <xsl:attribute name="name">
                <xsl:value-of select="@name"/>
            </xsl:attribute>
            <xsl:attribute name="ref">
               <xsl:value-of select="post:id(@name)"/>
            </xsl:attribute>
            <xsl:apply-templates select="@active | @mutual | @passive"/>
            <xsl:apply-templates/>
            <!--            need to be transformed into uris of the project-->
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@active | @passive |@mutual">
        <xsl:variable name="norm" select="normalize-space(.)"/>
        <xsl:attribute name="{./name()}">
           <xsl:value-of select="post:token($norm)"/>
        </xsl:attribute>
    </xsl:template>
  
    
    <xsl:template match="t:editor">
        <xsl:copy>
            
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="corresp">
                <xsl:value-of select="concat('https://betamasaheft.eu/team.html#', @key)"/>
            </xsl:attribute>
<xsl:attribute name="xml:id">
                <xsl:value-of select="@key"/>
            </xsl:attribute>
            <xsl:value-of select="$editorslist//t:item[@xml:id=current()/@key]/text()"/>
            
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
                    <xsl:variable name="file" select="document(concat('https://betamasaheft.eu/manuscripts/', $filename, '.xml'))"/>
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