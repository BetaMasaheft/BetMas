<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:origDate | t:floruit | t:birth | t:death">
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
        <xsl:if test="@evidence">
            <xsl:value-of select="concat(' (',@evidence,')')"/>
        </xsl:if>
        <xsl:if test="@cert = 'low'">?</xsl:if>
        <xsl:if test="child::t:* or text()">
            <xsl:apply-templates/>
        </xsl:if>
    </xsl:template>
    <xsl:include href="divEdition.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
</xsl:stylesheet>