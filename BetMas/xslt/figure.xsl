<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    <xsl:template match="t:figure">
        <xsl:variable name="url" select="concat('https://betamasaheft.eu/iiif/',t:graphic/@url, '/info.json')"/>
        <xsl:variable name="id" select="concat($mainID, 'graphic')"/>
        
        <xsl:choose>
            <xsl:when test="t:graphic[@n]">
                <xsl:variable name="n" select="t:graphic/@n"/>      
                <div id="{$id}">
                    <div id="openseadragon{$id}" style="height:300px"/>
                    <div class="caption w3-margin-left w3-tiny">
                        <xsl:apply-templates select="t:graphic/t:desc"/>
                    </div>
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
                           defaultZoomLevel:   1,
                        sequenceMode :true, </xsl:text>
                        <xsl:text>tileSources:   [</xsl:text>
                        <xsl:variable name="urls">
                            <xsl:for-each select="1 to $n">
                                "<xsl:value-of select="replace($url, '/info.json', concat(format-number(., '000'), '.tif/info.json'))"/>"<xsl:value-of select="if(. = $n)                                      then '' else ',                                     '"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="$urls/text()"/>
                        <xsl:text>]
                           });
                        </xsl:text>
                    </script>
                </div>
            </xsl:when>
            <xsl:otherwise>
        <div id="{$id}">
            <div id="openseadragon{$id}" style="height:300px"/>
            <div class="caption w3-margin-left w3-tiny">
                        <xsl:apply-templates select="t:graphic/t:desc"/>
                    </div>
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
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>