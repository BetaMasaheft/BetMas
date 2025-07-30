<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:msItem[parent::t:msContents]">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:variable name="trimid" select="concat(replace($id, '\.', '-'), 'N', position())"/>
        <div class="w3-container msItem" resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}" typeof="https://betamasaheft.eu/msitem https://w3id.org/sdc/ontology#UniCont" id="{$id}">
            <button style="max-width:100%" onclick="openAccordion('item{$trimid}')" class="w3-button w3-gray contentItem " resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}"> 
                <xsl:apply-templates select="./t:title[1]" mode="nolink"/> Item <xsl:value-of select="$id"/>
                <xsl:if test="child::t:msItem">
                    <span class="w3-badge w3-margin-left" property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts" about="https://betamasaheft.eu/{$mainID}/msitem/{$id}">
                        <xsl:value-of select="count(child::t:msItem)"/>
                    </span>
                </xsl:if>
            </button>
            
            <div id="item{$trimid}" class="w3-hide msItemContent">
                <div class="w3-container">
                    <hr class="msItems" align="left"/>
                    <xsl:variable name="anchor" select="concat('#', $id)"/>
                    <xsl:if test="ancestor::t:TEI//t:div[@corresp = $anchor]">
                        <xsl:variable name="number" select="if(ancestor::t:TEI//t:div[@corresp = $anchor]/@n) then ancestor::t:TEI//t:div[@corresp = $anchor]/@n else 1"/>
                        <a role="button" class="w3-button w3-gray w3-small" href="/manuscripts/{$mainID}/text?per-page=1&amp;start={$number}">Transcription</a>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="child::t:msItem">
                            <div class="w3-container" id="contentItem{$trimid}" rel="http://purl.org/dc/terms/hasPart">
                                <xsl:apply-templates/>
                            </div>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>
        </div>
        <hr/>
    </xsl:template>
    
    
    
    
    
    <xsl:template match="t:msItem">
        <xsl:variable name="id" select="@xml:id"/>
        <xsl:variable name="trimid" select="replace($id, '\.', '-')"/>
        <div class="w3-container msItem" resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}" id="{@xml:id}" typeof="https://betamasaheft.eu/msitem">
            
            <button style="max-width:100%" onclick="openAccordion('item{$trimid}')" class="w3-button w3-gray contentItem" resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}"> 
                <xsl:apply-templates select="./t:title[1]" mode="nolink"/> Item 
                <xsl:value-of select="$id"/>
                
                <xsl:if test="child::t:msItem">
                    <span class="w3-badge  w3-margin-left" property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts" about="https://betamasaheft.eu/{$mainID}/msitem/{$id}">
                        <xsl:value-of select="count(child::t:msItem)"/>
                    </span>
                </xsl:if>
            </button>
            
            <div id="item{$trimid}" class="w3-hide msItemContent">
                <div class="w3-container">
                    <hr class="msItems" align="left"/>
                    <xsl:variable name="anchor" select="concat('#', $id)"/>
                    <xsl:if test="ancestor::t:TEI//t:div[@corresp = $anchor]">
                        <xsl:variable name="number" select="if(ancestor::t:TEI//t:div[@corresp = $anchor]/@n) then ancestor::t:TEI//t:div[@corresp = $anchor]/@n else 1"/>
                        <a role="button" class="w3-button w3-red w3-small" href="/manuscripts/{$mainID}/text?per-page=1&amp;start={$number}">Transcription</a>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test="child::t:msItem">
                            <div class="accordion" id="contentItem{$trimid}" rel="http://purl.org/dc/terms/hasPart">
                                <xsl:apply-templates/>
                            </div>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates/>
                        </xsl:otherwise>
                    </xsl:choose>
                </div>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>