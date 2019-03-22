<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:bindingDesc">
        <h3>Binding <xsl:if test="./ancestor::t:msPart">
                <xsl:variable name="currentMsPart">
                    <a href="{./ancestor::t:msPart/@xml:id}">
                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                    </a>
                </xsl:variable> of codicological unit
            <xsl:value-of select="$currentMsPart"/>
            </xsl:if>
        </h3>
        <p id="{//t:binding/t:decoNote[position() = 1]/@xml:id}">
            <xsl:apply-templates select="//t:binding/t:decoNote[@xml:id='b1']"/>
        </p>
        <xsl:for-each select=".//t:decoNote[@type][not(@type='Other')][not(@type='bindingMaterial')][not(@xml:id='b1')]">
            <h4 id="{@xml:id}">
                <xsl:value-of select="if(@type='SewingStations') then 'Sewing Stations' else @type"/>
                
            </h4><!--
            <p> Yes </p>-->
            <xsl:apply-templates select="."/>
        </xsl:for-each>
        <!--<xsl:if test=".//t:decoDesc[@type = 'Headbands']">
            <h4 id="{.//t:decoDesc[@type = 'Headbands']/@xml:id}">Headbands</h4>
            <p> Yes </p>
            <xsl:apply-templates select=".//t:decoDesc[@type = 'Headbands']"/>
        </xsl:if>
        <xsl:if test=".//t:decoDesc[@type = 'Tailbands']">
            <h4 id="{.//t:decoDesc[@type = 'Tailbands']/@xml:id}">Tailbands</h4>
            <p> Yes </p>
            <xsl:apply-templates select=".//t:decoDesc[@type = 'Tailbands']"/>
        </xsl:if>-->
        <xsl:if test="t:binding/t:decoNote[@type = 'Other']">
            <h4 id="{t:binding/t:decoNote[@type = 'Other']/@xml:id}">Binding decoration</h4>
            <p>
                <xsl:apply-templates select="t:binding/t:decoNote[@type = 'Other']"/>
            </p>
        </xsl:if>
        <xsl:if test="t:binding/t:decoNote[@type = 'bindingMaterial']/t:material/@key"> 
            <h4 id="{t:binding/t:decoNote[@type = 'bindingMaterial']/@xml:id}">Binding material</h4>
            <xsl:for-each select="t:binding/t:decoNote[@type = 'bindingMaterial']/t:material">
                <p>
                     <xsl:value-of select="./@key"/>
                </p>
            </xsl:for-each>
            <p>
                <xsl:apply-templates select="t:binding/t:decoNote[@type = 'bindingMaterial']"/>
            </p>
        </xsl:if>
        <xsl:if test="t:binding/@contemporary">
            <h4>Original binding</h4>
        <p>
            <xsl:value-of select="if(t:binding/@contemporary = 'true') then 'Yes' else 'No'"/>
        </p>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>