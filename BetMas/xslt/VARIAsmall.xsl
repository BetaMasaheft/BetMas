<xsl:stylesheet xmlns="http://www.w3.torg/1999/xhtml" 
    xmlns:funct="my.funct"
    xmlns:number="roman.numerals.funct"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:t="http://www.tei-c.org/ns/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="#all" version="2.0">
<!--    from https://stackoverflow.com/questions/43732638/roman-numeral-to-integer-value-using-xslt-->
    <xsl:function name="number:RomanToInteger">
        <xsl:param name="romannumber"/>
        <xsl:param name="followingvalue"/>
        <xsl:choose>
            <xsl:when test="ends-with($romannumber,'CM')">
                <xsl:value-of select="900 + number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 900)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'M')">
                <xsl:value-of select="1000+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 1000)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'CD')">
                <xsl:value-of select="400+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 400)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'D')">
                <xsl:value-of select="500+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 500)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'XC')">
                <xsl:value-of select="90+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 90)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'C')">
                <xsl:value-of select="(if(100 ge number($followingvalue)) then 100 else -100)+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 100)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'XL')">
                <xsl:value-of select="40+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 40)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'L')">
                <xsl:value-of select="50+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 50)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'IX')">
                <xsl:value-of select="9+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 9)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'X')">
                <xsl:value-of select="(if(10 ge number($followingvalue)) then 10 else -10) + number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 10)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'IV')">
                <xsl:value-of select="4+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-2), 4)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'V')">
                <xsl:value-of select="5+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 5)"/>
            </xsl:when>
            <xsl:when test="ends-with($romannumber,'I')">
                <xsl:value-of select="(if(1 ge number($followingvalue)) then 1 else -1)+ number:RomanToInteger(substring($romannumber,1,string-length($romannumber)-1), 1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="funct:analyseMeasure">
       <xsl:param name="measure"/>
       <xsl:choose>
           <xsl:when test="matches($measure,'\s*(\d+)\s*\+\s*(\d+)\s*\+\s*(\d+)\s*')">
               <xsl:analyze-string select="$measure" regex="\s*(\d+)\s*\+\s*(\d+)\s*\+\s*(\d+)\s*">
                   <xsl:matching-substring>
                       <beginning><xsl:value-of select="regex-group(1)"/></beginning>
                       <text><xsl:value-of select="regex-group(2)"/></text>
                       <end><xsl:value-of select="regex-group(3)"/></end>
                   </xsl:matching-substring>
                   <xsl:non-matching-substring>
                       <xsl:value-of select="."/>
                   </xsl:non-matching-substring>
               </xsl:analyze-string>
           </xsl:when>
           <xsl:when test="matches($measure,'\s*(\d+)\s*\+\s*(\d+)\s*')">
               <xsl:analyze-string select="$measure" regex="\s*(\d+)\s*\+\s*(\d+)\s*">
                   <xsl:matching-substring>
                       <xsl:variable name="values">
                           <vals>
                               <val><xsl:value-of select="regex-group(1)"/></val>
                               <val><xsl:value-of select="regex-group(2)"/></val>
                           </vals>
                       </xsl:variable>
                       <xsl:variable name="max" select="max($values//*:val)"/>
                       <xsl:variable name="min" select="min($values//*:val)"/>
                       <xsl:if test="$min=xs:integer(regex-group(1))"><beginning><xsl:value-of select="$min"/></beginning></xsl:if>
                       <text><xsl:value-of select="$max"/></text>
                       <xsl:if test="$min=xs:integer(regex-group(2))"><end><xsl:value-of select="$min"/></end></xsl:if>
                   </xsl:matching-substring>
                   <xsl:non-matching-substring>
                       <xsl:value-of select="."/>
                   </xsl:non-matching-substring>
               </xsl:analyze-string>
           </xsl:when>
           <xsl:when test="matches($measure, '\s*([ivx|IVX]+)\s*\+\s*(\d{1,3})\s*\+\s*([ivx|IVX]+)\s*')">
               <xsl:analyze-string select="$measure" regex="\s*([ivx|IVX]+)\s*\+\s*(\d{{1,3}})\s*\+\s*([ivx|IVX]+)\s*">
                   <xsl:matching-substring>
                       <beginning><xsl:number value="number:RomanToInteger(regex-group(1), 0)" format="1"/></beginning>
                       <text><xsl:value-of select="regex-group(2)"/></text>
                       <end><xsl:number value="number:RomanToInteger(regex-group(3), 0)" format="1"/></end>
                   </xsl:matching-substring>
                   <xsl:non-matching-substring>
                       <xsl:value-of select="."/>
                   </xsl:non-matching-substring>
               </xsl:analyze-string>
           </xsl:when>
           <xsl:when test="matches($measure, '\s*([ivx|IVX]+)\s*\+\s*(\d{1,3})\s*')">
               <xsl:analyze-string select="$measure" regex="\s*([ivx|IVX]+)\s*\+\s*(\d{{1,3}})\s*">
                   <xsl:matching-substring>
                       <beginning><xsl:number value="number:RomanToInteger(regex-group(1), 0)" format="1"/></beginning>
                       <text><xsl:value-of select="regex-group(2)"/></text>
                   </xsl:matching-substring>
                   <xsl:non-matching-substring>
                       <xsl:value-of select="."/>
                   </xsl:non-matching-substring>
               </xsl:analyze-string>
           </xsl:when>
           <xsl:when test="matches($measure, '\s*(\d{1,3})\s*\+\s*([ivx|IVX]+)\s*')">
               <xsl:analyze-string select="$measure" regex="\s*(\d{{1,3}})\s*\+\s*([ivx|IVX]+)\s*">
                   <xsl:matching-substring>
                       <text><xsl:value-of select="regex-group(1)"/></text>
                       <end><xsl:number value="number:RomanToInteger(regex-group(2), 0)" format="1"/></end>
                   </xsl:matching-substring>
                   <xsl:non-matching-substring>
                       <xsl:value-of select="."/>
                   </xsl:non-matching-substring>
               </xsl:analyze-string>
           </xsl:when>
           <xsl:when test="matches($measure, '.*\((.*)\)')">
               <xsl:analyze-string select="$measure" regex=".*\((.*)\)">
                   <xsl:matching-substring>
               <xsl:value-of select="funct:analyseMeasure(regex-group(1))"/>
                   </xsl:matching-substring>
               </xsl:analyze-string>
           </xsl:when>
       </xsl:choose>
   </xsl:function>
   <xsl:function name="funct:measure">
        <xsl:param name="measure"/>
       <xsl:variable name="parsedMeasure">
            <xsl:copy-of select="funct:analyseMeasure($measure)"/>
        </xsl:variable>
       <xsl:variable name="totalprotectives" >
            <xsl:choose>
                <xsl:when test="$parsedMeasure//*:beginning and $parsedMeasure//*:end">
                    <xsl:value-of select="xs:integer($parsedMeasure//*:beginning/data()) + xs:integer($parsedMeasure//*:end/data())"/>
                </xsl:when>
                <xsl:when test="$parsedMeasure//*:beginning and not($parsedMeasure//*:end)">
                    <xsl:value-of select="xs:integer($parsedMeasure//*:beginning/data())"/>
                </xsl:when>
                <xsl:when test="$parsedMeasure//*:end and not($parsedMeasure//*:beginning)">
                    <xsl:value-of select="xs:integer($parsedMeasure//*:end/data())"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
       <xsl:if test="$parsedMeasure//*:beginning">
            <xsl:choose>
            <xsl:when test="xs:integer($parsedMeasure//*:beginning/data()) gt 1">
                i-<xsl:number format="i" value="$parsedMeasure//*:beginning/data()"/>
            </xsl:when>
            <xsl:otherwise>i</xsl:otherwise>
        </xsl:choose>
        <xsl:text>+</xsl:text>
       </xsl:if>
        <xsl:number value="$parsedMeasure//*:text/data()"/> 
        <xsl:if test="$parsedMeasure//*:end"> 
            <xsl:text>+</xsl:text>
            <xsl:choose>
                <xsl:when test="(xs:integer($parsedMeasure//*:end/data()) gt 1) and $parsedMeasure//*:beginning">
                    <xsl:number format="i" 
                        value="($parsedMeasure//*:beginning/data()+1)"/>-<xsl:number 
                            format="i" value="$totalprotectives"/>
                </xsl:when>
                <xsl:otherwise><xsl:number format="i" value="$totalprotectives"/></xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>
    
    <xsl:template match="t:relation" mode="gendesc">
        <xsl:choose>
            <xsl:when test="not(@passive) and t:desc">
                <xsl:value-of select="t:desc"/>
            </xsl:when>
            <xsl:otherwise>
                <a target="_blank">
                    <xsl:choose>
                <xsl:when test="starts-with(@passive, 'http')">
                    <xsl:attribute name="href">
                   <xsl:value-of select="@passive"/>
                </xsl:attribute>
                    <xsl:value-of select="@passive"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="href">
                    <xsl:value-of select="concat('/', @passive)"/>
                </xsl:attribute>
                    <span class="MainTitle" data-value="{@passive}">
                                <xsl:value-of select="@passive"/>
                            </span>
                </xsl:otherwise>
            </xsl:choose>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
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
        <xsl:if test="t:note"><h2>Administrative Information</h2></xsl:if>
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
        <xsl:when test="not(parent::*:fragment)">
            <p><xsl:apply-templates/></p>
        </xsl:when>    
        <xsl:when test="parent::t:placeName">
        <div class="w3-panel w3-gray">
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
                    <xsl:apply-templates/>
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
        <p lang="{$lang}">
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
        <p lang="{$lang}">
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
        <p lang="{@xml:lang}">
            <b>Rubric <xsl:value-of select="@xml:lang"/>: </b>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:watermark[not(parent::t:support[t:material[@key='parchment']])]">
        <h3>Watermark</h3>
        <p>
            <xsl:choose>
                <xsl:when test=". != ''">Yes</xsl:when>
                <xsl:otherwise>No</xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    
    <xsl:template match="t:custEvent[@type='restorations']">
        <p class="w3-large">
          This manuscript has <xsl:value-of select="@subtype"/>  restorations
        </p>
    </xsl:template>
    
    <xsl:template match="t:measure[. != '']">
        <span class="w3-tooltip">
            <xsl:choose>
                <xsl:when test="contains(.,'+')">
                <xsl:value-of select="funct:measure(.)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>    
                </xsl:otherwise>
            </xsl:choose>
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
   <span class="w3-teg">Entered as <xsl:value-of select="."/></span>
        </span>
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
            <span property="http://purl.org/dc/elements/1.1/language">
                <xsl:value-of select="//t:language[@ident = $curlang]"/>
            </span>
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
    
    
    <xsl:template match="t:term[parent::t:desc] | t:term[parent::t:summary]">
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
    
    <xsl:template match="t:q[parent::t:desc]">
        
        <span lang="{@xml:lang}">
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
        </span>
    </xsl:template>
    
    <xsl:template match="t:q[not(parent::t:desc)]">
        
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