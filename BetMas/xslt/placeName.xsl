<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:placeName | t:region | t:country | t:settlement">
        <xsl:if test="@type and not(ancestor::t:div[@type='edition'])">
            <xsl:value-of select="concat(@type, ': ')"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="@ref">
               
                <xsl:choose> 
                    <xsl:when test="contains(@ref, 'pleiades:')">
                    <xsl:variable name="pleiadesid" select="substring-after(@ref, 'pleiades:')"/>
                        <xsl:if test="not(ancestor::t:div[@type='edition'])">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="MainTitle" data-value="{@ref}"/>
                        </xsl:if>
                    <xsl:apply-templates select="child::node()[not(name()='certainty')]"/>
                        <span xmlns="http://www.w3.org/1999/xhtml" class="pelagios popup" data-pelagiosID="{encode-for-uri(concat('http://pleiades.stoa.org/places/',$pleiadesid))}" data-href="https://pleiades.stoa.org/places/{$pleiadesid}" data-value="{$pleiadesid}">
                            ↗
                    </span>
                </xsl:when>
                    <xsl:when test="starts-with(@ref, 'Q')">
                        <xsl:if test="not(ancestor::t:div[@type='edition'])">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="MainTitle" data-value="{@ref}"/>
                        </xsl:if>
                        <xsl:apply-templates select="child::node()[not(name()='certainty')]"/>
                        <span xmlns="http://www.w3.org/1999/xhtml" class="pelagios popup" data-pelagiosID="{encode-for-uri(concat('http://www.wikidata.org/entity/',@ref))}" data-href="https://www.wikidata.org/wiki/{@ref}" data-value="{@ref}">
                            ↗
                        </span>
                    </xsl:when>
                    <xsl:when test="contains(@ref, 'gn:')">
                        <xsl:if test="not(ancestor::t:div[@type='edition'])">
                            <span xmlns="http://www.w3.org/1999/xhtml" class="MainTitle" data-value="{@ref}"/>
                        </xsl:if>
                        <xsl:variable name="gnid" select="substring-after(@ref, 'gn:')"/>
                        <a xmlns="http://www.w3.org/1999/xhtml" href="http://www.geonames.org/{$gnid}">
                            <xsl:value-of select="document(concat('http://api.geonames.org/get?geonameId=',$gnid,'&amp;username=betamasaheft'))//toponymName"/> 
                           <!--should look at API and get toponims
                           if there is nothing still try a geonames look up for a link
                           -->
                        </a>
                        <xsl:variable name="id" select="generate-id()"/>
                        <span xmlns="http://www.w3.org/1999/xhtml" class="popup" id="{$id}Ent{@ref}relations">
                            <xsl:text>  </xsl:text>
                            <i class="fa fa-hand-o-left"/>
                        </span>
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
                        <a xmlns="http://www.w3.org/1999/xhtml" href="/{@ref}">
                            <xsl:choose>
                                <xsl:when test="text()">
                                    <xsl:apply-templates select="child::node()[not(name()='certainty')]"/>
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
                        <span xmlns="http://www.w3.org/1999/xhtml" class="popup" id="{$id}Ent{$filename}relations">
                            <xsl:text>  </xsl:text>
                            <i class="fa fa-hand-o-left"/>
                            <xsl:text>  </xsl:text>
                        </span>
                        <span xmlns="http://www.w3.org/1999/xhtml" class="pelagios popup" data-pelagiosID="{encode-for-uri(concat('http://betamasaheft.eu/places/',@ref))}" data-href="https://betamasaheft.eu/{@ref}" data-value="{@ref}">
                            ↗
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            <xsl:if test="t:certainty">
                    <xsl:apply-templates select="t:certainty"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="not(ancestor::t:div[@type='edition'])">
            <xsl:if test="@when"> (information recorded on: <xsl:value-of select="@when"/>) </xsl:if>
        <xsl:if test="@notBefore">
            <xsl:text> After: </xsl:text>
            <xsl:value-of select="@notBefore"/>
        </xsl:if>
        <xsl:if test="@notAfter">
            <xsl:text> Before: </xsl:text>
            <xsl:value-of select="@notAfter"/>
        </xsl:if>
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
                                    <span class="MainTitle" data-value="{$filename}" property="http://purl.org/dc/elements/1.1/relation" resource="https://betamasaheft.eu/{$filename}"/>
                                    <xsl:if test="contains(@ref, '#')">
                                        <xsl:value-of select="concat(', ', substring-after(@ref, '#'))"/>
                                    </xsl:if>
                                </xsl:otherwise>
                            </xsl:choose>
        
        <xsl:if test="not(ancestor::t:div[@type='edition'])">
        <xsl:if test="@when"> (information recorded on: <xsl:value-of select="@when"/>) </xsl:if>
        <xsl:if test="@notBefore">
            <xsl:text> After: </xsl:text>
            <xsl:value-of select="@notBefore"/>
        </xsl:if>
        <xsl:if test="@notAfter">
            <xsl:text> Before: </xsl:text>
            <xsl:value-of select="@notAfter"/>
        </xsl:if>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>