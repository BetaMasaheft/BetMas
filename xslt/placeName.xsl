<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:placeName | t:region | t:country | t:settlement">
        <xsl:if test="@type">
            <xsl:value-of select="concat(@type, ': ')"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="contains(@ref, 'gn:')">
                        <xsl:variable name="gnid" select="substring-after(@ref, 'gn:')"/>
                        <a xmlns="http://www.w3.org/1999/xhtml" href="http://www.geonames.org/{$gnid}">
                            <xsl:value-of select="document(concat('http://api.geonames.org/get?geonameId=',$gnid,'&amp;username=betamasaheft'))//toponymName"/> 
                           <!--should look at API and get toponims
                           if there is nothing still try a geonames look up for a link
                           -->
                        </a>
                        <xsl:variable name="id" select="generate-id()"/>
                        <a xmlns="http://www.w3.org/1999/xhtml" id="{$id}{@ref}relations">
                            <xsl:text>  </xsl:text>
                            <i class="fa fa-hand-o-left"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="filename">
                            <xsl:choose>
                                <xsl:when test="contains(@ref, '#')">
                                    <xsl:value-of select="substring-before(@ref, '#')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@ref"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="collection">
                            <xsl:choose>
                                <xsl:when test="contains(@ref, 'LOC')">places</xsl:when>
                                <xsl:when test="contains(@ref, 'INS')">institutions</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <a xmlns="http://www.w3.org/1999/xhtml" href="{@ref}">
                            <xsl:choose>
                                <xsl:when test="text()">
                                    <xsl:value-of select="."/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="@type = 'qušat'">
                                        <xsl:text>qušat </xsl:text>
                                    </xsl:if>
                                    <xsl:if test="@type = 'waradā'">
                                        <xsl:text>waradā </xsl:text>
                                    </xsl:if>
                                    <span class="MainTitle" data-value="{$filename}"/>
                                    <xsl:if test="contains(@ref, '#')">
                                        <xsl:value-of select="concat(', ', substring-after(@ref, '#'))"/>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
                        </a>
                        <xsl:variable name="id" select="generate-id()"/>
                        <a xmlns="http://www.w3.org/1999/xhtml" id="{$id}Ent{$filename}relations">
                            <xsl:text>  </xsl:text>
                            <i class="fa fa-hand-o-left"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@when"> (information recorded on: <xsl:value-of select="@when"/>) </xsl:if>
        <xsl:if test="@notBefore">
            <xsl:text> After: </xsl:text>
            <xsl:value-of select="@notBefore"/>
        </xsl:if>
        <xsl:if test="@notAfter">
            <xsl:text> Before: </xsl:text>
            <xsl:value-of select="@notAfter"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:placeName | t:region | t:country | t:settlement" mode="nolink">
        <xsl:if test="@type">
            <xsl:value-of select="concat(@type, ': ')"/>
        </xsl:if>
                        <xsl:variable name="filename">
                            <xsl:choose>
                                <xsl:when test="contains(@ref, '#')">
                                    <xsl:value-of select="substring-before(@ref, '#')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@ref"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="collection">
                            <xsl:choose>
                                <xsl:when test="contains(@ref, 'LOC')">places</xsl:when>
                                <xsl:when test="contains(@ref, 'INS')">institutions</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                            <xsl:choose>
                                <xsl:when test="text()">
                                    <xsl:value-of select="."/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="@type = 'qušat'">
                                        <xsl:text>qušat </xsl:text>
                                    </xsl:if>
                                    <xsl:if test="@type = 'waradā'">
                                        <xsl:text>waradā </xsl:text>
                                    </xsl:if>
                                    <span class="MainTitle" data-value="{$filename}"/>
                                    <xsl:if test="contains(@ref, '#')">
                                        <xsl:value-of select="concat(', ', substring-after(@ref, '#'))"/>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
                        
        <xsl:if test="@when"> (information recorded on: <xsl:value-of select="@when"/>) </xsl:if>
        <xsl:if test="@notBefore">
            <xsl:text> After: </xsl:text>
            <xsl:value-of select="@notBefore"/>
        </xsl:if>
        <xsl:if test="@notAfter">
            <xsl:text> Before: </xsl:text>
            <xsl:value-of select="@notAfter"/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>