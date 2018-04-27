<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:template match="t:handDesc">
        <h4>Hand<xsl:if test="count(.//t:handNote) gt 1">s</xsl:if>
        </h4>
        <div>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
</xsl:stylesheet>