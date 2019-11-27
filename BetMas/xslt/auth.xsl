<xsl:stylesheet xmlns:funct="my.funct"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:function name="funct:date">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, '\d{4}-\d{2}-\d{2}')">
                <xsl:value-of select="format-date(xs:date($date), '[D]-[M]-[Y0001]', 'en', 'AD', ())"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="format-number($date, '####')"/></xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="funct:datepicker">
        <xsl:param name="element"/>
        <xsl:choose>
            <xsl:when test="$element/@notBefore or $element/@notAfter">
                <xsl:if test="not($element/@notBefore)">Before </xsl:if>
                <xsl:if test="not($element/@notAfter)">After </xsl:if>
                <xsl:if test="$element/@notBefore"><xsl:value-of select="funct:date($element/@notBefore)"/></xsl:if>
                <xsl:if test="$element/@notBefore and $element/@notAfter"><xsl:text>-</xsl:text></xsl:if>
                <xsl:if test="$element/@notAfter"><xsl:value-of select="funct:date($element/@notAfter)"/></xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="funct:date($element/@when)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$element/@cert">
            <xsl:value-of select="concat(' (certainty: ', $element/@cert, ')')"/>
        </xsl:if>
    </xsl:function>
    <xsl:template match="t:relation" mode="gendesc">
        <xsl:choose>
            <xsl:when test="not(@passive) and t:desc"><xsl:value-of select="t:desc"/></xsl:when>
            <xsl:otherwise><a target="_blank" href="/{@passive}"><span class="MainTitle" data-value="{@passive}"><xsl:value-of select="@passive"/></span></a></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="/">
        <div id="MainData" class="w3-twothird">      <div id="description">
            <h2>General description</h2>
            
            <p>
                <xsl:apply-templates select="//t:sourceDesc"/>
            </p>
            <p>
                <xsl:apply-templates select="//t:abstract/t:p"/>
            </p>
            <p>
                <xsl:if test="//t:relation">
                    <xsl:text>See </xsl:text>
                </xsl:if>
                <xsl:for-each select="//t:relation">
                    <xsl:sort order="ascending" select="count(preceding-sibling::t:relation)+1"/>
                    <xsl:variable name="p" select="count(preceding-sibling::t:relation)+1"/>
                    <xsl:variable name="tot" select="count(//t:relation)"/>
                    <xsl:apply-templates select="." mode="gendesc"/><xsl:choose>
                        <xsl:when test="$p!=$tot"><xsl:text>, </xsl:text></xsl:when>
                        <xsl:otherwise>.</xsl:otherwise></xsl:choose>
                </xsl:for-each>
                For a table of all relations from and to this record, please go to the <a class="w3-tag w3-gray" href="/authority-files/{$mainID}/analytic">Relations</a> view. In the Relations boxes on the right of this page, you can also find all available relations grouped by name.
            </p>
            <h2>Bibliography</h2>
            <xsl:apply-templates select="//t:listBibl"/>
            <button class="w3-button w3-red" id="showattestations" data-value="term" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
            <div id="allattestations" class="col-md-12"/>
        </div>
        </div>
    </xsl:template>
    
    <xsl:template match="t:list[ancestor::t:abstract or ancestor::t:desc]">
        <ol>
            <xsl:for-each select="t:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ol>
    </xsl:template>
    <!-- elements templates-->
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="editorKey.xsl"/>
    <xsl:include href="msselements.xsl"/> 
    
    <!--    elements with references-->
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <!-- includes also region, country and settlement-->
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
</xsl:stylesheet>