<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:ref">
        <xsl:choose>

<!--this outputs in general for each ref[@corresp] a link. when this should output the computed name reference of the 
                item class="MainTitle" data-value="{$filename} are added which are then used by javascript title.js to call the restxq and get the title-->
            
            <!--            considers if ref is empty or not. start from cases in which is not-->
            <xsl:when test="text()">
                <!--                ref can take type and corresp or target-->
                <xsl:choose>
                    <xsl:when test="@cRef">
                    <xsl:choose>    
                    <xsl:when test="starts-with(@cRef, 'urn:cts:')">
                    <a href="http://data.perseus.org/citations/{@cRef}">
                            <xsl:value-of select="."/>
                        </a>
                        </xsl:when>
                        <xsl:when test="starts-with(@cRef, 'urn:dts:betmas')">
                        <xsl:variable name="id" select="substring-before(substring-after(@cRef, 'urn:dts:betmas:'), ':')"/>
                            <xsl:variable name="loc" select="substring-after(substring-after(@cRef, 'urn:dts:betmas:'), ':')"/>
                            <xsl:variable name="value" select="concat($id,'/',replace($loc, '\.', '/'))"/>
                            
                            <a class="reference" data-bmid="{$id}" data-value="{$value}">
                           <xsl:value-of select="."/> 
                        </a>
                        </xsl:when>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="@target">
                        <xsl:choose>
                            <!--                            multiple entries-->
                            <xsl:when test="contains(@target, ' ')">
                                <xsl:for-each select="tokenize(@target, ' ')">
                                    <a href="{.}">
                                        <xsl:value-of select="."/>
                                    </a>
                                </xsl:for-each>
                            </xsl:when>
                            <!-- one entry-->
                            <xsl:otherwise>
                                <a href="{@target}">
                                    <xsl:value-of select="."/> <xsl:value-of select="if (contains(@target, '#')) then concat(' (',substring-after(@target, '#'), ')') else ()"/>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="relsid" select="generate-id()"/>

                        <!--assumes corresp and type-->
                        <xsl:choose>

                            <!--                            multiple entries, will first print link to each corresp value and then apply templates to the content of ref.  -->
                            <xsl:when test="contains(@corresp, ' ')">
                                <xsl:for-each select="tokenize(@corresp, ' ')">
                                    <xsl:variable name="filename">
                                        <xsl:choose>
                                            <xsl:when test="contains(., '#')">
                                                <xsl:value-of select="substring-before(., '#')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <xsl:variable name="collection">
                                        <xsl:choose>
                                            <xsl:when test="starts-with($filename, 'PRS') or starts-with($filename, 'ETH')">persons</xsl:when>
                                            <xsl:when test="starts-with($filename, 'LOC')">places</xsl:when>
                                            <xsl:when test="starts-with($filename, 'INS')">institutions</xsl:when>
                                            <xsl:when test="starts-with($filename, 'LIT')">works</xsl:when>
                                            <xsl:when test="starts-with($filename, 'NAR')">narratives</xsl:when>
                                            <xsl:when test="document('../data/authority-files/taxonomy.xml')//t:catDesc[text() = $filename]">authority-files</xsl:when>
                                            <xsl:otherwise>manuscripts</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <a href="{.}" class="MainTitle" data-value="{.}">
                                        <xsl:value-of select="."/>
                                    </a>
                                    <a id="{$relsid}Ent{$filename}relations">
                                        <xsl:text>  </xsl:text>
                                        <span class="glyphicon glyphicon-hand-left"/>
                                    </a>
                                </xsl:for-each>
                                <xsl:apply-templates/> <!--to any child node of this ref with multiple corresp values-->
                            </xsl:when>
                            
                            
                            <!--one entry, it does not loop, thus the attribute node containing the reference is named every time in the functions
                            the text of the reference is the one contained in the source file-->
                            <xsl:otherwise>
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
                                <xsl:variable name="collection">
                                    <xsl:choose>
                                        <xsl:when test="starts-with($filename, 'PRS') or starts-with($filename, 'ETH')">persons</xsl:when>
                                        <xsl:when test="starts-with($filename, 'LOC')">places</xsl:when>
                                        <xsl:when test="starts-with($filename, 'INS')">institutions</xsl:when>
                                        <xsl:when test="starts-with($filename, 'LIT')">works</xsl:when>
                                        <xsl:when test="starts-with($filename, 'NAR')">narratives</xsl:when>
                                        <xsl:when test="document('../data/authority-files/taxonomy.xml')//t:catDesc[text() = $filename]">authority-files</xsl:when>
                                        <xsl:otherwise>manuscripts</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <a href="{@corresp}">
                                    <xsl:apply-templates/>
                                </a> 
                                        <!--the content of the link is the content of the ref, no class="MainTitle" data-value="{$filename} are added as there is no need to print these references-->
                                <a id="{$relsid}Ent{$filename}relations">
                                    <xsl:text>  </xsl:text>
                                    <span class="glyphicon glyphicon-hand-left"/>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!--            ref used empty-->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@target">
                        <xsl:choose>
                            <!--                            multiple entries-->
                            <xsl:when test="contains(@target, ' ')">
                                <xsl:if test="not(contains(@target, 'http')) and not(@type)">
                                    <xsl:text>nos. </xsl:text>
                                </xsl:if>
                                <xsl:for-each select="tokenize(@target, ' ')">
                                    <xsl:variable name="id" select="."/>
                                    <a href="{$id}">
                                        <xsl:value-of select="concat(if (contains(., '#')) then substring-after(., '#') else ., ' ')"/>
                                    </a>
                                    <xsl:text> </xsl:text>
                                </xsl:for-each>
                            </xsl:when>
                            <!-- one entry-->
                            <xsl:otherwise>
                                <xsl:variable name="id" select="substring-after(@target, '#')"/>
                                <a>
                                    <xsl:variable name="match" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
                                    <xsl:choose>
                                        <xsl:when test="$match/name() = 'div'">
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="concat('../../text/',ancestor::t:TEI/@xml:id,@target)"/>
                                            </xsl:attribute>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="@target"/>
                                            </xsl:attribute>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:choose>
                                        <xsl:when test="starts-with($id, 't')">
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:title[@xml:id = $id]"/>
                                        </xsl:when>
                                        <xsl:when test="starts-with($id, 'h')">
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:handNote[@xml:id = $id]/@xml:id"/>
                                        </xsl:when>
                                        <xsl:when test="starts-with($id, 'e')">
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:item[@xml:id = $id]/@xml:id"/>
                                        </xsl:when>
                                        <xsl:when test="starts-with($id, 'a')">
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:item[@xml:id = $id]/@xml:id"/>
                                        </xsl:when>
                                        <xsl:when test="starts-with($id, 'q')">
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:item[@xml:id = $id]/@xml:id"/>
                                        </xsl:when>
                                        <xsl:when test="$match/name() = 'div'">
                                            <xsl:value-of select="$match/@subtype"/>
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="$match/@n"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <!--
                                                why should a n be added? 
                                                <xsl:if test="not(contains(@target, 'http'))">
                                                <xsl:text>n. </xsl:text>
                                            </xsl:if>-->
                                            <xsl:value-of select="current()//ancestor::t:TEI//t:*[@xml:id = $id]/@xml:id"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="relsid" select="generate-id()"/>


                        <!--assumes corresp and type-->
                        <xsl:choose>
                            <xsl:when test="contains(@corresp, ' ')">
                                <xsl:for-each select="tokenize(@corresp, ' ')">
                                    <xsl:variable name="filename">
                                        <xsl:choose>
                                            <xsl:when test="contains(., '#')">
                                                <xsl:value-of select="substring-before(., '#')"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="."/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <xsl:variable name="collection">
                                        <xsl:choose>
                                            <xsl:when test="starts-with($filename, 'PRS') or starts-with($filename, 'ETH')">persons</xsl:when>
                                            <xsl:when test="starts-with($filename, 'LOC')">places</xsl:when>
                                            <xsl:when test="starts-with($filename, 'INS')">institutions</xsl:when>
                                            <xsl:when test="starts-with($filename, 'LIT')">works</xsl:when>
                                            <xsl:when test="starts-with($filename, 'NAR')">narratives</xsl:when>
                                            <xsl:when test="document('../data/authority-files/taxonomy.xml')//t:catDesc[text() = $filename]">authority-files</xsl:when>
                                            <xsl:otherwise>manuscripts</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:variable>
                                    <a href="{.}" class="MainTitle" data-value="{.}">
                                        <xsl:value-of select="$filename"/>
                                    </a>
                                    <a id="{$relsid}Ent{$filename}relations">
                                        <xsl:text>  </xsl:text>
                                        <span class="glyphicon glyphicon-hand-left"/>
                                    </a>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                <!--one entry-->
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
                                <xsl:variable name="collection">
                                    <xsl:choose>
                                        <xsl:when test="starts-with($filename, 'PRS') or starts-with($filename, 'ETH')">persons</xsl:when>
                                        <xsl:when test="starts-with($filename, 'LOC')">places</xsl:when>
                                        <xsl:when test="starts-with($filename, 'INS')">institutions</xsl:when>
                                        <xsl:when test="starts-with($filename, 'LIT')">works</xsl:when>
                                        <xsl:when test="starts-with($filename, 'NAR')">narratives</xsl:when>
                                        <xsl:when test="document('../data/authority-files/taxonomy.xml')//t:catDesc[text() = $filename]">authority-files</xsl:when>
                                        <xsl:otherwise>manuscripts</xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <a href="{@corresp}" class="MainTitle" data-value="{@corresp}">
                                    <xsl:value-of select="$filename"/>
                                </a>
                                <a id="{$relsid}Ent{$filename}relations">
                                    <xsl:text>  </xsl:text>
                                    <span class="glyphicon glyphicon-hand-left"/>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>
    </xsl:template>
</xsl:stylesheet>