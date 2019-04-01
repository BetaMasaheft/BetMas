<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    <xsl:template match="t:figure">
        <xsl:variable name="url" select="concat('https://betamasaheft.eu/iiif/',t:graphic/@url, '/info.json')"/>
        <xsl:variable name="id" select="t:graphic/@xml:id"/>
        <div id="{$id}">
            <div id="openseadragon{$id}" style="height:300px"/>
            <div class="caption w3-margin-left w3-tiny"><xsl:apply-templates select="t:graphic/t:desc"/></div>
            <script type="text/javascript">
                <xsl:text>
                           OpenSeadragon({
                           id: "openseadragon</xsl:text>
                <xsl:value-of select="$id"/>
                <xsl:text>",
                           prefixUrl: "resources/openseadragon/images/",
                           preserveViewport: true,
                           visibilityRatio:    1,
                           minZoomLevel:       1,
                           defaultZoomLevel:   1,</xsl:text>
                <xsl:text>tileSources:   ["</xsl:text>
                <xsl:value-of select="$url"/>
                <xsl:text>"]
                           });
                        </xsl:text>
            </script>
        </div>
    </xsl:template>
    
</xsl:stylesheet>