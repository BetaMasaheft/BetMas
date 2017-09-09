<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:bindingDesc">
        <h3>Binding <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit
            <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <p id="{//t:binding/t:decoNote[position() = 1]/@xml:id}">
            <xsl:apply-templates select="//t:binding/t:decoNote[@xml:id='b1']"/>
        </p>
        <xsl:if test=".//t:decoDesc[@type = 'Endbands']">
            <h4 id="{.//t:decoDesc[@type = 'Endbands']/@xml:id}">Endbands</h4>
            <p> Yes </p>
        </xsl:if>
        <xsl:if test=".//t:decoDesc[@type = 'Headbands']">
            <h4 id="{.//t:decoDesc[@type = 'Headbands']/@xml:id}">Headbands</h4>
            <p> Yes </p>
        </xsl:if>
        <xsl:if test=".//t:decoDesc[@type = 'Tailbands']">
            <h4 id="{.//t:decoDesc[@type = 'Tailbands']/@xml:id}">Tailbands</h4>
            <p> Yes </p>
        </xsl:if>
        <xsl:if test="t:binding/t:decoNote[@type = 'Other']">
            <h4 id="{t:binding/t:decoNote[@type = 'Other']/@xml:id}">Binding decoration</h4>
            <p>
                <xsl:value-of select="t:binding/t:decoNote[@type = 'Other']"/>
            </p>
        </xsl:if>
        <h4 id="{t:binding/t:decoNote[@type = 'bindingMaterial']/@xml:id}">Binding material</h4>
        <p>
            <xsl:value-of select="t:binding/t:decoNote[@type = 'bindingMaterial']/t:material/@key"/>
        </p>
        <h4>Original binding</h4>
        <p>
            <xsl:value-of select="t:binding/@contemporary"/>
        </p>
    </xsl:template>
</xsl:stylesheet>