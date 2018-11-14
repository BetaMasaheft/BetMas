<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    <xsl:template match="/">
        <div class="col-md-12">
           
            <div class="col-md-6" style="max-height:250px; overflow:auto; ">
                <xsl:apply-templates select="//t:q"/>
                <div class="footnotes">
                    <xsl:apply-templates select="//t:note[@n][@xml:id]"/>
                </div>
            </div>
            <div class="col-md-6" style="max-height:250px; overflow:auto; ">
            <xsl:apply-templates select="//t:note[not(@n)][not(@xml:id)]"/>
                <xsl:if test="//t:listBibl">
            <xsl:apply-templates select="//t:listBibl"/>
        </xsl:if>
        </div>
        
        </div>
        <hr/>
    </xsl:template>
    <xsl:template match="t:seg[@ana]">
        <xsl:variable name="ana" select="substring-after(@ana, '#')"/>
        <span class="{$ana}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:ptr[@target]">
        <xsl:variable name="t" select="substring-after(@target, '#')"/>
        <xsl:variable name="note" select="//t:note[@xml:id = $t]"/>
        <sup>
            <a href="{@target}" id="pointer{$t}">
                <xsl:value-of select="$note/@n"/>
            </a>
        </sup>
    </xsl:template>
    <xsl:template match="t:note[@n][@xml:id]">
        <dl style="font-size:smaller;">
        <xsl:variable name="t" select="substring-after(@xml:id, '#')"/>
        <dt>
                <i>
                    <a href="#pointer{$t}" id="{@xml:id}">
                        <xsl:value-of select="@n"/>
                        <xsl:text>) </xsl:text>
                    </a>
                </i>
            </dt>
            <dd>
                <xsl:apply-templates/>
            </dd>
        </dl>
    </xsl:template>
    <xsl:template match="t:term[text()]">
        <b>
            <xsl:value-of select="."/>
        </b>
    </xsl:template>
    <xsl:template match="t:relation"/>
    <xsl:include href="resp.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
</xsl:stylesheet>