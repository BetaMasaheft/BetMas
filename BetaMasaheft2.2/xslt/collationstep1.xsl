<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template name="DotPorterIfy">
        <xsl:param name="porterified" tunnel="yes"/>
        <collation>
            <xsl:for-each select=".//t:item">
                <xsl:sort select="position()"/>
                <quire>
                    <xsl:if test="@rend">
                        <xsl:attribute name="rend">
                            <xsl:value-of select="@rend"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="n">
                        <xsl:value-of select="position()"/>
                    </xsl:attribute>
                    <xsl:variable name="singletoncount">
                        <xsl:if test="matches(.,'stub')">
                            <xsl:analyze-string select="." regex="(\{{?\d+\}}?)(,?[\s\n]+stub[\s\n]+after[\s\n]+)(\d+)">
                                <xsl:matching-substring>1</xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:analyze-string select="." regex="(\{{?\d+\}}?)(,?[\s\n]+stub[\s\n]+before[\s\n]+)(\d+)">
                                        <xsl:matching-substring>1</xsl:matching-substring>
                                        <xsl:non-matching-substring>
                                            <xsl:analyze-string select="." regex="(\{{?\d+\}}?)(,?[\s\n]+no,?[\s\n]+stub)">
                                                <xsl:matching-substring>1</xsl:matching-substring>
                                            </xsl:analyze-string>
                                        </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                        </xsl:if>
                    </xsl:variable>
                    <xsl:call-template name="leafs">
                        <xsl:with-param name="rend">
                            <xsl:value-of select="@rend"/>
                        </xsl:with-param>
                        <xsl:with-param name="from">
                            <xsl:value-of select="substring-before(t:locus[1]/@from, 'r')"/>
                        </xsl:with-param>
                        <xsl:with-param name="to">
                            <xsl:value-of select="substring-before(t:locus[1]/@to, 'v')"/>
                        </xsl:with-param>
                        <xsl:with-param name="folio">1</xsl:with-param>
                        <xsl:with-param name="currentpos">1</xsl:with-param>
                        <xsl:with-param name="prec">
                            <xsl:value-of select="sum(preceding::t:dim[@unit='leaf'])"/>
                        </xsl:with-param>
                        <xsl:with-param name="count">
                            <xsl:value-of select="number(t:dim[@unit='leaf'])"/>
                        </xsl:with-param>
                        <xsl:with-param name="singletons">
                            <xsl:value-of select="string-length($singletoncount)"/>
                        </xsl:with-param>
                    </xsl:call-template>
                </quire>
            </xsl:for-each>
        </collation>
    </xsl:template>
    <xsl:template name="leafs">
        <xsl:param name="rend"/>
        <xsl:param name="from"/>
        <xsl:param name="to"/>
        <xsl:param name="currentpos"/>
        <xsl:param name="folio"/>
        <xsl:param name="count"/>
        <xsl:param name="prec"/>
        <xsl:param name="singletons"/>
        <xsl:variable name="position" select="$count + $singletons"/>
        
        
        <!--        extract information from string about singletons, stubs, added leafs (no stub)-->
        <xsl:variable name="singleton">
            <xsl:analyze-string select="." regex="(\{{?)(\d+)(\}}?)(,?[\s\n]+stub[\s\n]+after[\s\n]+)(\d+)">
                <xsl:matching-substring>
                    <couple>
                        <singleton>
                            <xsl:value-of select="regex-group(2)"/>
                        </singleton>
