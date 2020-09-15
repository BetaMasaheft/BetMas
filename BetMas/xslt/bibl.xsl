<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:listBibl[not(ancestor::t:note)]">
        <xsl:if test="not(parent::t:item) and not(ancestor::t:physDesc)">
            <!--this test simply excludes the title from a bibliography appearing in an item. it might be extended to cover more cases. decoNote, handNote?-->
            <h4>
                <xsl:if test="@type = 'catalogue'">
                    <xsl:attribute name="id">catalogue</xsl:attribute>
                </xsl:if>
                <xsl:value-of select="concat(concat(upper-case(substring(@type, 1, 1)), substring(@type, 2), ' '[not(last())]), ' Bibliography')"/>
                <xsl:if test="./ancestor::t:msPart[1]">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart[1]/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart[1]/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
                <xsl:if test="./ancestor::t:msItem[1]">
                    <xsl:variable name="currentMsItem">
                        <a href="{./ancestor::t:msItem[1]/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msItem[1]/@xml:id, 'i')"/>
                        </a>
                    </xsl:variable>, item <xsl:value-of select="$currentMsItem"/>
                </xsl:if>
                <xsl:if test="@corresp">
                    <xsl:choose>
                        <xsl:when test="contains(@corresp, ' ')">
                            <xsl:text> (about: </xsl:text>
                            <xsl:variable name="file" select="ancestor::t:TEI"/>
                            <xsl:for-each select="tokenize(@corresp, ' ')">
                                <xsl:variable name="id" select="                                         if (contains(., '#')) then                                             substring-after(., '#')                                         else                                             ."/>
                                <xsl:variable name="ref" select="$file//t:*[@xml:id = $id]"/>
                                <xsl:choose>
                                    <xsl:when test="$ref/text()">
                                        <xsl:value-of select="$ref/text()"/>
                                    </xsl:when>
                                    <xsl:when test="$ref/name() = 'listWit'">
                                        <xsl:for-each select="$ref/t:witness/@corresp">
                                            <span class="MainTitle" data-value=".">
                                                <xsl:value-of select="."/>
                                            </span>
                                            <xsl:text> </xsl:text>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat($ref/name(), ' ')"/>
                                        <span class="MainTitle" data-value="{$ref/@corresp}">
                                            <xsl:value-of select="$ref/@corresp"/>
                                        </span>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:text> </xsl:text>
                                <xsl:if test="$ref/@xml:lang">
                                    <xsl:value-of select="concat(' [', $file//t:language[@ident = $ref/@xml:lang], ']')"/>
                                </xsl:if>
                                <xsl:text> </xsl:text>
                            </xsl:for-each>
                            <xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="id" select="                                     if (contains(@corresp, '#')) then                                         substring-after(@corresp, '#')                                     else                                         @corresp"/>
                            <xsl:variable name="ref" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
                            <xsl:text> (about: </xsl:text>
                            <xsl:choose>
                                <xsl:when test="$ref/text()">
                                    <xsl:value-of select="$ref/text()"/>
                                </xsl:when>
                                <xsl:when test="$ref/name() = 'listWit'">
                                    <xsl:for-each select="$ref/t:witness/@corresp">
                                        <span class="MainTitle" data-value=".">
                                            <xsl:value-of select="."/>
                                        </span>
                                        <xsl:text> </xsl:text>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat($ref/name(), ' ')"/>
                                    <span class="MainTitle" data-value="{$ref/@corresp}">
                                        <xsl:value-of select="$ref/@corresp"/>
                                    </span>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text> </xsl:text>
                            <xsl:if test="$ref/@xml:lang">
                                <xsl:value-of select="concat(' [', current()//ancestor::t:TEI//t:language[@ident = $ref/@xml:lang], ']')"/>
                            </xsl:if>
                            <xsl:text> </xsl:text>
                            <xsl:text>)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </h4>
        </xsl:if>
        <ul class="bibliographyList">
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    
    <xsl:template match="t:bibl[parent::t:surrogates]">
        <p><xsl:apply-templates/></p>
    </xsl:template>
    <xsl:template match="t:bibl[parent::t:listBibl][not(ancestor::t:note)]">
        <li class="bibliographyItem">
            <xsl:if test="@xml:id">
                <xsl:attribute name="id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="not(@corresp) and not(t:ptr[@target])">
                    <b style="color:red;">THIS BIBLIOGRAPHIC RECORD IS WRONGLY ENCODED. Please check
                        the schema error report to fix it.</b>
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:when test="@corresp and not(t:ptr[@target])">
                    <a href="{@corresp}">
                        <xsl:value-of select="@corresp"/>
                        <xsl:variable name="filename">
                            <xsl:choose>
                                <xsl:when test="contains(@corresp, '#')">
                                    <xsl:value-of select="substring-before(@corresp, '#')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="@corresp"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:if test="not(document(concat('../../manuscripts/', $filename, '.xml'))//t:TEI)">
                            <b style="color:red;                                ">**No record for
                                    <xsl:value-of select="$filename"/>** = <xsl:value-of select="."/> **</b>
                        </xsl:if>
                    </a>
                    <xsl:if test="t:date">
                        <xsl:apply-templates select="t:date"/>
                    </xsl:if>
                    <xsl:if test="t:note">
                        <xsl:apply-templates select="t:note"/>
                    </xsl:if>
                </xsl:when>
                <xsl:when test="t:ptr/@target='bm:EthioSpare' and parent::t:listBibl[@type='catalogue']">
                    <xsl:variable select="ancestor::t:TEI//t:idno[preceding-sibling::t:collection[.='Ethio-SPaRe']]" name="BMsignature"/>
                    <xsl:variable name="domliblist" select="document('../lists/domlib.xml')//*:item[*:signature = $BMsignature]/*:domlib"/>
                    <xsl:variable name="cataloguer" select="ancestor::t:TEI//t:editor[@role='cataloguer']/@key"/>
                    <xsl:variable name="edlist" select="document('../lists/editors.xml')"/>
                    <xsl:variable name="date">
                        <xsl:choose>
                            <xsl:when test="ancestor::t:TEI//t:origDate/@when">
                                <xsl:value-of select="ancestor::t:TEI//t:origDate/@when"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="ancestor::t:TEI//t:origDate/@notBefore"/>-<xsl:value-of select="ancestor::t:TEI//t:origDate/@notAfter"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <!--             
                        Example from https://mycms-vs03.rrz.uni-hamburg.de/domlib/content/below/index.xml
                        
                        MS 'Addigrat Qirqos, AMQ-007 (digitized by the Ethio-SPaRe project), Gädlä Qirqos, 18th century, Catalogued by Vitagrazia Pisani, description accessed on 15 June 2015.-->
                    <a href="https://mycms-vs03.rrz.uni-hamburg.de/domlib/receive/{$domliblist}">MS <span class="MainTitle" data-value="{ancestor::t:TEI//t:repository/@ref}"/>, 
                        <xsl:value-of select="$BMsignature"/> (digitized by the Ethio-SPaRe project), <xsl:value-of select="ancestor::t:TEI//t:titleStmt/t:title[1]/text()"/>
                        <xsl:text>, </xsl:text> 
                        <xsl:value-of select="$date"/>, Catalogued by 
                        <xsl:choose>
                            <xsl:when test="$cataloguer">
                                <xsl:value-of select="$edlist//t:item[@xml:id=$cataloguer]/text()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="creator">
                                <xsl:choose>
                                    <xsl:when test="ancestor::t:TEI//t:editor[not(@role='generalEditor')]">
                                        <xsl:value-of select="ancestor::t:TEI//t:editor[not(@role='generalEditor')]/@key"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                            <xsl:value-of select="ancestor::t:TEI//t:change[contains(., 'created')]/@who"/>
                                        </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                                <xsl:value-of select="$edlist//t:item[@xml:id=$creator]/text()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </a>
                    In
                        <span class="Zotero Zotero-full" data-value="{t:ptr/@target}">
                        <xsl:if test="t:citedRange">
                            <xsl:attribute name="data-unit">
                                <xsl:value-of select="t:citedRange/@unit"/>
                            </xsl:attribute>
                            <xsl:attribute name="data-range">
                                <xsl:value-of select="t:citedRange"/>
                            </xsl:attribute>
                        </xsl:if>
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <span class="Zotero Zotero-full" data-value="{t:ptr/@target}">
                        <xsl:if test="t:citedRange">
                            <xsl:attribute name="data-unit">
                                <xsl:value-of select="t:citedRange/@unit"/>
                            </xsl:attribute>
                            <xsl:attribute name="data-range">
                                <xsl:value-of select="t:citedRange"/>
                            </xsl:attribute>
                        </xsl:if>
                    </span>
                    <xsl:if test="//t:ptr">
                       <!-- <xsl:variable name="url">
                            <xsl:choose><xsl:when test="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target, '&format=tei'))">
                            <xsl:variable name="zotero" select="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target, '&format=tei'))"/>
                        
                            <xsl:choose>
                                <xsl:when test="$zotero//t:note[@type = 'url']">
                                    <xsl:value-of select="$zotero//t:note[@type = 'url']"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat('https://www.zotero.org/groups/ethiostudies/items/tag/', t:ptr/@target)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        
                        </xsl:when>
                                <xsl:otherwise>https://www.zotero.org/groups/358366/ethiostudies/items</xsl:otherwise></xsl:choose>
                            
                        </xsl:variable>-->

                        <!--<xsl:value-of select="if ($zotero//t:author) then (if ($zotero//t:author/t:surname) then ($zotero//t:author/t:surname) else ($zotero//t:author)) else (if ($zotero//t:editor/t:surname) then ($zotero//t:editor/t:surname) else ($zotero//t:editor))"/>
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="$zotero//t:date"/>-->
                        <!--<xsl:variable name="zotbib">
                            <xsl:copy-of
                                select="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target,'&format=bib&style=http://www1.uni-hamburg.de/ethiostudies/hiob-ludolf-centre-for-ethiopian-studies-web.csl&linkwrap=1'))/div/div/child::node()"
                            />
                        </xsl:variable>-->
                        <!--<xsl:choose>
                            <xsl:when test="t:citedRange">--><!--
                                <xsl:copy-of select="$zotbib/node()[not(position() = last())]"/>
                                <xsl:copy-of select="replace($zotbib/text()[last()], '.$', '')"/>-->
                              <!--  <xsl:if test="t:citedRange"><xsl:for-each select="t:citedRange">
                                    <xsl:sort select="position()"/>
                                    <xsl:text>, </xsl:text>
                                    <xsl:value-of select="@unit"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="."/>
                                </xsl:for-each></xsl:if>-->
                            <!--</xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="$zotbib"/>
                            </xsl:otherwise>
                        </xsl:choose>-->
                      <!--  <a href="{$url}">
                            <xsl:text>  </xsl:text>
                            <span class="glyphicon glyphicon-share"/>
                        </a>-->
                        <xsl:if test="@corresp">
                            <xsl:choose>
                                <xsl:when test="contains(@corresp, ' ')">
                                    <xsl:text> (about: </xsl:text>
                                    <xsl:variable name="file" select="ancestor::t:TEI"/>
                                    <xsl:for-each select="tokenize(@corresp, ' ')">
                                        <xsl:variable name="id" select="                                                 if (contains(., '#')) then                                                     substring-after(., '#')                                                 else                                                     ."/>
                                        <xsl:variable name="ref" select="$file//t:*[@xml:id = $id]"/>
                                        <xsl:choose>
                                            <xsl:when test="$ref/text()">
                                                <xsl:value-of select="$ref/text()"/>
                                            </xsl:when>
                                            <xsl:when test="$ref/name() = 'listWit'">
                                                <xsl:for-each select="$ref/t:witness/@corresp">
                                                    <span class="MainTitle" data-value=".">
                                                        <xsl:value-of select="."/>
                                                    </span>
                                                    <xsl:text> </xsl:text>
                                                </xsl:for-each>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="concat($ref/name(), ' ')"/>
                                                <span class="MainTitle" data-value="{$ref/@corresp}">
                                                    <xsl:value-of select="$ref/@corresp"/>
                                                </span>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:text> </xsl:text>
                                        <xsl:if test="$ref/@xml:lang">
                                            <xsl:value-of select="concat(' [', $file//t:language[@ident = $ref/@xml:lang], ']')"/>
                                        </xsl:if>
                                        <xsl:text> </xsl:text>
                                    </xsl:for-each>
                                    <xsl:text>)</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="id" select="                                             if (contains(@corresp, '#')) then                                                 substring-after(@corresp, '#')                                             else                                                 @corresp"/>
                                    <xsl:variable name="ref" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
                                    <xsl:text> (about: </xsl:text>
                                    <xsl:choose>
                                        <xsl:when test="$ref/text()">
                                            <xsl:value-of select="$ref/text()"/>
                                        </xsl:when>
                                        <xsl:when test="$ref/name() = 'listWit'">
                                            <xsl:for-each select="$ref/t:witness/@corresp">
                                                <span class="MainTitle" data-value=".">
                                                    <xsl:value-of select="."/>
                                                </span>
                                                <xsl:text> </xsl:text>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat($ref/name(), ' ')"/>
                                            <span class="MainTitle" data-value="{$ref/@corresp}">
                                                <xsl:value-of select="$ref/@corresp"/>
                                            </span>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:text> </xsl:text>
                                    <xsl:if test="$ref/@xml:lang">
                                        <xsl:value-of select="concat(' [', current()//ancestor::t:TEI//t:language[@ident = $ref/@xml:lang], ']')"/>
                                    </xsl:if>
                                    <xsl:text> </xsl:text>
                                    <xsl:text>)</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                    </xsl:if>
                    <xsl:if test="t:note">
                        <xsl:text> </xsl:text>
                        <xsl:apply-templates select="t:note"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>
    <xsl:template match="t:listBibl[ancestor::t:note]">
        <xsl:apply-templates mode="intext"/>
    </xsl:template>
    <xsl:template match="t:bibl" mode="intext">
        <xsl:choose>
            <xsl:when test="not(@corresp) and not(t:ptr[@target])">
                <b style="color:red;">THIS BIBLIOGRAPHIC RECORD IS WRONGLY ENCODED. Please check the
                    schema error report to fix it.</b>
                <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="@corresp">
                <a href="{@corresp}">
                    <xsl:value-of select="text()"/>
                </a>
                <xsl:if test="t:date">
                    <xsl:apply-templates select="t:date"/>
                </xsl:if>
                <xsl:if test="t:note">
                    <xsl:apply-templates select="t:note"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <a class="Zotero Zotero-citation" data-value="{t:ptr/@target}">
                    <xsl:if test="t:citedRange">
                        <xsl:attribute name="data-unit">
                            <xsl:value-of select="t:citedRange/@unit"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-range">
                            <xsl:value-of select="t:citedRange"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                </a>
             
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:bibl[not(parent::t:listBibl)][not(parent::t:surrogates)]">
        <xsl:choose>
            <xsl:when test="not(@corresp) and not(t:ptr[@target])">
                <b style="color:red;">THIS BIBLIOGRAPHIC RECORD
                    IS WRONGLY ENCODED. Please check the schema error report to fix it.</b>
                <xsl:value-of select="."/>
            </xsl:when>
            <xsl:when test="@corresp">
                <a href="{@corresp}">
                    <xsl:value-of select="text()"/>
                </a>
                <xsl:if test="t:date">
                    <xsl:apply-templates select="t:date"/>
                </xsl:if>
                <xsl:if test="t:note">
                    <xsl:apply-templates select="t:note"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <a class="Zotero Zotero-citation" data-value="{t:ptr/@target}">
                    <xsl:if test="t:citedRange">
                        <xsl:attribute name="data-unit">
                            <xsl:value-of select="t:citedRange/@unit"/>
                        </xsl:attribute>
                        <xsl:attribute name="data-range">
                            <xsl:value-of select="t:citedRange"/>
                        </xsl:attribute>
                    </xsl:if>
                </a>
                <!--<xsl:if test="//t:ptr">
                    <xsl:variable name="zotero"
                        select="document(concat('https://api.zotero.org/groups/358366/items?tag=',t:ptr/@target, '&format=tei'))"/>
                    <xsl:variable name="url">
                        <xsl:choose>
                            <xsl:when test="$zotero//t:note[@type = 'url']">
                                <xsl:value-of select="$zotero//t:note[@type = 'url']"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of
                                    select="concat('https://www.zotero.org/groups/ethiostudies/items/tag/', t:ptr/@target)"
                                />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="author">
                        <xsl:if test="$zotero//t:author">
                            <xsl:for-each select="$zotero//t:author">
                                <author>
                                    <xsl:value-of
                                        select="
                                            if (./t:surname) then
                                                (./t:surname)
                                            else
                                                (.)"
                                    />
                                </author>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:variable name="authors">
                        <xsl:choose>
                            <xsl:when test="count($author/author) >= 3">
                                <xsl:value-of select="string-join($author/author, ', ')"/>
                            </xsl:when>
                            <xsl:when test="count($author/author) = 2">
                                <xsl:value-of select="string-join($author/author, ' and ')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$author/author"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="editor">
                        <xsl:if test="$zotero//t:editor">
                            <xsl:for-each select="$zotero//t:editor">
                                <editor>
                                    <xsl:value-of
                                        select="
                                            if (./t:surname) then
                                                (./t:surname)
                                            else
                                                (.)"
                                    />
                                </editor>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:variable name="editors">
                        <xsl:choose>
                            <xsl:when test="count($editor/editor) >= 3">
                                <xsl:value-of select="string-join($editor/editor, ', ')"/>
                            </xsl:when>
                            <xsl:when test="count($editor/editor) = 2">
                                <xsl:value-of select="string-join($editor/editor, ' and ')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$editor/editor"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <a xmlns="http://www.w3.org/1999/xhtml" href="{$url}">
                        <xsl:value-of
                            select="
                                if ($zotero//t:author) then
                                    $authors
                                else
                                    $editors"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$zotero//t:date"/>
                        
                    </a>
                    
                </xsl:if>-->
                <!--<xsl:if test="t:citedRange">
                            <xsl:for-each select="t:citedRange">
                                <xsl:sort select="position()"/>
                                <xsl:text>, </xsl:text>
                                <xsl:value-of select="@unit"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="."/>
                            </xsl:for-each>
                        </xsl:if>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>