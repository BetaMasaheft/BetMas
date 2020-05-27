<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:dimensions[@type = 'outer']">
        
        <h3>Outer dimension<xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <xsl:choose>
        <xsl:when test="t:*/text()">
                <p>
            <xsl:if test="t:height/text()">H: <span> <xsl:value-of select="t:height"/>
                </span>
                <xsl:value-of select="@unit"/>
            </xsl:if>
            <xsl:if test="t:width/text()"> x W: <span>
                    <xsl:value-of select="t:width"/>
                </span>
                <xsl:value-of select="@unit"/>
                    </xsl:if>
            <xsl:if test="t:depth/text()"> x D: <span>
                    <xsl:value-of select="t:depth"/>
                </span>
                <xsl:value-of select="@unit"/>
            </xsl:if>
        </p>
            </xsl:when>
        <xsl:otherwise>No dimensions provided.</xsl:otherwise>
    </xsl:choose>
        <xsl:if test="not(ancestor::t:TEI//t:objectDesc/@form = 'Inscription')">
            <xsl:if test="(t:height/text() and t:width/text())">
                <p>(proportion height/width: <xsl:value-of select="format-number(number(t:height div t:width), '#0.0###')"/> ) </p>
            </xsl:if>
        </xsl:if>
        <xsl:apply-templates select="node() except (t:height | t:width | t:depth )"/>
    </xsl:template>
    <xsl:template match="t:dimensions[@type='leaf']">
            <h3>Leaves dimension</h3>
            <p>
                <xsl:if test="t:height/text()">H: <span> <xsl:value-of select="t:height"/>
                </span>
                    <xsl:value-of select="@unit"/>
                </xsl:if>
                <xsl:if test="t:width/text()"> x W: <span>
                    <xsl:value-of select="t:width"/>
                </span>
                    <xsl:value-of select="@unit"/>
                </xsl:if>
            </p>
        
    </xsl:template>
    <xsl:template match="t:dimensions[@type='binding']">
        <h3>Binding dimensions (when different from outer dimensions)</h3>
        <p>
            <xsl:if test="t:height/text()">H: <span> <xsl:value-of select="t:height"/>
            </span>
                <xsl:value-of select="@unit"/>
            </xsl:if>
            <xsl:if test="t:width/text()"> x W: <span>
                <xsl:value-of select="t:width"/>
            </span>
                <xsl:value-of select="@unit"/>
            </xsl:if>
            <xsl:if test="t:depth/text()"> x D: <span>
                <xsl:value-of select="t:depth"/>
            </span>
                <xsl:value-of select="@unit"/>
            </xsl:if>
        </p>
        
    </xsl:template>
</xsl:stylesheet>