<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="/">
            <xsl:apply-templates/>
        
    </xsl:template>
        <xsl:template match="t:title | t:persName | t:placeName"> 
                <xsl:value-of select="@ref"/>
        </xsl:template>
        <xsl:template match="t:ref">
                <xsl:value-of select="@corresp"/>
        </xsl:template>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
</xsl:stylesheet>