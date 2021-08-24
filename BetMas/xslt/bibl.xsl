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
                                        <xsl:for-each select="$ref/t:witness">
                                            <xsl:value-of select="t:title"/>
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
                                    <xsl:for-each select="$ref/t:witness">
                                        <xsl:value-of select="t:title"/>
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
            <xsl:for-each select="t:bibl">
                <xsl:sort select="author"/>
                <xsl:sort select="date"/>
                <xsl:sort select="title"/>
                <xsl:apply-templates select="."/>
            </xsl:for-each>
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
                      <xsl:apply-templates mode="bibl" select="."/>
                    
                </xsl:when>
                <xsl:otherwise>
              <xsl:apply-templates mode="bibl" select="."/>
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
                <xsl:apply-templates select="." mode="intextbibl"/>
             
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
                
                <xsl:apply-templates select="." mode="intextbibl"/>

            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template mode="intextbibl" match="t:bibl">
        <span class="Zotero Zotero-citation" data-value="{t:ptr/@target}">
            <xsl:if test="t:citedRange">
                <xsl:attribute name="data-unit">
                    <xsl:value-of select="t:citedRange/@unit"/>
                </xsl:attribute>
                <xsl:attribute name="data-range">
                    <xsl:value-of select="t:citedRange"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:variable name="authors"><xsl:for-each select="t:author|t:editor"><xsl:apply-templates select="." mode='bibl'/></xsl:for-each></xsl:variable>
            <xsl:value-of select="$authors" separator=", "/>
            <xsl:apply-templates select="t:date" mode='bibl'/>
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="t:citedRange" mode='bibl'/>
        </span>
    </xsl:template>
    <xsl:template mode="bibl" match="t:bibl">
        <xsl:variable name="t" select="t:ptr/@target"/>
        <div class="w3-row">
            <div class="w3-col"  style="width:85%">
                <span class="Zotero Zotero-full" data-value="{$t}" data-type="{t:seg/@type}">
            <xsl:if test="t:citedRange">
                <xsl:attribute name="data-unit">
                    <xsl:value-of select="t:citedRange/@unit"/>
                </xsl:attribute>
                <xsl:attribute name="data-range">
                    <xsl:value-of select="t:citedRange"/>
                </xsl:attribute>
            </xsl:if>
        <xsl:if test="t:author|t:editor">
            <xsl:for-each select="t:author|t:editor"><xsl:apply-templates select="." mode='bibl'/><xsl:text>, </xsl:text></xsl:for-each>
            </xsl:if>
            <xsl:apply-templates select="t:date" mode='bibl'/>
            <xsl:text>, </xsl:text>
                    <xsl:variable name="titles" select="count(./t:title)"/>
                 <xsl:for-each select="t:title">
                     <xsl:variable name="position" select="position()"/>
                     <xsl:apply-templates select="." mode='bibl'/><xsl:if test="$titles!=$position"><xsl:text> </xsl:text></xsl:if>
                    </xsl:for-each>
            <xsl:text>, </xsl:text>
                   <xsl:if test="t:pubPlace"> <xsl:value-of select="t:pubPlace"/>
                    <xsl:text>: </xsl:text></xsl:if>
                    <xsl:if test="t:publisher"><xsl:value-of select="t:publisher"/></xsl:if>
                    <xsl:apply-templates select="t:citedRange" mode='bibl'/>
                    <xsl:text> </xsl:text>
        <xsl:apply-templates select="t:note[@type='about']"/>
                    <xsl:text> </xsl:text>
            <xsl:if test="t:ref"><a href="{t:ref/@target}">[link]</a></xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:if test="t:note[@type='accessed']">Accessed: <xsl:value-of select="t:note[@type='accessed']"/></xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="t:note[not(@type)]"/>
<!--                    ignoring biblScope-->
                    <xsl:text>. </xsl:text>
                </span></div><div class="w3-rest">
        <span class="w3-bar-block w3-hide-small w3-hide-medium">
            <a class="w3-bar-item w3-button w3-tiny" href="https://api.zotero.org/groups/358366/items?&amp;tag={$t}&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies">HLZ CSL style</a>
            <a class="w3-bar-item w3-button w3-tiny" target="_blank" href="https://www.zotero.org/groups/358366/ethiostudies/tags/{$t}/library">Zotero</a>
            <a class="w3-bar-item w3-button w3-tiny" href="/bibliography?pointer={$t}">Other citations</a>
        </span>
                
                </div></div><hr></hr>
    </xsl:template>
    
    <xsl:template match="t:author|t:editor" mode="bibl">
        <xsl:variable name="nodes" select="count(./node())"/>
            <xsl:for-each select="./node()">
                <xsl:variable name="position" select="position()"/>
                <xsl:value-of select="."/><xsl:if test="$nodes!=$position"><xsl:text> </xsl:text></xsl:if>
            </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:date" mode="bibl">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="t:title" mode="bibl">
        <xsl:choose>
            <xsl:when test="@type='short'"> (<xsl:value-of select="."/>)</xsl:when>
            <xsl:when test="@level='a'"> "<xsl:value-of select="."/>"</xsl:when>
            <xsl:when test="@level='j'"> in <i><xsl:value-of select="."/></i></xsl:when>
            <xsl:when test="@level='s'"> in series <i><xsl:value-of select="."/></i></xsl:when>
            <xsl:when test="@level='m'"> <i><xsl:value-of select="."/></i></xsl:when>
            <xsl:otherwise> <i><xsl:value-of select="."/></i></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:citedRange" mode="bibl">
        <xsl:value-of select="@unit"/><xsl:text> </xsl:text><xsl:value-of select="."/>
    </xsl:template>
    
</xsl:stylesheet>