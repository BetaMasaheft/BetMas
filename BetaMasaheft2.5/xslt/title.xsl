<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:title">
        <xsl:choose>
            <xsl:when test="@ref">
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
                
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:apply-templates/>
                        <a xmlns="http://www.w3.org/1999/xhtml" href="{@ref}">
                            <xsl:text> (</xsl:text>
                            <a href="{@ref}" class="MainTitle" data-value="{@ref}">
                                <xsl:text>CAe </xsl:text>
                                <xsl:value-of select="substring($filename, 4, 4)"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="substring-after(@ref, '#')"/>
                            </a>
                            <xsl:text>) </xsl:text>
                            <span class="glyphicon glyphicon-share"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <a xmlns="http://www.w3.org/1999/xhtml" href="{@ref}" class="MainTitle" data-value="{@ref}">
                            <xsl:text>CAe </xsl:text>
                            <xsl:value-of select="substring($filename, 4, 4)"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="substring-after(@ref, '#')"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
                
                
                <xsl:variable name="id" select="generate-id()"/>
                <a xmlns="http://www.w3.org/1999/xhtml" id="{$id}Ent{$filename}relations">
                    <xsl:text>  </xsl:text>
                    <span class="glyphicon glyphicon-hand-left"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@evidence"> (<xsl:value-of select="@evidence"/>)</xsl:if>
        <xsl:if test="@cert = 'low'">
            <xsl:text> ? </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:title" mode="nolink">
        <xsl:choose>
            <xsl:when test="@ref">
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
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:variable name="enteredTitle">
                            <xsl:apply-templates mode="nolink"/>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="string-length($enteredTitle) gt 50">
                                <xsl:value-of select="concat(substring($enteredTitle, 1, 50), '...')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$enteredTitle"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        
                    </xsl:when>
                    <xsl:otherwise>
                        <span xmlns="http://www.w3.org/1999/xhtml" class="MainTitle" data-value="{@ref}">
                            <xsl:value-of select="@ref"/>
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:when>
            <xsl:when test="not(text()) and not(@ref)"> No title </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="enteredTitle">
                    <xsl:apply-templates mode="nolink"/>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="string-length($enteredTitle) gt 50">
                        <xsl:value-of select="concat(substring($enteredTitle, 1, 50), '...')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$enteredTitle"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@evidence"> (<xsl:value-of select="@evidence"/>)</xsl:if>
        <xsl:if test="@cert = 'low'">
            <xsl:text> ? </xsl:text>
        </xsl:if>
        <xsl:text> / </xsl:text>
    </xsl:template>
</xsl:stylesheet>