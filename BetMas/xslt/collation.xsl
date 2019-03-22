<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:collation">
        <xsl:variable name="mspartID">
            <xsl:if test="./ancestor::t:msPart">
                <xsl:value-of select="./ancestor::t:msPart/@xml:id"/>
            </xsl:if>
        </xsl:variable>
        <h3>Collation <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit
            <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:if test=".//t:signatures">
            <p>
                <b>Signatures: </b>
                <xsl:apply-templates select=".//t:signatures"/>
            </p>
        </xsl:if>
        <xsl:if test=".//t:note[parent::t:collation]">
            <div>
                <xsl:apply-templates select=".//t:note"/>
            </div>
        </xsl:if>

        <xsl:if test="t:list">
        <div class="w3-container allCollation">
            
            <button type="button" class="w3-button w3-red" onclick=" openAccordion('collation{$mspartID}')">Quires Table</button>
            <div class="collation w3-hide QuiresTable" id="collation{$mspartID}">
                <div class="w3-col" style="width:200px">
                    <ul class="quireTableHeaders">
                        <li>Position</li>
                        <li>Number</li>
                        <li>Leaves</li>
                        <li>Quires</li>
                        <li>Description</li>
                    </ul>
                </div>
                <div class="w3-rest QuiresTableHoriz">
                    <ul class="list-inline">
                        <xsl:for-each select=".//t:item">
                            <xsl:sort select="position()"/>
                            <li class="quire">
                                <ul class="quireTableQuire">
                                    <li>
                                        <xsl:attribute name="id">
                                            <xsl:value-of select="@xml:id"/>
                                        </xsl:attribute>
                                        <xsl:value-of select="position()"/>
                                    </li>
                                    <li>
                                        <xsl:value-of select="@n"/>
                                    </li>
                                    <li>
                                        <xsl:apply-templates select="t:dim[@unit = 'leaf']/text()"/>
                                    </li>
                                    <li>
                                        <xsl:apply-templates select="t:locus[parent::t:item]"/>
                                    </li>
                                    <li>
                                        <xsl:apply-templates select="child::node() except (t:locus|t:dim)"/>
                                    </li>
                                </ul>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </div>
            <xsl:variable name="dimensionandstubs">
                    <xsl:for-each select=".//t:list/t:item">
                        <xsl:variable name="text" select="string-join(./text(), ' ')"/>
                        <xsl:variable name="stubs">
                            <xsl:analyze-string select="$text" regex="stub">
                                <xsl:matching-substring>1</xsl:matching-substring>
                            </xsl:analyze-string>
                        </xsl:variable>
                        <item>
                            <id>
                                <xsl:value-of select="@xml:id"/>
                            </id>
                            <n>
                                <xsl:value-of select="@n"/>
                            </n>
                            <dimensions>
                                <xsl:value-of select="t:dim[@unit='leaf']"/>
                            </dimensions>
                            <stubs>
                                <xsl:value-of select="count($stubs)"/>
                            </stubs>
                        </item>
                    </xsl:for-each>
                </xsl:variable>
            <xsl:choose>
                
                <xsl:when test="$dimensionandstubs//item[child::dimensions[. mod 2 = 0]][child::stubs[. mod 2 != 0]]">
                    <div class="w3-panel w3-black">
                        <p>
                            <b>It is unfortunately not possible with the information provided to print the collation diagrams and formula.
                            </b>
                        </p>
                        <ul>
                            <xsl:for-each select="$dimensionandstubs//item[child::dimensions[. mod 2 = 0]][child::stubs[. mod 2 != 0]]">
                                <li>
                                    <xsl:value-of select="concat('Quire with id:', id, ' and n ', n, ' is made of an even number of leaves (',  dimensions, '), but the number of stubs is odd.' )"/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>    
                </xsl:when>
            <xsl:when test="not(.//t:list/t:item[not(matches(text()[last()],'\d+'))][./t:dim[@unit='leaf'][. mod 2 != 0]])">
               
            <!--        visualization  -->
            <xsl:variable name="visColl">
                <xsl:call-template name="DotPorterIfy">
                    <xsl:with-param name="porterified" tunnel="yes" select="."/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="step1">
                <xsl:if test="$visColl">
                    <xsl:for-each select="$visColl">
                        <xsl:call-template name="step1">
                            <xsl:with-param name="step1ed" tunnel="yes" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="step2">
                <xsl:if test="$step1">
                    <xsl:for-each select="$step1">
                        <xsl:call-template name="step2">
                            <xsl:with-param name="step2ed" tunnel="yes" select="."/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>
            </xsl:variable>
            <xsl:variable name="step3">
                <xsl:if test="$step2">
                                <xsl:for-each select="$step2">
                    <xsl:call-template name="step3">
                        <xsl:with-param name="step3ed" tunnel="yes" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                            </xsl:if>
            </xsl:variable>
            <xsl:if test="$step3"> 
                <xsl:for-each select="$step3">
                    <xsl:call-template name="visColl">
                        <xsl:with-param name="Finalvisualization" tunnel="yes" select="."/>
                    </xsl:call-template>
                </xsl:for-each>
                        </xsl:if>

            <!--        formula-->
                <button type="button" class="w3-button w3-red" onclick=" openAccordion('collationFormula{$mspartID}')">Collation Formula </button>
            <div id="collationFormula{$mspartID}" class="w3-container w3-hide">
                <p>Formula: <xsl:for-each select=".//t:item">
                        <xsl:sort select="position()"/>
                        <xsl:apply-templates select="t:locus"/>
                        <xsl:value-of select="text()"/>
                        <xsl:text>; </xsl:text>
                    </xsl:for-each>
                </p>
                <p>Formula 1: <xsl:for-each select="$visColl//t:quire">
                        <!-- to be in the format 1(8, -4, +3) -->
                        <xsl:variable name="quire-no" select="@n"/>
                        <xsl:variable name="no-leaves" select="child::t:leaf[last()]/@n"/>
                        <xsl:value-of select="$quire-no"/> (<xsl:value-of select="$no-leaves"/>
                        <xsl:for-each select="child::t:leaf[@mode = 'missing']">, -<xsl:value-of select="@n"/>
                        </xsl:for-each>
                        <xsl:for-each select="child::t:leaf[@mode = 'added']">, +<xsl:value-of select="@n"/>
                        </xsl:for-each>
                        <xsl:for-each select="child::t:leaf[@mode = 'replaced']">, leaf in position
                                <xsl:value-of select="@n"/> has been
                        replaced</xsl:for-each>),<xsl:text> </xsl:text>
                    </xsl:for-each>
                </p>
                <p>Formula 2: <xsl:for-each select="$visColl//t:quire">
                        <!-- to be in the format 1(8, leaf missing between fol. X and fol. Y, leaf added after fol. X) -->
                        <xsl:variable name="quire-no" select="@n"/>
                        <xsl:variable name="no-leaves" select="child::t:leaf[last()]/@n"/>
                        <xsl:value-of select="$quire-no"/> (<xsl:value-of select="$no-leaves"/>
                        <xsl:for-each select="child::t:leaf[@mode = 'missing']">
                            <xsl:choose>
                                <xsl:when test="preceding-sibling::t:leaf">, leaf missing after fol.
                                        <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
                                </xsl:when>
                                <xsl:otherwise>, first leaf is missing</xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <xsl:for-each select="child::t:leaf[@mode = 'added']">
                            <xsl:choose>
                                <xsl:when test="preceding-sibling::t:leaf">, leaf added after fol.
                                        <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
                                </xsl:when>
                                <xsl:otherwise>, first leaf is added</xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        <xsl:for-each select="child::t:leaf[@mode = 'replaced']">
                            <xsl:choose>
                                <xsl:when test="preceding-sibling::t:leaf">, leaf replaced after
                                    fol. <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
                                </xsl:when>
                                <xsl:otherwise>, first leaf is replaced</xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>),<xsl:text> </xsl:text>
                    </xsl:for-each>
                </p>
            </div>
            </xsl:when>
                <xsl:otherwise>
                    <div class="w3-panel w3-black">
                    <p>
                                <b>It is unfortunately not possible with the information provided to print the collation diagrams and formula.
                    </b>
                            </p>
                        <ul>
                        <xsl:for-each select="//t:list/t:item[not(matches(text()[last()],'\d+'))][./t:dim[@unit='leaf'][. mod 2 != 0]]">
                            <li>
                                <xsl:value-of select="concat('Quire with id:', @xml:id, ' and n ', @n, ' is made of ',  t:dim[@unit='leaf']/text(), ' leaves, but there is no futher information about the reason this number is odd.' )"/>
                        </li>
                        </xsl:for-each>
                            </ul>
                    </div>
                </xsl:otherwise>
        </xsl:choose>
<!--             TESTING THING -->
<!--                <div><xsl:copy-of select="$visColl"/></div>-->
            
        </div>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>