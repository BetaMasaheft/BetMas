<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    <xsl:output encoding="UTF-8" method="xml"/>
    <xsl:output indent="yes"/>

    <xsl:template match="t:body">
        <div xlmns="http://www.tei-c.org/ns/1.0" type="edition" xml:lang="gez">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="t:div">
        <div n="{@n}" type="textpart" subtype="{@type}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="t:p">
        <ab>
            <xsl:variable name="text">
                <xsl:apply-templates/>
            </xsl:variable>
            <xsl:value-of select="replace(normalize-space($text), ' ።', '።')"/>
            <xsl:text/>
        </ab>
    </xsl:template>
    
    <xsl:template match="t:f[not(@name = 'fidäl')]"/>
   
    <xsl:template match="t:fs">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:f[@name = 'fidäl']">
        <xsl:choose>
            <xsl:when test="following-sibling::t:f[@name = 'analysis']//t:f[. = 'Punctuation']">
                <xsl:value-of select="text()"/>
            </xsl:when>
           <!-- <xsl:when test="following-sibling::t:f[@name = 'analysis']//t:f[. = 'Cardinal Numeral']">
                <xsl:value-of select="text()"/>
            </xsl:when>-->
            <xsl:otherwise>
                <xsl:variable name="separator" select="if(parent::t:fs/following-sibling::t:fs[position()=1]//t:f[@name = 'analysis']//t:f[. = 'Punctuation']) then () else '፡'"/>
                <xsl:value-of select="concat(text(), $separator)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>