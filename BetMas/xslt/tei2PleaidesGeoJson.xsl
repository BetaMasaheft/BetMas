<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="text" encoding="UTF-8" indent="yes"/>
    <xsl:variable name="collection" select="if (@type = 'place') then 'places' else 'institutions'"/>
    <xsl:template match="/">
        <xsl:if test="//t:geo">
            {"@context": {
            "geojson": "http://ld.geojson.org/vocab#",
            "Feature": "geojson:Feature",
            "FeatureCollection": "geojson:FeatureCollection",
            "GeometryCollection": "geojson:GeometryCollection",
            "LineString": "geojson:LineString",
            "MultiLineString": "geojson:MultiLineString",
            "MultiPoint": "geojson:MultiPoint",
            "MultiPolygon": "geojson:MultiPolygon",
            "Point": "geojson:Point",
            "Polygon": "geojson:Polygon",
            "bbox": {
            "@container": "@list",
            "@id": "geojson:bbox"
            },
            "connectsWith": "_:n8",
            "coordinates": "geojson:coordinates",
            "description": "http://purl.org/dc/terms/description",
            "features": {
            "@container": "@set",
            "@id": "geojson:features"
            },
            "geometry": "geojson:geometry",
            "id": "@id",
            "link": "_:n6",
            "location_precision": "_:n7",
            "names": "_:n9",
            "properties": "geojson:properties",
            "recent_changes": "_:n10",
            "reprPoint": "_:n11",
            "snippet": "http://purl.org/dc/terms/abstract",
            "title": "http://purl.org/dc/terms/title",
            "type": "@type"
            },
            "bbox": [
            <xsl:value-of select="substring-after(//t:geo, ' ')"/>, 
            <xsl:value-of select="substring-before(//t:geo, ' ')"/>,
            <xsl:value-of select="substring-after(//t:geo, ' ')"/>,
            <xsl:value-of select="substring-before(//t:geo, ' ')"/>
            ],
            "citation": "Location based on Encyclopaedia Aethiopica, from the Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea project",
            "connectsWith": [
            "39274",
            <xsl:if test="//t:region"> "<xsl:apply-templates select="//t:region"/>"</xsl:if>
            <xsl:if test="//t:settlement">
                <xsl:for-each select="//t:settlement">,
            "<xsl:apply-templates/>"</xsl:for-each>
            </xsl:if>
            ],
            "creators": [
            {
            "name": "<xsl:apply-templates select="//t:revisionDesc/t:change[contains(., 'created')]/@who"/>"
            }
            ], 
            "contributors": [<xsl:variable name="contributors">
                <xsl:for-each select="//t:revisionDesc/t:change">
                
                {
                "name": "<xsl:apply-templates select="@who"/>"
                },</xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="replace(normalize-space($contributors), ',$', '')"/>
            ],
            <xsl:if test="//t:desc[@type='foundation']">"description": "<xsl:apply-templates select="//t:desc[@type='foundation']"/>",</xsl:if>
            <xsl:if test="//t:ab[@type='history']">"details": "<xsl:variable name="details">
                    <xsl:apply-templates select="//t:ab[@type='history']"/>
                </xsl:variable>
                <xsl:value-of select="normalize-space($details)"/>",</xsl:if>
            "features": [
            {
            "geometry": {    "coordinates": [<xsl:value-of select="substring-after(//t:geo, ' ')"/>, 
            <xsl:value-of select="substring-before(//t:geo, ' ')"/>],
                "type": "Point"
                },
            "id": "<xsl:value-of select="t:TEI/@xml:id"/>",
            "properties": {
            "description": "Location based on Encyclopaedia Aethiopica",
            "link": "http://betamasaheft.aai.uni-hamburg.de/<xsl:value-of select="$collection"/>/<xsl:value-of select="t:TEI/@xml:id"/>",
            "location_precision": "precise",
            <xsl:if test="//t:date[@type='foundation']">"snippet": "<xsl:apply-templates select="//t:date[@type='foundation']"/>",</xsl:if>
            "title": "location of <xsl:value-of select="if ( //t:place/t:placeName[@corresp='#n1'  and @type='normalized'])                  then  normalize-space(//t:place/t:placeName[@corresp='#n1' and @type='normalized']/text())                 else if ( //t:place/t:placeName[@xml:id])                  then  normalize-space(//t:place/t:placeName[@xml:id='n1']/text())                 else if (//t:place/t:placeName[text()][position()= 1]/text() )                 then normalize-space(//t:place/t:placeName[text()][position()= 1]/text())                 else //t:titleStmt/t:title[position() = 1][text()]/text()"/>"
            },
            "type": "Feature"
            }
            ],
            "history": [
            {
            "comment": "Mapped to Json from mycore xml",
            "modified": "<xsl:value-of select="current-dateTime()"/>",
            "principal": "pliuzzo"
            }
            ],
            "id" :"<xsl:value-of select="t:TEI/@xml:id"/>",
            "names": [
            <xsl:variable name="names">
                <xsl:for-each select="//t:placeName[@xml:id]">
                    <xsl:variable name="id" select="@xml:id"/>
                {
                "association_certainty": "certain",
                "attested": "<xsl:value-of select="."/>",
                "romanized": "<xsl:value-of select="//t:placeName[substring-after(@corresp, '#') = $id]"/>",
                "transcription_accuracy": "accurate",
                "transcription_completeness": "complete",
                "uri": "http://betamasaheft.aai.uni-hamburg.de/<xsl:value-of select="$collection"/>/<xsl:value-of select="ancestor::t:TEI/@xml:id"/>
                    <xsl:value-of select="concat('#',@xml:id)"/>"
                },</xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="replace(normalize-space($names), ',$', '')"/>
            ],
            
            "place_types": [
            <xsl:variable name="types">
                <xsl:for-each select="tokenize(//t:place/@type, ' ')">"<xsl:value-of select="."/>",</xsl:for-each>
            </xsl:variable>
            <xsl:value-of select="replace(normalize-space($types), ',$', '')"/>
            ],
            "provenance": "Encyclopedia Aethiopica",
            <xsl:if test="//t:bibl[t:ptr]">"references": [
            
            <xsl:variable name="bibls">
                    <xsl:for-each select="//t:bibl[t:ptr]">
              {  "reference_type": "evidence",
                "work_uri": "<xsl:value-of select="concat('https://www.zotero.org/groups/ethiostudies/items/tag/',t:ptr/@target)"/>"
                },
            </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="replace($bibls, ',[\s\n\t]$', '')"/>
            ],</xsl:if>
            
            "reprPoint": [
            <xsl:value-of select="substring-after(//t:geo, ' ')"/>,
            <xsl:value-of select="substring-before(//t:geo, ' ')"/>
            ],
            "title": "<xsl:value-of select="if ( //t:place/t:placeName[@corresp='#n1'  and @type='normalized'])                      then  normalize-space(//t:place/t:placeName[@corresp='#n1' and @type='normalized']/text())                     else if ( //t:place/t:placeName[@xml:id])                      then  normalize-space(//t:place/t:placeName[@xml:id='n1']/text())                     else if (//t:place/t:placeName[text()][position()= 1]/text() )                     then normalize-space(//t:place/t:placeName[text()][position()= 1]/text())                     else //t:titleStmt/t:title[position() = 1][text()]/text()"/>",
            "type": "FeatureCollection",
            "uri": "http://betamasaheft.aai.uni-hamburg.de/<xsl:value-of select="$collection"/>/<xsl:value-of select="//t:TEI/@xml:id"/>"
            }
            
            </xsl:if>
    </xsl:template>
    <xsl:template match="t:placeName | t:region | t:country | t:settlement">
        <xsl:if test="@type">
            <xsl:value-of select="concat(@type, ': ')"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="contains(@ref, 'gn:')">
                        <xsl:variable name="id" select="substring-after(@ref, 'gn:')"/>
                        <a href="http://www.geonames.org/{$id}">
                            <xsl:value-of select="document(concat('http://api.geonames.org/get?geonameId=',$id,'&amp;username=betamasaheft'))//toponymName"/> 
                            <!--should look at API and get toponims
                           if there is nothing still try a geonames look up for a link
                           -->
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="filename">
                            <xsl:choose>
                                <xsl:when test="contains(@ref, '#')">
                                    <xsl:value-of select="substring-before(@ref, '#')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@ref"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="contains(@ref, 'LOC')">
                                <xsl:choose>
                                    <xsl:when test="doc-available(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))">
                                        <xsl:choose>
                                            <xsl:when test="text()">
                                                <xsl:value-of select="normalize-space(.)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="                                                           if (doc(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@corresp = '#n1' and @type = 'normalized'])                                                          then                                                        normalize-space( doc(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@corresp = '#n1' and @type = 'normalized'] /text()     )                                                         else                                                         if (doc(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@xml:id = 'n1'])                                                          then                                                         normalize-space(    doc(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@xml:id = 'n1']/text()                   )                                                         else                                                          normalize-space(   doc(concat('http://betamasaheft.aai.uni-hamburg.de/places/', $filename, '.xml'))//t:TEI//t:place/t:placeName[1]/text())"/>
                                                <xsl:if test="contains(@ref, '#')">
                                                    <xsl:value-of select="concat(', ', substring-after(@ref, '#'))"/>
                                                </xsl:if>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:choose>
                                    <xsl:when test="doc-available(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))">
                                        <xsl:choose>
                                            <xsl:when test="text()">
                                                <xsl:value-of select="normalize-space(.)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select=" if (doc(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@corresp = '#n1' and @type = 'normalized'])                                                          then   normalize-space(doc(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@corresp = '#n1' and @type = 'normalized'])                                                                                                              else if (doc(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@xml:id = 'n1']) then                                                             normalize-space(doc(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))//t:TEI//t:place/t:placeName[@xml:id = 'n1'])                                                         else   normalize-space( doc(concat('http://betamasaheft.aai.uni-hamburg.de/institutions/', $filename, '.xml'))//t:TEI//t:place/t:placeName[1])"/>
                                                <xsl:if test="contains(@ref, '#')">
                                                    <xsl:value-of select="concat(', ', substring-after(@ref, '#'))"/>
                                                </xsl:if>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@notBefore">
            <xsl:text> After: </xsl:text>
            <xsl:value-of select="@notBefore"/>
        </xsl:if>
        <xsl:if test="@notAfter">
            <xsl:text> Before: </xsl:text>
            <xsl:value-of select="@notAfter"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="@who">
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
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:origDate | t:floruit | t:birth | t:death">
        <p class="lead">
            <xsl:choose>
                <xsl:when test="@when">
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:when test="@from |@to">
                    <xsl:choose>
                        <xsl:when test="@from and @to">
                            <xsl:value-of select="@from"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:when>
                        <xsl:when test="@from and not(@to)">
                            <xsl:text>Before </xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:when>
                        <xsl:when test="@to and not(@from)">
                            <xsl:text>After </xsl:text>
                            <xsl:value-of select="@from"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@notBefore and @notAfter">
                            <xsl:value-of select="@notBefore"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="@notAfter"/>
                        </xsl:when>
                        <xsl:when test="@notAfter and not(@notBefore)">
                            <xsl:text>Before </xsl:text>
                            <xsl:value-of select="@notAfter"/>
                        </xsl:when>
                        <xsl:when test="@notBefore and not(@notAfter)">
                            <xsl:text>After </xsl:text>
                            <xsl:value-of select="@notBefore"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="@evidence"> (<xsl:value-of select="@evidence"/>)</xsl:if>
            <xsl:if test="@cert = 'low'">?</xsl:if>
        </p>
        <xsl:if test="child::t:* or text()">
            <p class="lead">
                <xsl:apply-templates select="child::node()"/>
            </p>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>