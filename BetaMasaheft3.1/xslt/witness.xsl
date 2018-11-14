<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:witness">
        <li>
            <xsl:choose>
                <xsl:when test="@corresp">
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
                    <xsl:choose>
                        <xsl:when test="text()">
                            <a href="{if(@type='external' and @facs) then @facs else @corresp}" class="MainTitle" data-value="{@corresp}" property="http://purl.org/dc/elements/1.1/source" resource="http://betamasaheft.eu/{@corresp}">
                                <xsl:value-of select="@corresp"/>
                            </a>
                            <xsl:if test="contains(@corresp, '#')">
                                <xsl:value-of select="substring-after(@corresp, '#')"/>
                            </xsl:if>
                            <xsl:text>:  </xsl:text>
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{if(@type='external' and @facs) then @facs else @corresp}" class="MainTitle" data-value="{if(contains(@corresp, '#')) then substring-before(@corresp, '#') else @corresp}" property="http://purl.org/dc/elements/1.1/source" resource="http://betamasaheft.eu/{@corresp}">
                                <xsl:if test="@facs"><xsl:attribute name="data-location"><xsl:value-of select="@facs"/></xsl:attribute></xsl:if>
                                <xsl:if test="t:ptr/@target"><xsl:attribute name="data-manifest"><xsl:value-of select="t:ptr/@target"/></xsl:attribute></xsl:if>
                                <xsl:if test="@xml:id">
                                    <xsl:attribute name="id">
                                        <xsl:value-of select="@xml:id"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="@corresp"/>
                            </a>
                            <xsl:text> </xsl:text>
                            <xsl:if test="contains(@corresp, '#')">
                                <xsl:value-of select="substring-after(@corresp, '#')"/>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@corresp"/>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="@cert = 'low'">
                <xsl:text> ? </xsl:text>
            </xsl:if>
            <xsl:if test="@facs and not(@type='external')">
                <a href="{@facs}"> [link]</a>
            </xsl:if>
        </li>
    </xsl:template>
</xsl:stylesheet>