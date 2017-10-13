<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:collection" mode="title">
        <p>Collection:  <xsl:value-of select="."/>
        </p>
    </xsl:template>
    <xsl:template match="t:altIdentifier" mode="title">
        <p>Other identifiers: <xsl:for-each select="t:idno">
                <xsl:sort/>
                <xsl:value-of select="concat(., ' ')"/>
            </xsl:for-each>
        </p>
    </xsl:template>
</xsl:stylesheet>