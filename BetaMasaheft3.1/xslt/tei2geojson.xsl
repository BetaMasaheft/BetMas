<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="text"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="//t:geo">
                {
                "type": "Feature",
                "geometry": {
                "type": "Point",
                "coordinates": [ 
                <xsl:value-of select="substring-after(//t:geo, ' ')"/>, <xsl:value-of select="substring-before(//t:geo, ' ')"/>]
                },
                "properties": {
                "name": "<xsl:value-of select="//t:placeName[1]"/>",
                "connectsWith": [
                "<xsl:value-of select="//t:country"/>",
                "<xsl:value-of select="//t:region"/>",
                "<xsl:value-of select="//t:district"/>"
                ],
                "description": "<xsl:value-of select="//t:settlement"/>",
                "citation": "Beta maṣāḥǝft",
                "id" :"<xsl:value-of select="t:TEI/@xml:id"/>"
                }}
                ;
                
            </xsl:when>
            <xsl:otherwise>
                {
                "type": "Feature",
                "geometry": {
                "type": "Point",
                "coordinates" : [11.5500, 39.2833]
                },
                "properties": {
                "name": "<xsl:value-of select="//t:placeName[1]"/>",
                "connectsWith": [
                "<xsl:value-of select="//t:country"/>",
                "<xsl:value-of select="//t:region"/>",
                "<xsl:value-of select="//t:district"/>"
                ],
                "description": "<xsl:value-of select="//t:settlement"/>",
                "citation": "Beta maṣāḥǝft",
                "id" :"<xsl:value-of select="t:TEI/@xml:id"/>"
                }}
                ;
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>