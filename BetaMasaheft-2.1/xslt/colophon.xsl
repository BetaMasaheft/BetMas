<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:colophon">
        <hr class="colophon"/>
        <h3 id="{@xml:id}">
            <xsl:choose>
                <xsl:when test="@type">
                    <xsl:value-of select="@type"/>
                </xsl:when>
                <xsl:otherwise>Colophon</xsl:otherwise>
            </xsl:choose>
        </h3>
        <p>
            <xsl:apply-templates select="descendant::t:locus"/>
        </p>
        <p>
            <xsl:apply-templates select="node() except (t:note | t:foreign | t:listBibl | t:locus)"/>
        </p>
        <xsl:if test="t:foreign">
            <p>
                <b>Translation <xsl:value-of select="t:foreign/@xml:lang"/>: </b>
                <xsl:value-of select="t:foreign"/>
            </p>
        </xsl:if>
        <xsl:if test="descendant::t:note">
            <p>
                <xsl:apply-templates select="descendant::t:note"/>
            </p>
        </xsl:if>
        <xsl:if test="t:listBibl">
            <xsl:apply-templates select="t:listBibl"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>