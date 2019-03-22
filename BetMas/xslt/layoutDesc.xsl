<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:layoutDesc">
        <div rel="http://purl.org/dc/terms/hasPart">
            <h3>Layout <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:for-each select=".//t:layout">
            <xsl:sort select="position()"/>
        <div id="layout{position()}" resource="http://betamasaheft.eu/{$mainID}/layout/layout{position()}">    
            <h4>
                <xsl:text>Layout note</xsl:text>
                <xsl:text> </xsl:text>
                <xsl:value-of select="position()"/>
                <xsl:if test="t:locus">
                    <xsl:text> (</xsl:text>
                    <xsl:apply-templates select="t:locus"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </h4>
            <xsl:if test="@columns">
                <p>Number of columns: <xsl:value-of select="@columns"/>
            </p>
            </xsl:if>
            <xsl:if test="@writtenLines">
                <p>Number of lines: <xsl:value-of select="if (contains(@writtenLines, ' ')) then replace(@writtenLines, ' ', '-') else @writtenLines "/>
            </p>
            </xsl:if>
            <xsl:if test=".//t:dimensions">
                <div class="w3-responsive">
                            <table class="w3-table w3-hoverable">
                    <tr>
                        <td>H</td>
                        <td>
                            <span class="lead">
                                <xsl:value-of select="t:dimensions/t:height"/>
                            </span>
                            <xsl:value-of select="t:dimensions[t:height]/@unit"/>
                        </td>
                    </tr>
                    <tr>
                        <td>W</td>
                        <td>
                            <span class="lead">
                                <xsl:value-of select="t:dimensions/t:width"/>
                            </span>
                            <xsl:value-of select=".//t:dimensions[t:width]/@unit"/>
                        </td>
                    </tr>
                    <xsl:if test="t:dimensions[not(@type = 'margin')]/t:dim[@type = 'intercolumn']">
                        <tr>
                        <td>Intercolumn</td>
                        <td>
                            <span class="lead">
                                <xsl:value-of select="t:dimensions[not(@type = 'margin')]/t:dim[@type = 'intercolumn']"/>
                            </span>
                            <xsl:value-of select=".//t:dimensions[not(@type = 'margin')][t:dim[@type = 'intercolumn']]/@unit"/>
                        </td>
                    </tr>
                    </xsl:if>
                   <xsl:if test="t:dimensions[@type = 'margin']/t:dim[@type]">
                       
                       <tr>
                                        <td>
                                            <b>Margins</b>
                                        </td>
                                        <td/>
                                    </tr>
                       <xsl:for-each select="t:dimensions[@type = 'margin']/t:dim[@type]">
                           
                           <tr>
                               <td>
                                                <xsl:value-of select="@type"/>
                                            </td>
                               <td>
                                                <span class="lead">
                                   <xsl:value-of select="."/>
                               </span>
                                   <xsl:value-of select="@unit"/>
                               </td>
                           </tr>
                    </xsl:for-each>
                   </xsl:if>
                </table>
                </div>
                        <xsl:if test="t:note">
                    <p>
                        <xsl:apply-templates select="t:note"/>
                    </p>
                </xsl:if>
                <xsl:variable name="topmargin" select="                         if (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'top'][1]/text()) then                             (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'top'][1])                         else                             ('0')"/>
                <xsl:variable name="bottomargin" select="                         if (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'bottom'][1]/text()) then                             (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'bottom'][1])                         else                             ('0')"/>
                <xsl:variable name="rightmargin" select="                         if (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'right'][1]/text()) then                             (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'right'][1])                         else                             ('0')"/>
                <xsl:variable name="leftmargin" select="                         if (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'left'][1]/text()) then                             (t:dimensions[@type = 'margin'][1]/t:dim[@type = 'left'][1])                         else                             ('0')"/>
                <xsl:variable name="textwidth" select="t:dimensions[not(@type)][1]/t:width[1]"/>
                <xsl:variable name="heighText" select="t:dimensions[not(@type)][1]/t:height[1]"/>
                <xsl:variable name="totalHeight" select="                         if (ancestor::t:TEI//t:objectDesc/t:supportDesc/t:extent/t:dimensions[@type = 'outer' and @unit = 'mm']/t:height/text()) then                             (ancestor::t:TEI//t:objectDesc/t:supportDesc/t:extent/t:dimensions[@type = 'outer' and @unit = 'mm']/t:height)                         else                             ('0')"/>
                <xsl:variable name="totalwidth" select="                         if (ancestor::t:TEI//t:objectDesc/t:supportDesc/t:extent/t:dimensions[@type = 'outer' and @unit = 'mm']/t:width/text()) then                             (ancestor::t:TEI//t:objectDesc/t:supportDesc/t:extent/t:dimensions[@type = 'outer' and @unit = 'mm']/t:width)                         else                             ('0')"/>
                <xsl:variable name="computedheight" select="number($heighText) + number($bottomargin) + number($topmargin)"/>
                <xsl:variable name="computedwidth" select="number($textwidth) + number($rightmargin) + number($leftmargin)"/>
                <xsl:variable name="currentMsPart">
                    <xsl:if test="./ancestor::t:msPart">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </xsl:if>
                </xsl:variable>
                <button type="button" class="w3-button w3-gray" onclick="openaccordion('layoutreport{$currentMsPart}')">Layout report</button>
                <div class="report w3-container w3-hide" id="layoutreport{$currentMsPart}">
                    <p>- Ms <xsl:value-of select="concat(t:TEI/@xml:id, $currentMsPart)"/>
                        <xsl:if test=".//t:titleStmt/t:title">, <xsl:value-of select=".//t:titleStmt/t:title"/>
                        </xsl:if>
                        <xsl:text>
            </xsl:text>
                        <xsl:choose>
                            <xsl:when test="number($computedheight) &gt; number($totalHeight)"> *
                                has a sum of layout height of <xsl:value-of select="$computedheight"/>mm which is greater than the object height of <xsl:value-of select="$totalHeight"/>mm </xsl:when>
                            <xsl:when test="number($computedwidth) &gt; number($totalwidth)"> * has
                                a sum of layout width of <xsl:value-of select="$computedwidth"/>mm
                                which is greater than the object width of <xsl:value-of select="$totalwidth"/>mm </xsl:when>
                            <xsl:otherwise> looks ok for measures computed width is: <xsl:value-of select="$computedwidth"/>mm, object width is: <xsl:value-of select="$totalwidth"/>mm, computed height is: <xsl:value-of select="$computedheight"/>mm and object height is: <xsl:value-of select="$totalHeight"/>mm. <xsl:if test="number($topmargin) = 0 or number($bottomargin) = 0 or number($rightmargin) = 0 or number($leftmargin) = 0 or number($totalHeight) = 0 or number($totalwidth) = 0">but the following values are
                                recognized as empty: <xsl:if test="number($topmargin) = 0">top
                                    margin </xsl:if>
                                    <xsl:if test="number($bottomargin) = 0">bottom margin </xsl:if>
                                    <xsl:if test="number($rightmargin) = 0">right margin </xsl:if>
                                    <xsl:if test="number($leftmargin) = 0">left margin </xsl:if>
                                    <xsl:if test="number($totalHeight) = 0">object height </xsl:if>
                                    <xsl:if test="number($totalwidth) = 0">object width </xsl:if>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </p>
                </div>
            </xsl:if>
        </div>
        </xsl:for-each>
        <xsl:if test=".//t:ab[@type = 'ruling']">
            <h3>Ruling <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            </h3>
            <ul>
                <xsl:for-each select=".//t:ab[@type = 'ruling']">
                    <li>
                        <xsl:if test="@subtype">(Subtype: <xsl:value-of select="@subtype"/>
                            <xsl:text>) </xsl:text>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="@subtype='pattern'">
                                <xsl:variable name="muzerelle">http://palaeographia.org/muzerelle/regGraph2.php?F=</xsl:variable>
                                <xsl:analyze-string select="." regex="(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))">
                                    <xsl:matching-substring>
                                            <a href="{concat($muzerelle, regex-group(1))}" target="_blank">
                                                <xsl:value-of select="regex-group(1)"/>
                                            </a>
                                        </xsl:matching-substring>
                                    <xsl:non-matching-substring>
                                            <xsl:value-of select="."/>
                                        </xsl:non-matching-substring>
                                </xsl:analyze-string>
                            </xsl:when>
                            <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                        </xsl:choose>
                        
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test=".//t:ab[@type = 'pricking']">
            <h3>Pricking <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            </h3>
            <ul>
                <xsl:for-each select=".//t:ab[@type = 'pricking']">
                    <li>
                        <xsl:if test="@subtype">(Subtype: <xsl:value-of select="@subtype"/>
                            <xsl:text>) </xsl:text>
                        </xsl:if>
                        <xsl:value-of select="."/>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test=".//t:ab[@type = 'punctuation']">
            <h3>Punctuation <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            </h3>
            <ul>
                <xsl:for-each select=".//t:ab[@type = 'punctuation']">
                    <li>
                        <xsl:if test="@subtype">(Subtype: <xsl:value-of select="@subtype"/>
                            <xsl:text>) </xsl:text>
                        </xsl:if>
                        <xsl:value-of select="."/>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test=".//t:ab[@type != 'pricking'][@type != 'ruling'][@type != 'punctuation']">
            <h3>Other <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            </h3>
            <ul>
                <xsl:for-each select=".//t:ab[@type != 'pricking'][@type != 'ruling'][@type != 'punctuation']">
                    <li>
                        <xsl:value-of select="@type"/>
                        <xsl:text> </xsl:text>
                        <xsl:if test="@subtype">(Subtype: <xsl:value-of select="@subtype"/>
                            <xsl:text>) </xsl:text>
                        </xsl:if>
                        <xsl:text>: </xsl:text>
                        <xsl:value-of select="."/>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test=".//t:layout//t:ab[not(@type)]">
            <h3 style="color:red;">Ab without type <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            </h3>
            <ul>
                <xsl:for-each select=".//t:ab[not(@type)]">
                    <li>
                        <b style="color:red;">THIS ab element does not have a required type.</b>
                        <xsl:value-of select="."/>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
       <xsl:if test="//t:handNote"> <h3>Palaeography <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:for-each select=".//t:handNote">
            <h4>
                <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute> Hand <xsl:value-of select="substring-after(@xml:id, 'h')"/>
            </h4>
            <p>
                <xsl:value-of select="@script"/>: <xsl:value-of select="t:ab[@type = 'script']"/>
            </p>
            <p>Ink: <xsl:value-of select="t:seg[@type = 'ink']"/>
            </p>
            <xsl:if test="t:list[@type = 'abbreviations']">
                <h4> Abbreviations </h4>
                <ul>
                    <xsl:for-each select="t:list[@type = 'abbreviations']/t:item">
                        <li>
                            <xsl:apply-templates select="."/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:if>
            <xsl:if test="t:persName[@role = 'scribe']">
                <b>Scribe</b>
                <p>
                    <xsl:apply-templates select="t:persName[@role = 'scribe']"/>
                </p>
            </xsl:if>
            <xsl:apply-templates select="child::node() except (t:list | t:ab[@type = 'script'] | t:seg)"/>
        </xsl:for-each>
      </xsl:if>  <xsl:if test="//t:ab[@subtype = 'Executed'] or //t:ab[@subtype = 'Usage']">
            <h4>Punctuation</h4>
            <xsl:if test="//t:ab[@subtype = 'Executed']">
                <p>Executed: <xsl:value-of select="//t:ab[@subtype = 'Executed']"/>
                </p>
            </xsl:if>
            <xsl:if test="//t:ab[@subtype = 'Usage']">
                <p>Usage: <xsl:value-of select="//t:ab[@subtype = 'Usage']"/>
                </p>
            </xsl:if>
        </xsl:if>
        <ul>
            <xsl:for-each select=".//t:ab[not(@subtype)][@type = 'punctuation']//t:item">
                <li>
                    <xsl:attribute name="id">
                        <xsl:value-of select="@xml:id"/>
                    </xsl:attribute>
                    <xsl:value-of select="."/>
                </li>
            </xsl:for-each>
        </ul>
        <xsl:if test=".//t:layout//t:ab[@type = 'CruxAnsata']">
            <h4>crux</h4>
            <p>Yes <xsl:apply-templates select="//t:layout//t:ab[@type = 'CruxAnsata']"/>
            </p>
        </xsl:if>
        <xsl:if test=".//t:layout//t:ab[@type = 'coronis']">
            <h4>coronis</h4>
            <p>Yes <xsl:apply-templates select="//t:layout//t:ab[@type = 'coronis']"/>
            </p>
        </xsl:if>
        <xsl:if test=".//t:layout//t:ab[@type = 'ChiRho']">
            <h4>crux</h4>
            <p>Yes <xsl:apply-templates select="//t:layout//t:ab[@type = 'ChiRho']"/>
            </p>
        </xsl:if>
        </div>
    </xsl:template>
</xsl:stylesheet>