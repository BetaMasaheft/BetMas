<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:title">
        <xsl:value-of select="doc(concat('https://betamasaheft.aai.uni-hamburg.de/api/',@ref,'/titlexml'))//t:title"/>
    </xsl:template>
    <xsl:template match="t:ref">
        <xsl:value-of select="doc(concat('https://betamasaheft.aai.uni-hamburg.de/api/',@corresp,'/titlexml'))//t:title"/>
    </xsl:template>
</xsl:stylesheet>