<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:foliation">
        <h3>Foliation <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit
            <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
</xsl:stylesheet>