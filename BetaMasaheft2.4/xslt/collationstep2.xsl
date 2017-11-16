<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b>July 2, 2014</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Dot Porter</xd:p>
            <xd:p>
                <xd:b>Modified on:</xd:b>May 4, 2015</xd:p>
            <xd:p>
                <xd:b>Modified by:</xd:b> Dot Porter</xd:p>
            <xd:p>This document takes as its input the output from the Collation Modeler.
                It generates the collation frame, with a <quire/> element for each quire, 
                <units/> containing all conjoins, and <unit/>for each bifolium / singleton, with a
                <right/> and <left/> side for each conjoin. There are attributes noting the
                position for each <right/> and <left/>, but not folio numbers.
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template name="step1">
        <xsl:param name="step1ed" tunnel="yes"/>
        <xsl:for-each select="//t:quire">
            <quire>
                <xsl:attribute name="rend">
                    <xsl:value-of select="@rend"/>
                </xsl:attribute>
                <xsl:attribute name="corresp">
                    <xsl:value-of select="@corresp"/>
                </xsl:attribute>
                <xsl:attribute name="n">
                    <xsl:value-of select="@n"/>
                </xsl:attribute>
                <xsl:variable name="positions" select="child::t:leaf[last()]/@position"/>
                <xsl:attribute name="positions">
                    <xsl:value-of select="$positions"/>
                </xsl:attribute>
                <leaves>
                    <xsl:call-template name="test"/>
                </leaves>
                <xsl:variable name="posNo">
                    <xsl:value-of select="$positions"/>
                </xsl:variable>
                <xsl:variable name="sum">
                    <xsl:value-of select="$posNo + 1"/>
                </xsl:variable>
                <xsl:variable name="div2">
                    <xsl:value-of select="$posNo div 2 - 1"/>
                </xsl:variable>
                <xsl:variable name="missing1">
                    <xsl:value-of select="t:leaf[not(@mode)][1]/@position"/>
                </xsl:variable>
                <xsl:variable name="missing2">
                    <xsl:value-of select="t:leaf[not(@mode)][2]/@position"/>
                </xsl:variable>
                <xsl:variable name="missing3">
                    <xsl:value-of select="t:leaf[not(@mode)][3]/@position"/>
                </xsl:variable>
                <xsl:variable name="missing4">
                    <xsl:value-of select="t:leaf[not(@mode)][4]/@position"/>
                </xsl:variable>
                <xsl:variable name="missing5">
                    <xsl:value-of select="t:leaf[not(@mode)][5]/@position"/>
                </xsl:variable>
                <xsl:variable name="missing6">
                    <xsl:value-of select="t:leaf[not(@mode)][6]/@position"/>
                </xsl:variable>
                <units>
                    <xsl:for-each select="0 to $div2">
                        <xsl:variable name="test">
                            <xsl:value-of select="."/>
                        </xsl:variable>
                        <xsl:variable name="lead">
                            <xsl:value-of select="$sum - $posNo + $test"/>
                        </xsl:variable>
                        <xsl:variable name="trail">
                            <xsl:value-of select="$posNo - $test"/>
                        </xsl:variable>
                        <unit>
                            <xsl:attribute name="n" select="$test + 1"/>
                            <inside>
                                <left>
                                    <xsl:if test="($lead = $missing1) or ($lead = $missing2) or ($lead = $missing3) or ($lead = $missing4) or ($lead = $missing5) or ($lead = $missing6)">
                                        <xsl:attribute name="mode">missing</xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="pos">
                                        <xsl:value-of select="$lead"/>
                                    </xsl:attribute>
                                </left>
                                <right>
                                    <xsl:if test="($trail = $missing1) or ($trail = $missing2) or ($trail = $missing3) or ($trail = $missing4) or ($trail = $missing5) or ($trail = $missing6)">
                                        <xsl:attribute name="mode">missing</xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="pos">
                                        <xsl:value-of select="$trail"/>
                                    </xsl:attribute>
                                </right>
                            </inside>
                            <outside>
                                <left>
                                    <xsl:if test="($trail = $missing1) or ($trail = $missing2) or ($trail = $missing3) or ($trail = $missing4) or ($trail = $missing5) or ($trail = $missing6)">
                                        <xsl:attribute name="mode">missing</xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="pos">
                                        <xsl:value-of select="$trail"/>
                                    </xsl:attribute>
                                </left>
                                <right>
                                    <xsl:if test="($lead = $missing1) or ($lead = $missing2) or ($lead = $missing3) or ($lead = $missing4) or ($lead = $missing5)  or ($lead = $missing6)">
                                        <xsl:attribute name="mode">missing</xsl:attribute>
                                    </xsl:if>
                                    <xsl:attribute name="pos">
                                        <xsl:value-of select="$lead"/>
                                    </xsl:attribute>
                                </right>
                            </outside>
                        </unit>
                    </xsl:for-each>
                </units>
            </quire>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="test" match="//t:quire">
        <xsl:for-each select=".">
            <xsl:apply-templates/>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>