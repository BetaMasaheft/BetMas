<xsl:stylesheet xmlns="http://www.w3.torg/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    
    <xsl:template match="t:metamark"/>
    <xsl:template match="t:desc[parent::t:relation]">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:cit">
        <xsl:text>"</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>"</xsl:text>
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
            <b>
                <xsl:choose>
                <xsl:when test="@type = 'supplication'">Supplication</xsl:when>
                <xsl:otherwise>Incipit</xsl:otherwise>
            </xsl:choose> <xsl:text> (</xsl:text>
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
                    <xsl:when test="@type = 'supplication'">Supplication</xsl:when>
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
    
    <xsl:template match="t:custEvent[@type='restorations']">
        <p class="lead">
          This manuscript has <xsl:value-of select="@subtype"/>  restorations
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
            <xsl:when test="following-sibling::t:measure[@unit='leaf'][@type='blank']">
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>.</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:expan">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:abbr">
        <xsl:apply-templates/>
        <xsl:if test="not(ancestor::t:expan)">
            <xsl:text>(- - -)</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:ex">
           <xsl:text>(</xsl:text>
        <xsl:apply-templates/>
              <xsl:text>)</xsl:text>
    </xsl:template>
    
    <xsl:template match="t:am">
            <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:hi">
        <xsl:choose>
            <xsl:when test="@rend = 'ligature'">
                <span style="border-top:1px solid">
                    <xsl:value-of select="."/>
                </span>
            </xsl:when>
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
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:when test="@rend = 'encircled'">
                <span class="encircled">
                    <xsl:apply-templates/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
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
            <span property="http://purl.org/dc/elements/1.1/language"><xsl:value-of select="//t:language[@ident = $curlang]"/></span>
            <xsl:if test="@otherLangs">
                <xsl:variable name="Otherlang" select="@otherLangs"/> and <xsl:value-of select="//t:language[@ident = $Otherlang]"/>
            </xsl:if>
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
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    
    <xsl:template match="t:term[parent::t:desc]">
        <a target="_blank">
            <xsl:attribute name="href">
                <xsl:value-of select="concat('/authority-files/list?keyword=', @key)"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="text()">
                    <xsl:value-of select="text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <span class="MainTitle" data-value="{@key}"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
    </xsl:template>
    
    <xsl:template match="t:q">
        
        <p lang="{@xml:lang}">
            <xsl:if test="ancestor::t:decoNote">Legend: </xsl:if>
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