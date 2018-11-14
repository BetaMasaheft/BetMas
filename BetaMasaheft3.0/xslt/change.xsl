<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="//t:revisionDesc">
        <xsl:for-each select="t:change">
            <xsl:sort select="@when" order="descending"/>
            <li>
                <xsl:apply-templates select="@who"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="."/>
                <xsl:text> </xsl:text>
                <xsl:variable name="date">
                    <xsl:choose>
                        <xsl:when test="contains(@when, 'T')">
                            <xsl:value-of select="substring-before(@when, 'T')"/>
                        </xsl:when>
                        <xsl:when test="contains(@when, '+')">
                            <xsl:value-of select="substring-before(@when, '+')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@when"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="format-date($date, '[D].[M].[Y]')"/>
            </li>
        </xsl:for-each>
    </xsl:template>
    <xsl:include href="editorKey.xsl"/>
</xsl:stylesheet>