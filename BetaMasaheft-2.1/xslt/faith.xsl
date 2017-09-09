<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:template match="t:faith">
        <xsl:choose>
            <xsl:when test="text()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@type='EOTC'">Ethiopian Orthodox Tewahedo Church</xsl:when>
                    <xsl:when test="@type='Christianity'">Christian</xsl:when>
                    <xsl:when test="@type='Catholicism'">Christian Catholic</xsl:when>
                    <xsl:when test="@type='Protestantism'">Christian Protestant</xsl:when>
                    <xsl:when test="@type='Anglican'">Christian Anglican</xsl:when>
                    <xsl:when test="@type='Coptic'">Christian Coptic</xsl:when>
                    <xsl:when test="@type='Orthodox'">Christian Orthodox</xsl:when>
                    <xsl:when test="@type='Syriac'"> Christian Orthodox Syriac</xsl:when>
                    <xsl:when test="@type='Greek'">Christian Orthodox Greek</xsl:when>
                    <xsl:when test="@type='Russian'">Christian Orthodox Russian</xsl:when>
                    <xsl:when test="@type='Armenian'">Christian Orthodox Armenian</xsl:when>
                    <xsl:when test="@type='Islam'">Islam</xsl:when>
                    <xsl:when test="@type='Sunni'">Sunni Islam</xsl:when>
                    <xsl:when test="@type='Shia'">Shia Islam</xsl:when>
                    <xsl:when test="@type='Judaism'">Judaism</xsl:when>
                    <xsl:when test="@type='Ethiopian'">Ethiopian</xsl:when>
                    <xsl:when test="@type='Traditional'">Traditional</xsl:when>
                    <xsl:when test="@type='Aksumite'">Aksumite</xsl:when>
                    <xsl:when test="@type='Oromo'">Oromo</xsl:when>
                    <xsl:when test="@type='Gurage'">Gurage</xsl:when>
                    <xsl:otherwise>Unknown</xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>