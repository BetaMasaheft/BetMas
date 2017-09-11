<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template name="resp">
        <xsl:param name="resp"/>
        <xsl:for-each select="distinct-values(//@resp)">
            <div class="hidden">
                <span id="{.}Name">
                    <xsl:choose>
                        <xsl:when test=". = 'AB'">Alessandro Bausi</xsl:when>
                        <xsl:when test=". = 'ES'">Eugenia Sokolinski</xsl:when>
                        <xsl:when test=". = 'DN'">Denis Nosnitsin</xsl:when>
                        <xsl:when test=". = 'MV'">Massimo Villa</xsl:when>
                        <xsl:when test=". = 'DR'">Dorothea Reule</xsl:when>
                        <xsl:when test=". = 'SG'">Solomon Gebreyes</xsl:when>
                        <xsl:when test=". = 'PL'">Pietro Maria Liuzzo</xsl:when>
                        <xsl:when test=". = 'SA'">Stéphane Ancel</xsl:when>
                        <xsl:when test=". = 'SD'">Sophia Dege</xsl:when>
                        <xsl:when test=". = 'VP'">Vitagrazia Pisani</xsl:when>
                        <xsl:when test=". = 'IF'">Iosif Fridman</xsl:when>
                        <xsl:when test=". = 'SH'">Susanne Hummel</xsl:when>
                        <xsl:when test=". = 'FP'">Francesca Panini</xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="class">MainTitle</xsl:attribute>
                            <xsl:attribute name="data-value">
                                <xsl:value-of select="."/>
                            </xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </div>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>