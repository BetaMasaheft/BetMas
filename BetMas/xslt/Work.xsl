<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:template match="/">
        <div id="MainData" class="w3-twothird">
        <div id="description">
            <xsl:if test="count(//t:titleStmt/t:title) gt 1">
                <h2>Titles</h2>
                <ul>
                    <xsl:for-each select="//t:titleStmt/t:title[@xml:id]">
                        <xsl:sort select="if (@xml:id) then @xml:id else text()"/>
                        <xsl:variable name="id" select="@xml:id"/>
                        <li property="http://purl.org/dc/elements/1.1/title">
                            <xsl:if test="@xml:id">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="@xml:id"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:if test="@type">
                                <xsl:value-of select="concat(@type, ': ')"/>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="@ref">
                                    <a href="{@ref}" target="_blank">
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
                            <xsl:if test="//t:titleStmt/t:title[@corresp]">
                                <xsl:text> (</xsl:text>
                                <xsl:for-each select="//t:titleStmt/t:title[substring-after(@corresp, '#') = $id]">
                                    <xsl:sort select="if (@xml:lang) then @xml:lang else ()" order="descending"/>
                                    <xsl:value-of select="."/>
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
                        </li>
                    </xsl:for-each>
                    <xsl:if test="//t:titleStmt/t:title[not(@xml:id or @corresp)]">
                        <xsl:for-each select="//t:titleStmt/t:title[not(@xml:id or @corresp)]">
                            <xsl:sort/>
                            <li>
                                <xsl:if test="@type">
                                    <xsl:value-of select="concat(@type, ': ')"/>
                                </xsl:if>
                                <xsl:choose>
                                    <xsl:when test="@ref">
                                        <a href="{@ref}" target="_blank">
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
                            </li>
                        </xsl:for-each>
                    </xsl:if>
                </ul>
            </xsl:if>
            <xsl:if test="//t:author |//t:relation[@name='saws:isAttributedToAuthor']|//t:relation[@name='dcterms:creator']">
                <h2>Author</h2>
                <ul>
                    <xsl:for-each select="//t:relation[@name='saws:isAttributedToAuthor']|//t:relation[@name='dcterms:creator']">
                        <xsl:variable name="parentname">
                            <xsl:if test="ancestor::t:div[@xml:id]">
                                <a class="page-scroll MainTitle" target="_blank" href="/text/{ancestor::t:TEI/@xml:id}#{ancestor::t:div[@xml:id][1]/@xml:id}" data-value="{ancestor::t:TEI/@xml:id}#{ancestor::t:div[@xml:id][1]/@xml:id}">
                                <xsl:value-of select="ancestor::t:div[@xml:id][1]/@xml:id"/>
                            </a>: </xsl:if>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="contains(@passive,' ')">
                                <xsl:for-each select="tokenize(normalize-space(@passive),' ')">
                                    <li>
                                        <xsl:copy-of select="$parentname"/>
                                        <xsl:variable name="filename">
                                            <xsl:choose>
                                                <xsl:when test="contains(., '#')">
                                                    <xsl:value-of select="substring-before(., '#')"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="."/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <a href="{.}" class="persName">
                                            <span class="MainTitle" data-value="{.}"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                                <xsl:if test="@name='saws:isAttributedToAuthor'">
                                    <span class="label label-warning">attributed</span>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <li>
                                    <xsl:copy-of select="$parentname"/>
                                    <xsl:variable name="filename">
                                        <xsl:choose>
                                            <xsl:when test="contains(@passive, '#')">
                                                <xsl:value-of select="substring-before(@passive, '#')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="@passive"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <a href="{@passive}" data-value="{@passive}" class="MainTitle"/>
                                    <xsl:variable name="id" select="generate-id()"/>
                                    <a id="{$id}Ent{$filename}relations">
                                        <xsl:text>  </xsl:text>
                                        <span class="glyphicon glyphicon-hand-left"/>
                                    </a>
                                    <xsl:if test="@name='saws:isAttributedToAuthor'">
                                        <span class="label label-warning">attributed</span>
                                    </xsl:if>
                                    <xsl:text>. </xsl:text>
                                        <xsl:if test="t:desc">
                                        <xsl:apply-templates select="t:desc"/>
                                    </xsl:if>
                                    
                                    
                                </li>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <xsl:for-each select="//t:author">
                        <li>
                            <xsl:apply-templates/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
            <xsl:if test="//t:abstract">
                <h2>General description</h2>
                <p>
                    <xsl:apply-templates select="//t:abstract"/>
                </p>
            </xsl:if>
            
            <xsl:if test="//t:extent">
                <p>
                    <b>Extent: </b>
                    <xsl:apply-templates select="//t:extent"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:creation">
                <h2>Date</h2>
                <p>
                    <xsl:apply-templates select="//t:creation"/>
                    <xsl:if test="//t:creation/@evidence">(<xsl:value-of select="//t:creation/@evidence"/>)</xsl:if>
                </p>
            </xsl:if>
            <xsl:if test="//t:listWit">
                <h2>Witnesses</h2>
                <p class="alert alert-info">The following manuscripts are reported in this record as witnesses of the source of the information or the edition here encoded. 
                    Please check the <a href="#computedWitnesses">box below</a> for a live updated list of manuscripts pointing to this record.</p>
                <xsl:apply-templates select="//t:listWit[not(parent::t:listWit)]"/>
            </xsl:if>
            <xsl:if test="//t:sourceDesc/t:p">
                <xsl:apply-templates select="//t:sourceDesc/t:p"/>
            </xsl:if>
            
            <xsl:if test="//t:listBibl[@type='clavis']">
                <div id="clavisbibliography">
                    <xsl:apply-templates select="//t:listBibl[@type='clavis']"/>
                </div>
            </xsl:if>
            <xsl:if test="//t:div[@type='bibliography']/t:listBibl">
                <div id="bibliography">
                    <xsl:apply-templates select="//t:div[@type='bibliography']/t:listBibl"/>
                </div>
            </xsl:if>
            <xsl:if test="//t:publicationStmt">
                <div class="col-md-12" id="publicationStmt">
                    <h2>Publication Statement</h2>
                    <xsl:apply-templates select="//t:publicationStmt"/>
                </div>
            </xsl:if>
            <xsl:if test="//t:encodingDesc">
                <div class="col-md-12" id="encodingDesc">
                    <h2>Encoding Description</h2>
                    <xsl:apply-templates select="//t:encodingDesc"/>
                </div>
            </xsl:if>
            <xsl:if test="//t:editionStmt">
                <div class="col-md-12" id="editionStmt">
                    <h2>Edition Statement</h2>
                    <xsl:apply-templates select="//t:editionStmt"/>
                </div>
            </xsl:if>
            <xsl:if test="//t:div[@type='edition']//t:ab//text()">
                <a class="w3-button w3-gray w3-large" target="_blank" href="{concat('http://voyant-tools.org/?input=https://betamasaheft.eu/works/',string(t:TEI/@xml:id),'.xml')}">Voyant</a>
            </xsl:if>
            <button class="w3-button w3-red w3-large" id="showattestations" data-value="work" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
            <div id="allattestations" class="col-md-12"/>
            <!--<xsl:if test="//t:body[t:div[@type='edition'][t:ab or t:div[@type='textpart']]]">
                <div class="row-fluid well" id="textpartslist">
                    <h4>Text Parts</h4>
                    <xsl:apply-templates select="//t:div[@xml:id][t:label]"/>
                </div>
            </xsl:if>-->
        </div>
        </div>
            <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
        <xsl:call-template name="calendar">
            <xsl:with-param name="dates" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="t:listWit">
        <xsl:if test="@rend='edition'">
            <b>Manuscripts used in this edition</b>
        </xsl:if>
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    
    
    <!-- elements templates-->
    <xsl:include href="resp.xsl"/>
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="msselements.xsl"/> <!--includes a series of small templates for elements in manuscript entities-->
    <xsl:include href="witness.xsl"/>
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