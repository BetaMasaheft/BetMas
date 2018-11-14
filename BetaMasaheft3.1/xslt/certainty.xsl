<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:certainty">
        <!--
        need to add support for `certainty` to specify for example that the uncertainty lies with the completeness and not with the title.
        
        e.g. 
        
        <title type="Complete" ref="LIT1716Kidanz"><certainty locus="value" match="../@type" cert="low"></title>
        
        instead of
        
        <title type="Complete" cert="low" ref="LIT1716Kidanz"/>-->
        <xsl:variable name="match">
            <xsl:choose>
                <xsl:when test="@match = '..'">element <xsl:value-of select="parent::t:*/name()"/>
                </xsl:when>
                <xsl:when test="starts-with(@match, '../@')">element <xsl:value-of select="parent::t:*/name()"/>'s attribute <xsl:value-of select="substring-after(@match, '../@')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@match"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="cert" select="@cert"/>
        <xsl:variable name="alternative" select="@assertedValue"/>
        <xsl:variable name="resp" select="@resp"/>
        <xsl:variable name="statement">
            <xsl:choose>
                <xsl:when test="@cert and not(@resp) and not(@assertedValue)">
                    <xsl:value-of select="concat(' is ', $cert, '.')"/>
                </xsl:when>
                <xsl:when test="@resp and @assertedValue">
                    <xsl:value-of select="concat(' is ', $alternative, ' according to ', $resp)"/>
                </xsl:when>
                <xsl:when test="not(@resp) and @assertedValue">
                    <xsl:value-of select="concat(' is low. It might alternatively be ', $alternative, '.')"/>
                </xsl:when>
                <xsl:when test="@resp and not(@assertedValue)">
                    <xsl:value-of select="concat(' is low. It might alternatively be according to ', $resp, ': ', t:desc)"/>
                </xsl:when>
                <xsl:otherwise><xsl:text>is not set.</xsl:text></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <a href="#" data-toggle="tooltip" title="The certainty about the {@locus} of {$match} {$statement}">
            <sup>[!]</sup>
        </a>
    </xsl:template>
</xsl:stylesheet>