<!--                        before or after-->
                        <boa>+</boa>
                        <stub>
                            <xsl:value-of select="regex-group(5)"/>
                        </stub>
                    </couple>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:analyze-string select="." regex="(\{{?)(\d+)(\}}?)(,?[\s\n]+stub[\s\n]+before[\s\n]+)(\d+)">
                        <xsl:matching-substring>
                            <couple>
                                <singleton>
                                    <xsl:value-of select="regex-group(2)"/>
                                </singleton>
                                <!--                        before or after-->
                                <boa>-</boa>
                                <stub>
                                    <xsl:value-of select="regex-group(5)"/>
                                </stub>
                            </couple>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:analyze-string select="." regex="(\{{?)(\d+)(\}}?)(,?[\s\n]+no,?[\s\n]+stub)">
                                <xsl:matching-substring>
                                    <couple>
                                        <singleton>
                                            <xsl:value-of select="regex-group(2)"/>
                                        </singleton>
                                        <!--                        before or after-->
                                        <boa>n</boa>
                                        <stub>
                                        </stub>
                                    </couple>
                                </xsl:matching-substring>
                                <xsl:non-matching-substring>
                                    <xsl:analyze-string select="." regex="(\{{?)(\d+)(\}}?)(,?[\s\n]+added)">
                                        <xsl:matching-substring>
                                            <couple>
                                                <singleton>
                                                    <xsl:value-of select="regex-group(2)"/>
                                                </singleton>
                                                <boa>n</boa>
                                                <stub>
                                                </stub>
                                            </couple>
                                        </xsl:matching-substring>
                                    </xsl:analyze-string>
                                </xsl:non-matching-substring>
                            </xsl:analyze-string>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
<!--        looks for added, missing and replaced leafs. these should be in pairs.-->
        <xsl:variable name="notRegularLeafs">
            <notregleafs>
                <xsl:analyze-string select="." regex="(\d+)(\s)added">
                    <xsl:matching-substring>
                        <added f="{regex-group(1)}"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
                <xsl:analyze-string select="." regex="(\{{)(\d+)(\}})">
                    <xsl:matching-substring>
                        <added f="{regex-group(2)}"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
                <xsl:analyze-string select="." regex="(&lt;)(\d+)(&gt;)">
                    <xsl:matching-substring>
                        <added f="{regex-group(2)}"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
                <xsl:analyze-string select="." regex="(\d+)(\s)missing">
                    <xsl:matching-substring>
                        <missing f="{regex-group(1)}"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
                <xsl:analyze-string select="." regex="(\d+)(\s)replaced">
                    <xsl:matching-substring>
                        <replaced f="{regex-group(1)}"/>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </notregleafs>
        </xsl:variable>
        
<!--        this step creates a leaf for each actual leaf, 
            regardless if it is singleton stub or added but already adds the @mode attribute accordingly at this stage also folionumbers are added-->
        <xsl:variable name="leafs">
            <xsl:for-each select="1 to $count">
                <xsl:sort order="ascending" select="position()"/>
                
<!--                folio numbers are computed. This does not allow the visualization of quires contained in other quires-->
                <leaf n="{position()}">
                    <xsl:attribute name="folio_number">
                        <xsl:choose>
                            <xsl:when test="$rend = 'inserted in'">
                                <xsl:choose>
                                    <xsl:when test="position() = 1">
                                        <xsl:value-of select="$from"/>
                                    </xsl:when>
                                    <xsl:when test="position() = $count">
                                        <xsl:value-of select="$to"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$prec+position()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="$rend = 'with insertion'">
                                <xsl:choose>
                                    <xsl:when test="position() = 1">
                                        <xsl:value-of select="$from"/>
                                    </xsl:when>
                                    <xsl:when test="position() = $count">
                                        <xsl:value-of select="$to"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$prec+position()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$prec+position()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="mode">
                        <xsl:choose>
                            <xsl:when test="number($notRegularLeafs//t:added/@f) = number(position())">added</xsl:when>
                            <xsl:when test="number($notRegularLeafs//t:missing/@f) = number(position())">missing</xsl:when>
                            <xsl:when test="number($notRegularLeafs//t:replaced/@f )= number(position())">replaced</xsl:when>
                            <xsl:otherwise>original</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                </leaf>
            </xsl:for-each>
        </xsl:variable>
        
        
<!--        this step compares the leafs with the informations about singletons and addes the @single with the appriate value, 
            so we know which one are singeltons or added
        
        it works also for added leafs recorded as no stub, as this are saved in the singleton variable as well-->
        <xsl:variable name="leafs2">
            <xsl:for-each select="$leafs/t:leaf">
                <xsl:sort order="ascending" select="position()"/>
                <leaf>
                    <xsl:copy-of select="@*"/>
                    <xsl:choose>
                        <xsl:when test="position() = $singleton//t:singleton">
                            <xsl:attribute name="single">true</xsl:attribute>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="single">false</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                </leaf>
            </xsl:for-each>
        </xsl:variable>
        
        
