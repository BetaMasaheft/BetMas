<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:template match="/">
        <div id="description" class="{if(t:TEI/@type='ins') then 'institutionView' else 'col-md-8'}">
            <h2>Names <xsl:if test="//t:place/@sameAs">
                    <xsl:variable name="sAs" select="//t:place/@sameAs"/>
                    <xsl:variable name="gnid" select="substring-after(//t:place/@sameAs, 'gn:')"/>
                    <xsl:variable name="url" select="                             if (starts-with($sAs, 'gn:')) then                                 (concat('http://www.geonames.org/', $gnid))                             else                                 concat('https://www.wikidata.org/wiki/', $sAs)"/>
                    <a href="{$url}">
                        <xsl:text> </xsl:text>
                        <span class="icon-large icon-globe"/>
                    </a>
                </xsl:if>
            </h2>
            <div class="placeNames col-md-12">
                <xsl:for-each select="//t:place/t:placeName[@xml:id]">
                    <xsl:sort select="                             if (@xml:id) then                                 @xml:id                             else                                 text()"/>
                    <xsl:variable name="id" select="@xml:id"/>
                    <div class="col-md-12" rel="http://lawd.info/ontology/hasName">
                    <p class="lead">
                        <xsl:if test="@xml:id">
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                        </xsl:if>
                        <i class="fa fa-chevron-right" aria-hidden="true"/>
                    <xsl:text> </xsl:text>
                        <xsl:if test="@type">
                            <xsl:value-of select="concat(@type, ': ')"/>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="@ref">
                                <a href="{@ref}" target="_blank" property="http://lawd.info/ontology/primaryForm">
                                    <xsl:value-of select="text()"/>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="text()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:if test="@xml:lang">
                            <sup>
                                <xsl:value-of select="@xml:lang"/>
                            </sup>
                        </xsl:if>
                        <xsl:apply-templates select="./t:note"/>
                        <xsl:if test="//t:place/t:placeName[contains(@corresp, $id)]">
                            <xsl:text> (</xsl:text>
                            <xsl:for-each select="//t:place/t:placeName[substring-after(@corresp, '#') = $id]">
                                <xsl:sort/>
                                
                            <xsl:apply-templates/>
                                <xsl:if test="@xml:lang">
                                    <sup>
                                        <xsl:value-of select="@xml:lang"/>
                                    </sup>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                        </xsl:if>
                        </p>
                    </div>
                </xsl:for-each>
                <xsl:if test="//t:place/t:placeName[not(@xml:id or @corresp)]">
                    <xsl:for-each select="//t:place/t:placeName[not(@xml:id or @corresp)]">
                        <xsl:sort/>
                        <div class="col-md-12" rel="http://lawd.info/ontology/hasName">
                        <p>
                            <xsl:if test="@type">
                                <xsl:value-of select="concat(@type, ': ')"/>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="@ref">
                                    <a href="{@ref}" target="_blank" property="http://lawd.info/ontology/variantForm">
                                        <xsl:value-of select="."/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    
                                <xsl:apply-templates/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@xml:lang">
                                <sup>
                                    <xsl:value-of select="@xml:lang"/>
                                </sup>
                            </xsl:if>
                        </p>
                        </div>
                    </xsl:for-each>
                </xsl:if>
            </div>
            <xsl:if test="//t:location[@type='relative']">
            <h2>Location</h2>
            <xsl:for-each select="//t:location[@type='relative']">
                <p>
                        <xsl:apply-templates select="."/>
                    </p>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="//t:ab[@type = 'appellations'][child::*]">
                <h2>Appellations</h2>
                <p>
                    <p>
                        <xsl:apply-templates select="//t:ab[@type = 'appellations']"/>
                    </p>
                </p>
            </xsl:if>
            <xsl:if test="//t:*[@type = 'foundation']">
                <h3>Foundation</h3>
                <xsl:if test="//t:date[@type = 'foundation']">
                    <p>
                        <b>Date of foundation: </b>
                        <xsl:value-of select="//t:date[@type = 'foundation']"/>
                    </p>
                </xsl:if>
                <xsl:if test="//t:desc[@type = 'foundation']">
                    <p>
                        <xsl:apply-templates select="//t:desc[@type = 'foundation']"/>
                    </p>
                </xsl:if>
            </xsl:if>
            <xsl:if test="//t:ab[@type = 'history']">
                <h3>History</h3>
                <p>
                    <xsl:apply-templates select="//t:ab[@type = 'history']"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:ab[@type = 'description']">
                <h3>Description</h3>
                <p>
                    <xsl:apply-templates select="//t:ab[@type = 'description']"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:ab[@type = 'tabot']">
                <h3>Tābots</h3>
                <p>
                    <xsl:apply-templates select="//t:ab[@type = 'tabot']"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:listBibl">  <h2>Bibliography</h2>
            <xsl:apply-templates select="//t:listBibl"/>
            </xsl:if>
            <xsl:if test="//t:note[not(descendant::t:ab)][not(parent::t:placeName)][not(@source)]">
                <h2>Other</h2>
            <p>
                <xsl:apply-templates select="//t:place/t:note[not(descendant::t:ab)]"/>
            </p>
            </xsl:if>
            
            <button class="btn btn-primary" id="showattestations" data-value="place" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
            <div id="allattestations" class="col-md-12"/>
            
        </div>
        <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:include href="resp.xsl"/>
    <!-- elements templates-->
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="editorKey.xsl"/>
    <xsl:include href="msselements.xsl"/>
   <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="faith.xsl"/>
    <xsl:include href="provenance.xsl"/>
    <xsl:include href="handDesc.xsl"/>
    <xsl:include href="msContents.xsl"/>
    <xsl:include href="history.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    <!--    elements with references-->
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <!-- includes also region, country and settlement-->
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
    <!--produces also the javascript for graph-->
</xsl:stylesheet>