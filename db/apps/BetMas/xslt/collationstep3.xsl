<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b>July 2, 2014</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Dot Porter</xd:p>
            <xd:p>This document takes as its input the output from process4.xsl. It adds folio /
        page numbers to <right/> and <left/>. </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="step2">
        <xsl:param name="step2ed" tunnel="yes"/>
        <xsl:for-each select="t:quire">
            <quire>
                <xsl:attribute name="contoreale">
                    <xsl:value-of select="@contoreale"/>
                </xsl:attribute>
                <xsl:attribute name="quireid">
                    <xsl:value-of select="@quireid"/>
                </xsl:attribute>
                <xsl:attribute name="rend">
                    <xsl:value-of select="@rend"/>
                </xsl:attribute>
                <xsl:attribute name="corresp">
                    <xsl:value-of select="@corresp"/>
                </xsl:attribute>
                <xsl:attribute name="desc">
                    <xsl:value-of select="@desc"/>
                </xsl:attribute>
                <xsl:attribute name="n">
                    <xsl:value-of select="@n"/>
                </xsl:attribute>
                <xsl:attribute name="positions">
                    <xsl:value-of select="@positions"/>
                </xsl:attribute>
                <units>
                    <xsl:apply-templates select="t:units" mode="step1"/>
                </units>
                <xsl:copy-of select="t:text"/>
            </quire>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:units" mode="step1">
        <xsl:for-each select="t:unit">
            <unit>
                <xsl:attribute name="n" select="@n"/>
                <inside>
                    <xsl:apply-templates select="t:inside" mode="step1"/>
                </inside>
                <outside>
                    <xsl:apply-templates select="t:outside" mode="step1"/>
                </outside>
            </unit>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:inside" mode="step1">
        <xsl:apply-templates mode="step1"/>
    </xsl:template>
    <xsl:template match="t:outside" mode="step1">
        <xsl:apply-templates mode="step1"/>
    </xsl:template>
    <xsl:template match="t:left" mode="step1">
        <xsl:variable name="the_pos" select="@pos"/>
        <xsl:choose>
            <xsl:when test="contains(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-')">
                <xsl:variable name="first_number" select="tokenize(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-') [position() = 1]"/>
                <xsl:variable name="second_number" select="tokenize(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-') [position() = 2]"/>
                <xsl:choose>
                    <xsl:when test="parent::t:inside">
                        <left>
                            <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                                <xsl:attribute name="folNo">
                                    <xsl:value-of select="$second_number"/>
                                </xsl:attribute>
                                <xsl:attribute name="mode">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                                </xsl:attribute>
                                <xsl:attribute name="single">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="pos">
                                <xsl:value-of select="@pos"/>
                            </xsl:attribute>
<!--              THIS IS NOT WORKING-->
                        </left>
                    </xsl:when>
                    <xsl:when test="parent::t:outside">
                        <left>
                            <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                                <xsl:attribute name="folNo">
                                    <xsl:value-of select="$first_number"/>
                                </xsl:attribute>
                                <xsl:attribute name="mode">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                                </xsl:attribute>
                                <xsl:attribute name="single">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="pos">
                                <xsl:value-of select="@pos"/>
                            </xsl:attribute>
                        </left>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <left>
                    <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                        <xsl:attribute name="folNo">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number"/>
                            <xsl:choose>
                                <xsl:when test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode='missing'"/>
                                <xsl:otherwise>
                                    <xsl:text>v</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="mode">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                        </xsl:attribute>
                        <xsl:attribute name="single">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:attribute name="pos">
                        <xsl:value-of select="@pos"/>
                    </xsl:attribute>
                </left>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:right" mode="step1">
        <xsl:variable name="the_pos" select="@pos"/>
        <xsl:choose>
            <xsl:when test="contains(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-')">
                <xsl:variable name="first_number" select="tokenize(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-') [position() = 1]"/>
                <xsl:variable name="second_number" select="tokenize(ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number,'-') [position() = 2]"/>
                <xsl:choose>
                    <xsl:when test="parent::t:outside">
                        <right>
                            <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                                <xsl:attribute name="folNo">
                                    <xsl:value-of select="$first_number"/>
                                </xsl:attribute>
                                <xsl:attribute name="mode">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                                </xsl:attribute>
                                <xsl:attribute name="single">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="pos">
                                <xsl:value-of select="@pos"/>
                            </xsl:attribute>
                        </right>
                    </xsl:when>
                    <xsl:when test="parent::t:inside">
                        <right>
                            <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                                <xsl:attribute name="folNo">
                                    <xsl:value-of select="$second_number"/>
                                </xsl:attribute>
                                <xsl:attribute name="mode">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                                </xsl:attribute>
                                <xsl:attribute name="single">
                                    <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:attribute name="pos">
                                <xsl:value-of select="@pos"/>
                            </xsl:attribute>
                        </right>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <right>
                    <xsl:if test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number">
                        <xsl:attribute name="folNo">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@folio_number"/>
                            <xsl:choose>
                                <xsl:when test="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode='missing'"/>
                                <xsl:otherwise>
                                    <xsl:text>r</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:attribute name="mode">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@mode"/>
                        </xsl:attribute>
                        <xsl:attribute name="single">
                            <xsl:value-of select="ancestor::t:quire/t:leaves/t:leaf[@position=$the_pos]/@single"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:attribute name="pos">
                        <xsl:value-of select="@pos"/>
                    </xsl:attribute>
                </right>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>