<!--        this step adds singletons and conjoin leaves looking always at the singleton variable, before (-) or afeter (+) the leaf number indicated in the describtion-->
        <xsl:variable name="leafs3">
            <xsl:for-each select="$leafs2/t:leaf">
                <xsl:sort order="ascending" select="position()"/>
                <xsl:variable name="n" select="@n"/>
<!--                This if statement looks for no stub singletons, e.g. added leaves ONLY at the END of the quire, 
                    conjoining them to the beginning of the quire-->
                <xsl:if test="$singleton/t:couple[t:boa[text() = 'n']][t:singleton = $count][$n =1]">
                    <xsl:for-each select="$singleton/t:couple[t:boa[text() = 'n']][t:singleton = $count]">
                        <leaf>
                            <xsl:attribute name="conjoin">1</xsl:attribute>
                        </leaf>
                    </xsl:for-each>
                </xsl:if>
                <xsl:if test="$singleton/t:couple[t:stub[text() = $n]]//t:boa[text() = '-']">
                    <xsl:for-each select="$singleton/t:couple[t:stub[text() = $n]]//t:boa[text() = '-']">
                        <leaf>
                            <xsl:variable name="precSingl" select="current()/preceding-sibling::t:singleton"/>
                            <xsl:attribute name="conjoin">
                                <xsl:value-of select="$precSingl"/>
                            </xsl:attribute>
                        </leaf>
                    </xsl:for-each>
                </xsl:if>
                <leaf>
                    <xsl:copy-of select="@*"/>
                </leaf>
                <xsl:if test="$singleton/t:couple[t:stub[text() = $n]]//t:boa[text() = '+']">
                    <xsl:for-each select="$singleton/t:couple[t:stub[text() = $n]]//t:boa[text() = '+']">
                        <leaf>
                            <xsl:variable name="precSingl" select="current()/preceding-sibling::t:singleton"/>
                            <xsl:attribute name="conjoin">
                                <xsl:value-of select="$precSingl"/>
                            </xsl:attribute>
                        </leaf>
                    </xsl:for-each>
                </xsl:if>
                <!--                This if statement looks for no stub singletons, e.g. added leaves ONLY at the BEGINNING of the quire, 
                    conjoining them to the beginning of the quire-->
                <xsl:if test="$singleton/t:couple[t:boa[text() = 'n']][number(t:singleton) = 1][$n =$count]">
                    <xsl:for-each select="$singleton/t:couple[t:boa[text() = 'n']][number(t:singleton) = 1]">
                        <leaf>
                            <xsl:attribute name="conjoin">
                                <xsl:value-of select="($count +$singletons)"/>
                            </xsl:attribute>
                        </leaf>
                    </xsl:for-each>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        
<!--        now that all elements are there, it is possible to enumerate and to add the @conjoin to the non single leaves (stubs already have it)
        added leaves should not get any conjoin, as they are single=true
        -->
        <xsl:variable name="leafs4">
            <xsl:for-each select="$leafs3/t:leaf">
                <xsl:sort order="ascending" select="position()"/>
                <xsl:variable name="pos" select="@position"/>
                <leaf>
                    <xsl:copy-of select="@*"/>
                    <xsl:attribute name="position">
                        <xsl:value-of select="position()"/>
                    </xsl:attribute>
                    <xsl:if test="@single='false'">
                        <xsl:attribute name="conjoin">
                            <xsl:choose>
                                <xsl:when test="@folio_number">
                                    <xsl:value-of select="((($count+1)+$singletons) - position())"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:attribute>
                    </xsl:if>
                </leaf>
            </xsl:for-each>
        </xsl:variable>
        
       <!--    TESTING
           <xsl:copy-of select="$count"/>
        <xsl:copy-of select="$singletons"/>
        <xsl:copy-of select="$singleton"/>
        <xsl:copy-of select="$notRegularLeafs"/>
        <xsl:copy-of select="$leafs"/>
        <xsl:copy-of select="$leafs2"/>
        <xsl:copy-of select="$leafs3"/>-->
        <xsl:copy-of select="$leafs4"/>
    </xsl:template>
</xsl:stylesheet>