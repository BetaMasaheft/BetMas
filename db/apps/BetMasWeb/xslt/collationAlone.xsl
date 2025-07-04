<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:variable name="mainID" select="ancestor-or-self::t:TEI/@xml:id"/>
    <xsl:template match="t:collation">
        <xsl:variable name="mspartID">
            <xsl:if test="./ancestor::t:msPart">
                <xsl:value-of select="./ancestor::t:msPart[1]/@xml:id"/>
            </xsl:if>
        </xsl:variable>
        <h3>
            <span class="w3-tooltip">Quire Structure <span class="w3-text w3-tag w3-gray">Collation</span></span>
            <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart[1]/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart[1]/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:if test=".//t:signatures/text()">
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

                <button type="button" class="w3-button w3-red" onclick=" openAccordion('collation{$mspartID}')">Quire Table</button>
                <div class="collation w3-hide" id="collation{$mspartID}">
                    <table class="w3-table">
                        <tr>
                            <th>Position</th>
                            <th>Number</th>
                            <th>Leaves</th>
                            <th>Quires</th>
                            <th>Description</th>
                        </tr>
                        <xsl:for-each select=".//t:item">
                            <xsl:sort select="position()"/>
                            <xsl:variable name="dim" select="if (t:dim) then t:dim[@unit = 'leaf'] else  number(t:locus[@to]) - number(t:locus[@from]) + 1"/>
                            <tr>
                                <td>
                                    <xsl:attribute name="id">
                                        <xsl:value-of select="@xml:id"/>
                                    </xsl:attribute>
                                    <xsl:value-of select="position()"/>
                                </td>
                                <td>
                                    <xsl:value-of select="@n"/>
                                </td>
                                <td>
                                    <xsl:value-of select="$dim"/>
                                </td>
                                <td>
                                    <xsl:apply-templates select="t:locus[parent::t:item]"/>
                                </td>
                                <td>
                                    <xsl:apply-templates select="child::node() except (t:locus | t:dim)"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table>
                </div>
                <xsl:variable name="dimensionandstubs">
                    <xsl:for-each select=".//t:list/t:item">
                        <xsl:variable name="text" select="string-join(./text(), ' ')"/>
                        <xsl:variable name="dim" select="if (t:dim) then t:dim[@unit = 'leaf'] else  (number(t:locus[@to]) - number(t:locus[@from]) + 1)"/>
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
                                <xsl:value-of select="$dim"/>
                            </dimensions>
                            <stubs>
                                <xsl:value-of select="count($stubs)"/>
                            </stubs>
                        </item>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="not(.//t:list/t:item/t:dim)">
                        <div class="w3-panel w3-black">
                            <p>
                                <b>It is unfortunately not possible with the information provided to
                                    print the collation diagrams and formula. </b>
                            </p>                            
                            <p>The text information provided in the record is: <br/><xsl:value-of select="string-join(.//t:list/node())"/></p>
                        </div>
                    </xsl:when>
                    <xsl:when test="$dimensionandstubs//item[child::dimensions[not(@xml:lang)][. mod 2 = 0]][child::stubs[. mod 2 != 0]]">
                        <div class="w3-panel w3-black">
                            <p>
                                <b>It is unfortunately not possible with the information provided to
                                    print the collation diagrams and formula. </b>
                            </p>
                            <ul>
                                <xsl:for-each select="$dimensionandstubs//item[child::dimensions[not(@xml:lang)][. mod 2 = 0]][child::stubs[. mod 2 != 0]]">
                                    <li>
                                        <xsl:value-of select="concat('Quire with id:', id, ' and n ', n, ' is made of an even number of leaves (', dimensions, '), but the number of stubs is odd.')"/>
                                    </li>
                                </xsl:for-each>
                            </ul>
                            <p>The text information provided in the record is: <br/><xsl:value-of select="string-join(.//t:list/node())"/></p>
                        </div>
                    </xsl:when>
                    <xsl:when test="not(.//t:list/t:item[not(matches(text()[last()], '\d+'))][./t:dim[@unit = 'leaf'][. mod 2 != 0]])">

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
                        <button type="button" class="w3-button w3-red" onclick=" openAccordion('collationFormula{$mspartID}')">Collation
                            Formula </button>
                        <div id="collationFormula{$mspartID}" class="w3-container w3-hide">
                            <p>Ethio-SPaRe formula : <xsl:for-each select=".//t:item">
                                    <xsl:sort select="                                             if (@n) then                                                 number(@n)                                             else                                                 number(replace(@xml:id, 'q', ''))" order="ascending"/>
                                    <xsl:value-of select="t:num"/>
                                    <xsl:choose>
                                        <xsl:when test="matches(@n, '[A-Za-z]')">
                                            <xsl:value-of select="@n"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:variable name="val" select="                                                     if (@n) then                                                         string(@n)                                                     else                                                         replace(@xml:id, 'q', '')"/>
                                            <xsl:number value="$val" format="I"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:text>(</xsl:text>
                                <xsl:variable name="dim"
                                    select="if (t:dim[@unit='leaf']) then t:dim[@unit='leaf'] else number(t:locus[@to]) - number(t:locus[@from]) + 1"/>
                                    <xsl:choose>
                                        <xsl:when test="contains(string-join(text()), 'stub')">
                                            <xsl:variable name="text" select="string-join(text(), ' ')"/>
                                            <xsl:variable name="stubs">
                                                <xsl:analyze-string select="$text" regex="stub">
                                                  <xsl:matching-substring>1</xsl:matching-substring>
                                                </xsl:analyze-string>
                                            </xsl:variable>
                                            <xsl:variable name="countstubs" select="string-length($stubs)"/>
                                            <xsl:value-of select="number(t:dim[1]) - number($countstubs)"/>+<xsl:value-of select="$countstubs"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="$dim"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:text>/</xsl:text>
                                    <xsl:if test="contains(string-join(text()), 'stub')">
                                        <xsl:variable name="text" select="string-join(text(), ' ')"/>
                                        <xsl:variable name="stubs">
                                            <xsl:analyze-string select="$text" regex="((\d+)(,?)(\s?)(no\s)?((stub|added|replaced|missing)(\s+)?)(after|before)?(\s?)(\d+)?)">
                                                <xsl:matching-substring><single>s.l. <xsl:value-of select="regex-group(1)"/></single></xsl:matching-substring>
                                            </xsl:analyze-string>
                                        </xsl:variable>
                                        <xsl:value-of select="string-join($stubs//text(), '; ')"/>
                                        <xsl:text>/</xsl:text>
                                    </xsl:if>
                                    <xsl:apply-templates select="t:locus"/>
                                    <xsl:text>)</xsl:text>
                                    <xsl:text> – </xsl:text>
                                </xsl:for-each>
                            </p>
                            <p>Formula: <xsl:for-each select=".//t:item">
                                    <xsl:sort select="position()"/>
                                <xsl:apply-templates select="t:locus[@from or @to]"/>
                                    <xsl:value-of select="text()"/>
                                    <xsl:text>; </xsl:text>
                                </xsl:for-each>
                            </p>
                            <p>Formula 1: <xsl:for-each select="$visColl//t:quire">
                                    <!-- to be in the format 1(8, -4, +3) -->
                                    <xsl:variable name="quire-no" select="@n"/>
                                    <xsl:variable name="no-leaves" select="child::t:leaf[last()]/@n"/>
                                    <xsl:value-of select="$quire-no"/> (<xsl:value-of select="$no-leaves"/>
                                    <xsl:for-each select="child::t:leaf[@mode = 'missing']">,
                                            -<xsl:value-of select="@n"/>
                                    </xsl:for-each>
                                    <xsl:for-each select="child::t:leaf[@mode = 'added']">,
                                            +<xsl:value-of select="@n"/>
                                    </xsl:for-each>
                                    <xsl:for-each select="child::t:leaf[@mode = 'replaced']">, leaf
                                        in position <xsl:value-of select="@n"/> has been
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
                                            <xsl:when test="preceding-sibling::t:leaf">, leaf
                                                missing after fol. <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
                                            </xsl:when>
                                            <xsl:otherwise>, first leaf is missing</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                    <xsl:for-each select="child::t:leaf[@mode = 'added']">
                                        <xsl:choose>
                                            <xsl:when test="preceding-sibling::t:leaf">, leaf added
                                                after fol. <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
                                            </xsl:when>
                                            <xsl:otherwise>, first leaf is added</xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:for-each>
                                    <xsl:for-each select="child::t:leaf[@mode = 'replaced']">
                                        <xsl:choose>
                                            <xsl:when test="preceding-sibling::t:leaf">, leaf
                                                replaced after fol. <xsl:value-of select="preceding-sibling::t:leaf[1]/@folio_number"/>
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
                                <b>It is unfortunately not possible with the information provided to
                                    print the collation diagrams and formula. </b>
                            </p>
                            <ul>
                                <xsl:for-each select="//t:list/t:item[not(matches(text()[last()], '\d+'))][./t:dim[@unit = 'leaf'][. mod 2 != 0]]">
                                    <li>
                                        <xsl:value-of select="concat('Quire with id:', @xml:id, ' and n ', @n, ' is made of ', t:dim[@unit = 'leaf']/text(), ' leaves, but there is no futher information about the reason this number is odd.')"/>
                                    </li>
                                </xsl:for-each>
                            </ul>
                            <p>The text information provided in the record is: <br/><xsl:value-of select="string-join(.//t:list/node())"/></p>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
                <!--             TESTING THING -->
                <!--                <div><xsl:copy-of select="$visColl"/></div>-->

            </div>
        </xsl:if>
    </xsl:template>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="collationstep1.xsl"/>
    <xsl:include href="collationstep2.xsl"/>
    <xsl:include href="collationstep3.xsl"/>
    <xsl:include href="collationstep4.xsl"/>
    <xsl:include href="collationdiagrams.xsl"/>
</xsl:stylesheet>