<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:additions">
        <div id="additiones" rel="http://purl.org/dc/terms/hasPart">
            <h2>Additions <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit
                <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
            <a tabindex="0" data-html="true" data-toggle="popover" title="additions informations">
                <xsl:attribute name="data-content">
                    
                    <xsl:text>In this unit there are </xsl:text>
            <xsl:for-each select=".//t:item/t:desc[generate-id() = generate-id(key('additiontype', @type)[1])]">
                <xsl:value-of select="concat(' ', count(key('additiontype', ./@type)), ' ', ./@type)"/>
                <xsl:choose>
                    <xsl:when test="not(position() = last()) and not(position() + 1 = last())">
                        <xsl:text>,</xsl:text>
                    </xsl:when>
                    <xsl:when test="position() + 1 = last()">
                        <xsl:text> and</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>.</xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
                </xsl:attribute>
                <i class="fa fa-info-circle" aria-hidden="true"/>
                </a>
            </h2>
            
            
            <xsl:if test="t:note">
                <p>
                    <xsl:apply-templates select="t:note"/>
                </p>
            </xsl:if>
            <ol>
                <xsl:for-each select=".//t:item[contains(@xml:id, 'a')]">
                    <li resource="https://betamasaheft.eu/{$mainID}/addition/{@xml:id}">
                        <xsl:attribute name="typeof">
                            <xsl:if test="./t:desc/@type">
                                <xsl:value-of select="concat('https://betamasaheft.eu/', ./t:desc/@type)"/>
                            </xsl:if>
                    </xsl:attribute>
                        <xsl:attribute name="id">
                            <xsl:value-of select="@xml:id"/>
                        </xsl:attribute>
                        <p>
                            <xsl:apply-templates select="t:locus"/> <xsl:if test="t:desc/@type"> (Type: <a href="/authority-files/list?keyword={t:desc/@type}" data-value="{t:desc/@type}" class="MainTitle"><xsl:value-of select="t:desc/@type"/></a><a href="/additions?type={t:desc/@type}"><i class="fa fa-hand-o-left"/></a>)</xsl:if>
                        </p>
                        <p>
                            <xsl:value-of select="@rend"/>
                        </p>
                        <p>
                            <xsl:apply-templates select="t:desc"/>
                            
                        </p>
                        <xsl:apply-templates select="t:q"/>
                        <p>
                            <xsl:value-of select="./text()"/>
                        </p>
                        <p>
                            <xsl:apply-templates select="t:note"/>
                        </p>
                        <xsl:if test="t:listBibl">
                            <xsl:apply-templates select="t:listBibl"/>
                        </xsl:if>
                    </li>
                </xsl:for-each>
            </ol>
            <xsl:if test=".//t:item[contains(@xml:id, 'e')]">
                <h3 id="{@xml:id}">Extras <xsl:if test="./ancestor::t:msPart">
                        <xsl:variable name="currentMsPart">
                            <a href="{./ancestor::t:msPart/@xml:id}">
                                <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                            </a>
                        </xsl:variable> of codicological unit
                    <xsl:value-of select="$currentMsPart"/>
                    </xsl:if>
                </h3>
                <ol>
                    <xsl:for-each select=".//t:item[contains(@xml:id, 'e')]">
                        <li resource="https://betamasaheft.eu/{$mainID}/addition/{@xml:id}">
                            <xsl:attribute name="typeof">
                                <xsl:if test="./t:desc/@type">
                                    <xsl:value-of select="concat('https://betamasaheft.eu/', ./t:desc/@type)"/>
                                </xsl:if>
                            </xsl:attribute>
                            <p>
                                <xsl:apply-templates select="t:locus"/> <xsl:if test="t:desc/@type"> (Type: <a href="/authority-files/list?keyword={t:desc/@type}" data-value="{t:desc/@type}" class="MainTitle"><xsl:value-of select="t:desc/@type"/></a>)</xsl:if>
                            </p>
                            <xsl:apply-templates select="child::node() except t:locus"/>
                        </li>
                    </xsl:for-each>
                </ol>
            </xsl:if>
        </div>
    </xsl:template>
</xsl:stylesheet>