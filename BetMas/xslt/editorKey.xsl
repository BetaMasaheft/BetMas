<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="@who[parent::t:change]">
        <xsl:variable name="list" select="doc('xmldb:exist:///db/apps/BetMas/editors.xml')"/>
        <xsl:value-of select="$list//t:item[@xml:id=.]/text()"/>
      </xsl:template>
</xsl:stylesheet>