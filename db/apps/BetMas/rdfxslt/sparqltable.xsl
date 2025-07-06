<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sr="http://www.w3.org/2005/sparql-results#" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="sr:sparql">
        <div class="w3-responsive">
            <table class="w3-table w3-all" id="sparqltable">
            <xsl:apply-templates/>
        </table>
        </div>
    </xsl:template>
    <xsl:template match="sr:head">
        <thead>
            <tr>
                <th>#</th>
                <xsl:apply-templates/>
            </tr>
        </thead>
    </xsl:template>

    <xsl:template match="sr:variable">
        <th onclick="sortTable({position()-1})" style="word-break:break-word;">
            <xsl:value-of select="@name"/>
        </th>
    </xsl:template>
    <xsl:template match="sr:results">
        <tbody>
            <xsl:apply-templates/>
        </tbody>
    </xsl:template>

    <xsl:template match="sr:result">
        <xsl:variable name="results" select="sr:binding"/>
        <tr>
            <td style="word-break:break-word;">
                <xsl:value-of select="position() div 2"/>
            </td>
            <xsl:for-each select="//sr:variable">
                <xsl:variable name="n" select="@name"/>
                <td style="word-break:break-word;">
                    <xsl:apply-templates select="$results[@name = $n]"/>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>

    <xsl:template match="sr:binding">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="sr:uri">
       <a href="{.}" target="_blank">
             <xsl:choose>
                 <xsl:when test="ends-with(.,'owner') or ends-with(.,'scribe') or ends-with(.,'illustrator') or ends-with(.,'patron') or ends-with(.,'donor') or ends-with(.,'bequeather')">
                     <xsl:value-of select="substring-after(.,'https://betamasaheft.eu/')"/>
                 </xsl:when>
                 <xsl:when test="starts-with(.,'https://betamasaheft.eu/')">
                     <xsl:attribute name="class">MainTitle</xsl:attribute>
                     <xsl:attribute name="data-value">
                        <xsl:value-of select="substring-after(.,'https://betamasaheft.eu/')"/>
                    </xsl:attribute>
                     <xsl:value-of select="."/>
                 </xsl:when>
                 <xsl:when test="starts-with(., 'http://n2t.net/ark:/99152/')">
                     <xsl:choose>
                         <xsl:when test="ends-with(., 't5z3')">South-Arabian, Pre-Aksumite and Proto-Aksumite. -0999–0000</xsl:when>
                         <xsl:when test="ends-with(., 'tdn7')">Early Aksumite. 0001–0300</xsl:when>
                         <xsl:when test="ends-with(., '4qvv')">Aksumite. 0300–0700</xsl:when>
                         <xsl:when test="ends-with(., 'rjvk')">Postaksumite I. 1200–1433</xsl:when>
                         <xsl:when test="ends-with(., 'vm7f')">Postaksumite II. 1434–1632</xsl:when>
                         <xsl:when test="ends-with(., 'dh3k')">Gondarine. 1632–1769</xsl:when>
                         <xsl:when test="ends-with(., 'vtwm')">Zamana Masāfǝnt. 1769–1855</xsl:when>
                         <xsl:when test="ends-with(., 'fc3r')">Modern Period. 1855–1974</xsl:when>
                     </xsl:choose>
                 </xsl:when>
                 <xsl:when test="starts-with(.,'http://data.snapdrgn.net/ontology/snap#')">
                     <xsl:value-of select="substring-after(.,'http://data.snapdrgn.net/ontology/snap#')"/>
                 </xsl:when>
                 <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
             </xsl:choose>
           
        </a>
    </xsl:template>
</xsl:stylesheet>