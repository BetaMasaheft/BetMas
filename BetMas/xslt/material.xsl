<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:supportDesc">
        <h2>Physical Description<xsl:if test="./ancestor::t:msPart">
            <xsl:variable name="currentMsPart">
                <a href="{./ancestor::t:msPart/@xml:id}">
                    <xsl:value-of select="substring-after(./ancestor::t:msPart[1]/@xml:id, 'p')"/>
                </a>
            </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
        </xsl:if>
        </h2>
        <xsl:if test="parent::t:objectDesc/@form">
            <h3>Form of support <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart[1]/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit
                <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
            </h3>
            <p>
                <xsl:if test=".//t:material/@key">
                    <xsl:for-each select=".//t:material">
                        <span class="w3-tag w3-gray" property="http://www.cidoc-crm.org/cidoc-crm/P46_is_composed_of" resource="https://betamasaheft.eu/material/{@key}">
                            <xsl:value-of select="concat(upper-case(substring(@key,1,1)),                 substring(@key, 2),        ' ' )"/>
                        </span>
                        <xsl:apply-templates/>
                    </xsl:for-each>
                    
                </xsl:if>
                <xsl:text> </xsl:text>
                <span class="w3-tag w3-red" typeof="https://betamasaheft.eu/{parent::t:objectDesc/@form}">
                    <xsl:value-of select="parent::t:objectDesc/@form"/>
                </span>
            </p>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>