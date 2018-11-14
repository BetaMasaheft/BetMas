<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:repository" mode="title">
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
        <a xmlns="http://www.w3.org/1999/xhtml" href="{@ref}">
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <span class="MainTitle" data-value="{$filename}"/>
                    <xsl:if test="contains(@ref, '#')">
                        <xsl:value-of select="concat(', ',substring-after(@ref, '#'))"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
</xsl:stylesheet>