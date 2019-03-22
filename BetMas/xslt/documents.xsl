<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:template match="/">
        <div class="w3-container">
           
            <div class="w3-twothird w3-padding w3-card-4">
                
                <div class="w3-row w3-padding w3-margin-bottom w3-red">
                    <xsl:apply-templates select="//t:note[@type = 'résumé']"/>
                    <span class="w3-tag w3-gray">
                        <xsl:apply-templates select="//t:date"/>
                    </span>
                </div>
                
                <div class="w3-row w3-margin-bottom">
                    <div class="w3-half w3-padding" lang="gez">
                        <xsl:apply-templates select="//t:q[@xml:lang='gez']"/>
                    </div>
                
                <div class="w3-half w3-padding">
                        <xsl:apply-templates select="//t:q[not(@xml:lang='gez')]"/>
                    </div>
                
                    <div class="footnotes">
                    <xsl:apply-templates select="//t:note[@n][@xml:id]"/>
                </div>
                </div>
            </div>
            <div class="w3-third w3-padding w3-card-4 w3-gray">
                <xsl:apply-templates select="//t:note[not(@n)][not(@xml:id)][not(@type = 'résumé')]"/>
                <xsl:if test="//t:listBibl">
            <xsl:apply-templates select="//t:listBibl"/>
        </xsl:if>
        </div>
        
        </div>
        <hr/>
    </xsl:template>
    <xsl:template match="t:seg[@ana]">
        <xsl:variable name="ana" select="substring-after(@ana, '#')"/>
        <span class="{$ana}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:ptr[@target]">
        <xsl:variable name="t" select="substring-after(@target, '#')"/>
        <xsl:variable name="note" select="//t:note[@xml:id = $t]"/>
        <sup>
            <a href="{@target}" id="pointer{$t}">
                <xsl:value-of select="$note/@n"/>
            </a>
        </sup>
    </xsl:template>
    <xsl:template match="t:note[@n][@xml:id]">
        <dl style="font-size:smaller;">
        <xsl:variable name="t" select="substring-after(@xml:id, '#')"/>
        <dt>
                <i>
                    <a href="#pointer{$t}" id="{@xml:id}">
                        <xsl:value-of select="@n"/>
                        <xsl:text>) </xsl:text>
                    </a>
                </i>
            </dt>
            <dd>
                <xsl:apply-templates/>
            </dd>
        </dl>
    </xsl:template>
    <xsl:template match="t:term[text()]">
        <b>
            <xsl:value-of select="."/>
        </b>
    </xsl:template>
    <xsl:template match="t:relation"/>
    <xsl:include href="resp.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
</xsl:stylesheet>