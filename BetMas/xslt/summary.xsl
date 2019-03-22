<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:summary[not(parent::t:decoDesc)]">
        <xsl:variable name="id" select="ancestor::t:*[@xml:id][1]/@xml:id"/>
        <h3>Summary<xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
<!--                    ms part matches only ms part, not msfrag. -->
                    <a class="page-scroll" href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <div class="w3-bar w3-black">
            <button class="w3-bar-item w3-button w3-half" onclick="openSummary('extracted{$id}')">
           Extracted
            </button>
            <button class="w3-bar-item w3-button w3-half" onclick="openSummary('given{$id}')">
           Given
            </button>
        </div>
        <div class="summaryText" id="given{$id}">
                <xsl:choose>
                    <xsl:when test="ancestor::t:TEI//@form = 'Inscription'"/>
                    <xsl:otherwise>
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates/>
            </div>
            <div class="summaryText" id="extracted{$id}">
                <xsl:choose>
                    <xsl:when test="ancestor::t:TEI//@form = 'Inscription'">
                        <xsl:attribute name="style">display:none</xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
                <ol class="summary">
                    <xsl:choose>
                        <xsl:when test="ancestor::t:msPart">
                            <xsl:for-each select="ancestor::t:msPart//t:msItem[not(parent::t:msItem)]">
                                <xsl:sort select="position()"/>
                                <li>
                                    <a class="page-scroll" href="#{@xml:id}">
                                        <xsl:value-of select="@xml:id"/>
                                    </a>
                                    <xsl:if test="./t:locus">
                                        <xsl:text> (</xsl:text>
                                        <xsl:apply-templates select="./t:locus">
                                            <xsl:with-param name="text" tunnel="yes">only</xsl:with-param>
                                        </xsl:apply-templates>
                                        <xsl:text>)</xsl:text>
                                    </xsl:if>
                                    <xsl:text>, </xsl:text>
                                    <xsl:apply-templates select="./t:title"/>
                                    <xsl:if test="t:msItem">
                                        <ol class="summary">
                                            <xsl:for-each select="t:msItem">
                                                <xsl:sort select="position()"/>
                                                <li>
                                                    <a class="page-scroll" href="#{@xml:id}">
                                                        <xsl:value-of select="@xml:id"/>
                                                    </a>
                                                    <xsl:if test="./t:locus">
                                                        <xsl:text> (</xsl:text>
                                                        <xsl:apply-templates select="./t:locus">
                                                            <xsl:with-param name="text" tunnel="yes">only</xsl:with-param>
                                                        </xsl:apply-templates>
                                                        <xsl:text>)</xsl:text>
                                                    </xsl:if>
                                                    <xsl:text>, </xsl:text>
                                                    <xsl:apply-templates select="./t:title"/>
                                                </li>
                                            </xsl:for-each>
                                        </ol>
                                    </xsl:if>
                                </li>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="ancestor::t:msDesc//t:msItem[not(parent::t:msItem)]">
                                <xsl:sort select="position()"/>
                                <li>
                                    <a class="page-scroll" href="#{@xml:id}">
                                        <xsl:value-of select="@xml:id"/>
                                    </a>
                                    <xsl:if test="./t:locus">
                                        <xsl:text> (</xsl:text>
                                        <xsl:apply-templates select="./t:locus">
                                            <xsl:with-param name="text" tunnel="yes">only</xsl:with-param>
                                        </xsl:apply-templates>
                                        <xsl:text>)</xsl:text>
                                    </xsl:if>
                                    <xsl:text>, </xsl:text>
                                    <xsl:apply-templates select="./t:title"/>
                                    <xsl:if test="t:msItem">
                                        <ol class="summary">
                                            <xsl:for-each select="t:msItem">
                                                <xsl:sort select="position()"/>
                                                <li>
                                                    <a class="page-scroll" href="#{@xml:id}">
                                                        <xsl:value-of select="@xml:id"/>
                                                    </a>
                                                    <xsl:if test="./t:locus">
                                                        <xsl:text> (</xsl:text>
                                                        <xsl:apply-templates select="./t:locus">
                                                            <xsl:with-param name="text" tunnel="yes">only</xsl:with-param>
                                                        </xsl:apply-templates>
                                                        <xsl:text>)</xsl:text>
                                                    </xsl:if>
                                                    <xsl:text>, </xsl:text>
                                                    <xsl:apply-templates select="./t:title"/>
                                                </li>
                                            </xsl:for-each>
                                        </ol>
                                    </xsl:if>
                                </li>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </ol>
            </div>
        
    </xsl:template>
</xsl:stylesheet>