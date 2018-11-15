<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sr="http://www.w3.org/2005/sparql-results#" xmlns:xxx="http://www.w3.org/2005/sparql-results#" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="sr:sparql">
        <table class="table table-responsive">
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="sr:head">
        <thead>
            <tr>
                <th>number</th>
                <xsl:apply-templates/>
            </tr>
        </thead>
    </xsl:template>

    <xsl:template match="sr:variable">
        <th>
            variable : <xsl:value-of select="@xxx:name"/>
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
            <td>
                <xsl:value-of select="position()"/>
            </td>
            <xsl:for-each select="//sr:variable">
                <xsl:variable name="n" select="@xxx:name"/>
                <td>
                    <xsl:apply-templates select="$results[@xxx:name = $n]"/>
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>

    <xsl:template match="sr:binding">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="sr:uri">
        <a href="{.}">
            <xsl:value-of select="."/>
        </a>
    </xsl:template>
</xsl:stylesheet>