<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="@who[parent::t:change]">
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
            <xsl:when test=". = 'AA'">Abreham Adugna</xsl:when>
            <xsl:when test=". = 'EG'">Ekaterina Gusarova</xsl:when>
            <xsl:when test=". = 'IR'">Irene Roticiani</xsl:when>
            <xsl:when test=". = 'MB'">Maria Bulakh</xsl:when>
            <xsl:when test=". = 'VR'">Veronika Roth</xsl:when>
            <xsl:when test=". = 'MK'">Magdalena Krzyzanowska</xsl:when>
            <xsl:when test=". = 'DE'">Daria Elagina</xsl:when>
            <xsl:when test=". = 'NV'">Nafisa Valieva</xsl:when>
            <xsl:when test=". = 'RHC'">Ran HaCohen</xsl:when>
            <xsl:when test=". = 'SS'">Sisay Sahile</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>