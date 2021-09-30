<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    <xsl:output encoding="UTF-8" method="xml"/>
    
    <xsl:output indent="yes" method="xml"/>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="t:taxonomy">
    <xsl:copy>
        <xsl:apply-templates/>
    </xsl:copy>
</xsl:template>

<xsl:template match="t:category">
    <xsl:copy>
        <xsl:if test="t:catDesc">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="t:catDesc/text()"/>
                </xsl:attribute>
            </xsl:if>
        <xsl:if test="t:catDesc">
                <xsl:attribute name="corresp">
                    <xsl:value-of select="concat('https://betamasaheft.eu/authority-files/', t:catDesc/text(), '/main')"/>
                </xsl:attribute>
            </xsl:if>
        <xsl:apply-templates/>
    </xsl:copy>
</xsl:template>
    
<xsl:template match="t:catDesc">
    <xsl:copy>
        <xsl:value-of select="document(concat('https://betamasaheft.eu/', text(), '.xml'))//t:titleStmt/t:title[1]"/>
    </xsl:copy>
</xsl:template>
    
   
</xsl:stylesheet>