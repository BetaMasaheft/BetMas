<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:decoDesc">
        <div id="deco" rel="http://purl.org/dc/terms/hasPart">
            <h2>Decoration <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart[1]/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart[1]/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit
                <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
                <a tabindex="0" data-html="true" data-toggle="popover" title="additions informations">
                    <xsl:attribute name="data-content">
                        <xsl:text>In this unit there are in total </xsl:text>
            <xsl:for-each select="//t:decoNote[not(ancestor::t:binding)][generate-id() = generate-id(key('decotype', @type)[1])]">
                <xsl:value-of select="concat(' ', count(key('decotype', ./@type)), ' notes about ', ./@type)"/>
                <xsl:choose>
                    <xsl:when test="not(position() = last()) and not(position() + 1 = last())">
                        <xsl:text>,</xsl:text>
                    </xsl:when>
                    <xsl:when test="position() + 1 = last()">
                        <xsl:text> and</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>.</xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
                    </xsl:attribute>
                        <i class="fa fa-info-circle" aria-hidden="true"/>
                </a>
            </h2>
            
            
            <p>
                <xsl:apply-templates select="//t:decoDesc/t:summary"/>
            </p>
            <xsl:if test="t:decoNote[not(ancestor::t:binding)][@type = 'rubrication']">
                <h3>Rubrication</h3>
                <ol>
                    <xsl:for-each select="t:decoNote[not(ancestor::t:binding)][@type = 'rubrication']">
                        <li resource="http://betamasaheft.eu/{$mainID}/decoration/{@xml:id}">
                            <xsl:attribute name="typeof">
                                <xsl:for-each select="current()//t:term/@key">
                                    <xsl:value-of select="concat('http://betamasaheft.eu/',.)"/>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                                <xsl:text> </xsl:text>
                                <xsl:if test="@type">
                                    <xsl:value-of select="concat('http://betamasaheft.eu/',@type)"/>
                                </xsl:if>
                            </xsl:attribute>
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(@type, ': ')"/>
                            <xsl:apply-templates/>
                        </li>
                    </xsl:for-each>
                </ol>
            </xsl:if>
            <xsl:if test="t:decoNote[not(ancestor::t:binding)][@type = 'frame']">
                <h3>Frame notes</h3>
                <ol>
                    <xsl:for-each select="t:decoNote[not(ancestor::t:binding)][@type = 'frame']">
                        <li resource="http://betamasaheft.eu/{$mainID}/decoration/{@xml:id}">
                            <xsl:attribute name="typeof">
                                <xsl:for-each select="current()//t:term/@key">
                                    <xsl:value-of select="concat('http://betamasaheft.eu/',.)"/>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </xsl:attribute>
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(@type, ': ')"/>
                            <xsl:apply-templates/>
                        </li>
                    </xsl:for-each>
                </ol>
            </xsl:if>
            <xsl:if test="t:decoNote[not(ancestor::t:binding)][@type = 'miniature']">
                <h3>Miniature notes</h3>
                <ol>
                    <xsl:for-each select="t:decoNote[not(ancestor::t:binding)][@type = 'miniature']">
                        <li resource="http://betamasaheft.eu/{$mainID}/decoration/{@xml:id}">
                            <xsl:attribute name="typeof">
                                <xsl:for-each select="current()//t:term/@key">
                                    <xsl:value-of select="concat('http://betamasaheft.eu/',.)"/>
                                    <xsl:text> </xsl:text>
                            </xsl:for-each>
                        </xsl:attribute>
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(@type, ': ')"/>
                            <xsl:apply-templates/>
                        </li>
                    </xsl:for-each>
                </ol>
            </xsl:if>
            <xsl:if test="t:decoNote[not(ancestor::t:binding)][@type != 'rubrication'][@type != 'miniature'][@type != 'frame']">
                <h3>Other decorations</h3>
                <ol>
                    <xsl:for-each select="t:decoNote[not(ancestor::t:binding)][@type != 'rubrication'][@type != 'miniature'][@type != 'frame']">
                        <li resource="http://betamasaheft.eu/{$mainID}/decoration/{@xml:id}">
                            <xsl:attribute name="typeof">
                                <xsl:for-each select="current()//t:term/@key">
                                    <xsl:value-of select="concat('http://betamasaheft.eu/',.)"/>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </xsl:attribute>
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:value-of select="concat(@type, ': ')"/>
                            <xsl:apply-templates/>
                        </li>
                    </xsl:for-each>
                </ol>
            </xsl:if>
        </div>
    </xsl:template>
</xsl:stylesheet>