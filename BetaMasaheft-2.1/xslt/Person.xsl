<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="/">
        <div id="description">
            <h2>Names <xsl:if test="//t:person/@sex">
                    <xsl:choose>
                        <xsl:when test="//t:person/@sex = 1">
                            <i class="icon-large icon-male"/>
                        </xsl:when>
                        <xsl:when test="//t:person/@sex = 2">
                            <i class="icon-large icon-female"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:if>
                <xsl:if test="//t:person/@sameAs">
                    <a href="{//t:person/@sameAs}">
                        <span class="icon-large icon-vcard"/>
                    </a>
                </xsl:if>
            </h2>
            <xsl:choose>
                <xsl:when test="//t:personGrp">
                    <xsl:for-each select="//t:personGrp/t:persName[@xml:id]">
                        <xsl:sort select="if (@xml:id) then @xml:id else text()"/>
                        <xsl:variable name="id" select="@xml:id"/>
                        <li>
                            <xsl:if test="@xml:id">
                                <xsl:attribute name="id">
                                    <xsl:value-of select="@xml:id"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:if test="@type">
                                <xsl:value-of select="concat(@type, ': ')"/>
                            </xsl:if>
                            <xsl:if test="t:roleName">
                                <xsl:apply-templates select="t:roleName"/>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="@ref">
                                    <a href="{@ref}" target="_blank">
                                        <xsl:value-of select=". except t:roleName"/>
                                    </a>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select=". except t:roleName"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="@xml:lang">
                                <sup>
                                    <xsl:value-of select="@xml:lang"/>
                                </sup>
                            </xsl:if>
                            <xsl:if test="//t:personGrp/t:persName[@corresp]">
                                <xsl:text> (</xsl:text>
                                <xsl:for-each select="//t:personGrp/t:persName[substring-after(@corresp, '#') = $id]">
                                    <xsl:sort/>
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
                    <xsl:if test="//t:personGrp/t:persName[not(@xml:id or @corresp)]">
                        <xsl:for-each select="//t:personGrp/t:persName[not(@xml:id or @corresp)]">
                            <xsl:sort/>
                            <li>
                                <xsl:if test="@type">
                                    <xsl:value-of select="concat(@type, ': ')"/>
                                </xsl:if>
                                <xsl:if test="t:roleName">
                                    <xsl:apply-templates select="t:roleName"/>
                                </xsl:if>
                                <xsl:choose>
                                    <xsl:when test="@ref">
                                        <a href="{@ref}" target="_blank">
                                            <xsl:value-of select=". except t:roleName"/>
                                        </a>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select=". except t:roleName"/>
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
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="//t:person/t:persName[@xml:id]">
                        <xsl:sort select="if (@xml:id) then @xml:id else text()"/>
                        <xsl:variable name="id" select="@xml:id"/>
                        <li>
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
                            <xsl:if test="//t:person/t:persName[@corresp]">
                                <xsl:text> (</xsl:text>
                                <xsl:for-each select="//t:person/t:persName[substring-after(@corresp, '#') = $id]">
                                    <xsl:sort/>
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
                    <xsl:if test="//t:person/t:persName[not(@xml:id or @corresp)]">
                        <xsl:for-each select="//t:person/t:persName[not(@xml:id or @corresp)]">
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
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="//t:occupation">
                <h2>Occupation</h2>
              
                    <xsl:for-each select="//t:occupation">
                        <p class="lead">
                        <xsl:if test="@from or @to">
                            <xsl:value-of select="@from"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:if>
                        <xsl:apply-templates select="."/>
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="@type"/>
                        <xsl:text>)
                </xsl:text>
                </p>
                    </xsl:for-each>
            </xsl:if>
            <xsl:if test="//t:residence/text()">
                <h2>Residence</h2>
                <p class="lead">
                    <xsl:apply-templates select="//t:residence"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:faith">
                <h2>Faith</h2>
                <p class="lead">
                    <xsl:apply-templates select="//t:faith"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:nationality">
                <h2>Nationality</h2>
                <p class="lead">
                    <xsl:apply-templates select="//t:nationality"/>
                </p>
            </xsl:if>
        </div>
        <div id="history">
            <xsl:if test="//t:birth">
                <h2>Birth</h2>
                <xsl:apply-templates select="//t:birth"/>
            </xsl:if>
            <xsl:if test="//t:death">
                <h2>Death</h2>
                <p class="lead">
                    <xsl:apply-templates select="//t:death"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:floruit">
                <h2>Floruit</h2>
                <p class="lead">
                    <xsl:apply-templates select="//t:floruit"/>
                </p>
            </xsl:if>
        </div>
        <div id="bibliography">
            <xsl:apply-templates select="//t:listBibl"/>
        </div>
        <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="t:surname">
        <xsl:value-of select="."/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename">
        <xsl:value-of select="."/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:nationality">
        <xsl:choose>
            <xsl:when test="text()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:include href="resp.xsl"/>
    <!-- elements templates-->
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="editorKey.xsl"/>
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