<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:funct="my.funct" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:function name="funct:date">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, '\d{4}-\d{2}-\d{2}')">
                <xsl:value-of select="format-date(xs:date($date), '[D]-[M]-[Y0001]', 'en', 'AD', ())"/>
            </xsl:when><xsl:when test="matches($date, '\d{4}-\d{2}')">
                <xsl:variable name="monthnumber" select="substring-after($date, '-')"/>
                <xsl:variable name="monthname">
                    <xsl:choose>
                        <xsl:when test="$monthnumber = '01'">January</xsl:when>
                        <xsl:when test="$monthnumber = '02'">February</xsl:when>
                        <xsl:when test="$monthnumber = '03'">March</xsl:when>
                        <xsl:when test="$monthnumber = '04'">April</xsl:when>
                        <xsl:when test="$monthnumber = '05'">May</xsl:when>
                        <xsl:when test="$monthnumber = '06'">June</xsl:when>
                        <xsl:when test="$monthnumber = '07'">July</xsl:when>
                        <xsl:when test="$monthnumber = '08'">August</xsl:when>
                        <xsl:when test="$monthnumber = '09'">September</xsl:when>
                        <xsl:when test="$monthnumber = '10'">October</xsl:when>
                        <xsl:when test="$monthnumber = '11'">November</xsl:when>
                        <xsl:when test="$monthnumber = '12'">December</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="concat(replace(substring-after($date, '-'), $monthnumber, $monthname), ' ', substring-before($date, '-'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="format-number($date, '####')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="funct:datepicker">
        <xsl:param name="element"/>
        <xsl:choose>
            <xsl:when test="$element/@notBefore or $element/@notAfter">
                <xsl:if test="not($element/@notBefore)">Before </xsl:if>
                <xsl:if test="not($element/@notAfter)">After </xsl:if>
                <xsl:if test="$element/@notBefore">
                    <xsl:value-of select="funct:date($element/@notBefore)"/>
                </xsl:if>
                <xsl:if test="$element/@notBefore and $element/@notAfter">
                    <xsl:text>-</xsl:text>
                </xsl:if>
                <xsl:if test="$element/@notAfter">
                    <xsl:value-of select="funct:date($element/@notAfter)"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="funct:date($element/@when)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$element/@cert">
            <xsl:value-of select="concat(' (certainty: ', $element/@cert, ')')"/>
        </xsl:if>
    </xsl:function>
    <xsl:template match="/">
            <xsl:apply-templates/>
        
    </xsl:template>
       
    <xsl:include href="ref.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
</xsl:stylesheet>