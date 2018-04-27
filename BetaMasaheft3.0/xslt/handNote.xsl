<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    <xsl:template match="t:handNote">
        <xsl:if test="count(./ancestor::t:handDesc/t:handNote) gt 1">
            <h5 id="{@xml:id}">Hand <xsl:value-of select="substring-after(@xml:id, 'h')"/>
                <xsl:if test="./ancestor::t:msPart">
                    <xsl:variable name="currentMsPart">
                        <a href="{./ancestor::t:msPart/@xml:id}">
                            <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                        </a>
                    </xsl:variable> of codicological unit <xsl:value-of select="$currentMsPart"/>
                </xsl:if>
                <xsl:if test="@corresp">
                    <xsl:text> (</xsl:text>
                    <xsl:choose>
                        <xsl:when test="contains(@corresp, ' ')">
                            <xsl:for-each select="tokenize(@corresp, ' ')">
                                <a href="{.}">
                                    <xsl:value-of select="substring-after(., '#')"/>
                                </a>
                                <xsl:text> </xsl:text>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{@corresp}">
                                <xsl:value-of select="substring-after(@corresp, '#')"/>
                            </a>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>)</xsl:text>
                </xsl:if>
            </h5>
        </xsl:if>

        <xsl:choose>
            <xsl:when test="t:seg[@type = 'script']">
            <p>
                <xsl:apply-templates select="t:seg[@type = 'script']"/>
            </p>
        </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@script">
                        <xsl:value-of select="@script"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        
        
        <xsl:if test="t:seg[@type = 'rubrication']">
            <p>
                <xsl:apply-templates select="t:seg[@type = 'rubrication']"/>
</p>
        </xsl:if>
        <xsl:if test="t:seg[@type = 'ink']">
            <p>Ink: <xsl:apply-templates select="t:seg[@type = 'ink']"/>
            </p>
        </xsl:if>
      <xsl:if test="t:list[@type = 'abbreviations']">
            <h4> Abbreviations </h4>
            <ul>
                <xsl:for-each select="t:list[@type = 'abbreviations']/t:item">
                    <li>
                        <xsl:apply-templates select="."/>
                    </li>
                </xsl:for-each>
            </ul>
        </xsl:if>
        <xsl:if test="t:persName[@role = 'scribe']">
            <h4>Scribe</h4>
        </xsl:if>
          <xsl:apply-templates select="child::node() except (t:list | t:ab[@type = 'script'] | t:seg)"/>
    </xsl:template>
</xsl:stylesheet>