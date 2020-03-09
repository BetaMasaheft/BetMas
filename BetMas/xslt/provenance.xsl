<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:template match="t:provenance">
        
        <h3>Provenance</h3>
        <p> <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <xsl:template match="t:acquisition">
        
        <h3>Acquisition</h3>
        <p> <xsl:apply-templates/>
        </p>
    </xsl:template>
</xsl:stylesheet>