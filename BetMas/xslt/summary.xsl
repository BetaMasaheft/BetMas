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
        <ul class="nav nav-tabs">
            <li>
                <xsl:choose>
                    <xsl:when test="ancestor::t:TEI//@form = 'Inscription'"/>
                    <xsl:otherwise>
                        <xsl:attribute name="class">active</xsl:attribute>
                    </xsl:otherwise>
                </xsl:choose>
                <a data-toggle="tab" href="#extracted{$id}">Extracted summary of contents</a>
            </li>
            <li>
                <xsl:choose>
                    <xsl:when test="ancestor::t:TEI//@form = 'Inscription'">
                        <xsl:attribute name="class">active
                </xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
                <a data-toggle="tab" href="#given{$id}">Given summary of contents</a>
            </li>
        </ul>
        <div class="tab-content">
            <div id="given{$id}">
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="ancestor::t:TEI//@form = 'Inscription'">tab-pane fade in active</xsl:when>
                        <xsl:otherwise>tab-pane fade in</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:apply-templates/>
            </div>
            <div id="extracted{$id}">
                <xsl:attribute name="class">
                    <xsl:choose>
                        <xsl:when test="ancestor::t:TEI//@form = 'Inscription'">tab-pane fade in</xsl:when>
                        <xsl:otherwise>tab-pane fade in active</xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
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
        </div>
    </xsl:template>
</xsl:stylesheet>