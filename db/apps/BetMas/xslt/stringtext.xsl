<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <!--   https://github.com/BetaMasaheft/Documentation/issues/1449 -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="text()[following-sibling::t:*[1][name()='lb']]">
        <xsl:choose>
            <!--            begins with a white space, check the lb before and if that is preceded by a text ending with a separator, all is fine, else the leading space needes to be removed-->
            <xsl:when test="matches(., '[፡።፨፤]\s+$') and following-sibling::t:*[1][name()='lb']">
                <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="not(matches(., '[፡።፨፤]\s+$')) and following-sibling::t:*[1][name()='lb']">
                <xsl:value-of select="replace(.,'\s+$', '')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:gap">
        <xsl:text>[</xsl:text>
        <xsl:value-of select="string-join(@*, ' ')"/>
        <xsl:text>]</xsl:text>
    </xsl:template>
    <xsl:template match="t:supplied">
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&gt;</xsl:text>
    </xsl:template>
    <xsl:template match="t:choice">
        <xsl:apply-templates select="t:sic|t:orig"/>
    </xsl:template>
    <xsl:template match="t:del">
        ###
    </xsl:template>
    <xsl:template match="t:add">
        <xsl:text>{</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>}</xsl:text>
    </xsl:template>
    <xsl:template match="t:subst">
        <xsl:text>'</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>'</xsl:text>
    </xsl:template>
    <xsl:template match="t:hi |t:date|t:seg| t:sic">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:lb|t:pb|t:cb"/>
</xsl:stylesheet>