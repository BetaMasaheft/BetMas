<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:desc[parent::t:relation]">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:surrogates">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:support">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:projectDesc">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:material">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:correction">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:sealDesc">
        <h3>Seals <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:list[ancestor::t:correction]">
        <ul>
            <xsl:for-each select="t:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    <xsl:template match="t:additional">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:adminInfo">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:head">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:foreign">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:recordHist">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:source">
        <xsl:apply-templates select="*"/>
    </xsl:template>
    
    <xsl:template match="t:note">
        <xsl:choose>
        <xsl:when test="parent::t:placeName">
        <div class="alert alert-info">
           <xsl:choose>
            <xsl:when test="t:p">
                <xsl:apply-templates/>
            </xsl:when> 
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates/>
                </p>
            </xsl:otherwise>
            
        </xsl:choose>
        <xsl:if test="@source">
                <a href="{@source}">Source <i class="fa fa-link" aria-hidden="true"/>
                        </a>
            </xsl:if>
        </div>
    </xsl:when>
            <xsl:when test="t:p">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:when test="parent::t:rdg">
                <xsl:text> </xsl:text>
                <i>
                    <xsl:apply-templates/>
                </i>
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:filiation">
        <p>
            <b>Filiation: </b>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:incipit">
        <xsl:variable name="lang" select="@xml:lang"/>
        <p>
            <b>Incipit <xsl:text> (</xsl:text>
                <xsl:value-of select="ancestor::t:TEI//t:language[@ident = $lang]"/>
                <xsl:text>): </xsl:text>
            </b>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:explicit">
        <xsl:variable name="lang" select="@xml:lang"/>
        <p>
            <b>
                <xsl:choose>
                    <xsl:when test="@type = 'subscription'">Subscription</xsl:when>
                    <xsl:otherwise>Explicit</xsl:otherwise>
                </xsl:choose>
                <xsl:text> (</xsl:text>
                <xsl:value-of select="ancestor::t:TEI//t:language[@ident = $lang]"/>
                <xsl:text>): </xsl:text>
            </b>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:rubric">
        <p>
            <b>Rubric <xsl:value-of select="@xml:lang"/>: </b>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:watermark">
        <h3>watermark</h3>
        <p>
            <xsl:choose>
                <xsl:when test=". != ''">Yes</xsl:when>
                <xsl:otherwise>No</xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <xsl:template match="t:custEvent/@restoration">
        <p>
            <xsl:value-of select="//t:custEvent/@restorations"/> restorations :<xsl:value-of select="//t:custEvent/@subtype"/>
        </p>
    </xsl:template>
    
    <xsl:template match="t:measure[. != '']">
        <xsl:value-of select="."/>
        <xsl:text> (</xsl:text>
        <xsl:value-of select="@unit"/>
        <xsl:if test="@type">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="@type"/>
        </xsl:if>
        <xsl:text>)</xsl:text>
        <xsl:choose>
            <xsl:when test="following-sibling::t:*[1][self::t:locus]">
                <xsl:text>: </xsl:text>
            </xsl:when>
        <xsl:when test="position() != last()">
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>.</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:hi">
        <xsl:choose>
            <xsl:when test="@rend = 'apices'">
                <sup>
                    <xsl:value-of select="."/>
                </sup>
            </xsl:when>
            <xsl:when test="@rend = 'underline'">
                <u>
                    <xsl:value-of select="."/>
                </u>
            </xsl:when>
            <xsl:when test="@rend = 'rubric'">
                <span class="rubric">
                    <xsl:value-of select="."/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:ab[not(ancestor::t:body)] | t:seg[@type = 'script'] | t:desc[parent::t:handNote] | t:seg[@type = 'rubrication']">
        <p>
            <xsl:if test="@type">
                <b>
                    <xsl:choose>
                        <xsl:when test="@type='script'">
                            <xsl:value-of select="parent::t:handNote/@script"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@type"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </b>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:textLang">
        <xsl:variable name="curlang" select="@mainLang"/>
        <p>
            <b>Language of text: </b>
            <xsl:value-of select="//t:language[@ident = $curlang]"/>
        </p>
    </xsl:template>
    <xsl:template match="t:signatures">
        <xsl:value-of select="text()"/>
        <xsl:if test="t:note">
            <xsl:text> - </xsl:text>
            <xsl:value-of select="t:note"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:desc[not(parent::t:relation)][not(parent::t:handNote)]">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:q">
        <xsl:if test="ancestor::t:decoNote">Legend: </xsl:if>
        <p lang="{@xml:lang}">
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="concat('(', @xml:lang, ') ')"/>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="lang" select="@xml:lang"/>
                    <xsl:text>Text in </xsl:text>
                    <xsl:value-of select="                             if (ancestor::t:TEI/t:teiHeader/t:profileDesc/t:langUsage/t:language[@ident = $lang]) then                                 ancestor::t:TEI/t:teiHeader/t:profileDesc/t:langUsage/t:language[@ident = $lang]/text()                             else                                 $lang"/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
</xsl:stylesheet>