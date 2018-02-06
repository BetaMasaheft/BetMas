<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="t:TEI/@type = 'mss'">
                <li>
                    <h3>Navigate section</h3>
                    <ul class="nav nav-pills nav-stacked">
                        <li>
                            <a class="page-scroll" href="#general">General</a>
                        </li>
                        <li>
                            <a class="page-scroll" href="#description">Description</a>
                        </li>
                        <li>
                            <a class="page-scroll" href="#generalphysical">Physical desc of ms</a>
                        </li>
                        <xsl:if test="//t:msPart">
                            <ul>
                                <xsl:for-each select="//t:msPart">
                                    <li>
                                        <a class="page-scroll" href="#{@xml:id}">Codicological unit <xsl:value-of select="substring-after(@xml:id, 'p')"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </xsl:if>
                        <xsl:if test="//t:additional//t:listBibl">
                            <li>
                                <a class="page-scroll" href="#catalogue">Catalogue</a>
                            </li>
                        </xsl:if>
                        <xsl:if test="//t:body[t:div]">
                            <li>
                                <a class="page-scroll" href="#transcription">Transcription </a>
                            </li>
                        </xsl:if>
                        <li>
                            <a class="page-scroll" href="#footer">Authors</a>
                        </li>
                    </ul>
                </li>
                <li>
                    <button type="button" class="toggle btn btn-info" data-toggle="collapse" data-target="#NavByIds">Show more links</button>
                    <div class="collapse" id="NavByIds">
                        <ul class="nav nav-pills nav-stacked">
                            <xsl:for-each select="//*[not(self::t:TEI)][@xml:id]">
                                <xsl:sort select="position()"/>
                                <li>
                                    <a class="page-scroll" href="#{@xml:id}">
                                        <xsl:choose>
                                            <xsl:when test="contains(@xml:id, 't') and matches(@xml:id, '\w\d+')">Title <xsl:value-of select="substring-after(@xml:id, 't')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'b') and matches(@xml:id, '\w\d+')">Binding <xsl:value-of select="substring-after(@xml:id, 'b')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'a') and matches(@xml:id, '\w\d+')">Addition <xsl:value-of select="substring-after(@xml:id, 'a')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'e') and matches(@xml:id, '\w\d+')">Extra <xsl:value-of select="substring-after(@xml:id, 'e')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'i') and matches(@xml:id, '_\w\d+')">Content Item <xsl:value-of select="substring-after(@xml:id, 'i')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'q') and matches(@xml:id, '\w\d+')">Quire <xsl:value-of select="substring-after(@xml:id, 'q')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'coloph')">Colophon
                                                <xsl:value-of select="substring-after(@xml:id, 'coloph')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'h') and matches(@xml:id, '\w\d+')">Hand <xsl:value-of select="substring-after(@xml:id, 'h')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'div')">Divider <xsl:value-of select="substring-after(@xml:id, 'div')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'd') and matches(@xml:id, '\w\d+')">Decoration <xsl:value-of select="substring-after(@xml:id, 'd')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="name()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </div>
                </li>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'work'">
                <li>
                    <a class="page-scroll" href="#description">Description</a>
                </li>
                <xsl:if test="//t:body[t:div[@type='edition'][t:ab or t:div[@type='textpart']]]">
                    <li>
                        <a class="page-scroll" href="#transcription">Transcription
                            </a>
                    </li>
                </xsl:if>
                <li>
                    <a class="page-scroll" href="#bibliography">Bibliography</a>
                </li>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'nar'">
                <li>
                    <a class="page-scroll" href="#general">General</a>
                </li>
                <li>
                    <a class="page-scroll" href="#description">Description</a>
                </li>
                <li>
                    <a data-toggle="modal" data-target="#BetMasRel">Relations</a>
                </li>
                <li>
                    <a class="page-scroll" href="#authors">Authors</a>
                </li>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'ins' or t:TEI/@type = 'place'">
                <li>
                    <a class="page-scroll" href="#general">General</a>
                </li>
                <li>
                    <a class="page-scroll" href="#description">Description</a>
                </li>
                <li>
                    <a class="page-scroll" href="#map">Map</a>
                </li>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'pers'">
                <li>
                    <a class="page-scroll" href="#general">General</a>
                </li>
                <xsl:if test="//t:birth">
                    <li>
                    <a class="page-scroll" href="#birth">Birth</a>
                </li>
                </xsl:if>
                <xsl:if test="//t:death">
                    <li>
                    <a class="page-scroll" href="#death">Death</a>
                </li>
                </xsl:if>
                <xsl:if test="//t:floruit">
                <li>
                    <a class="page-scroll" href="#floruit">Floruit</a>
                </li>
                </xsl:if>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'auth'">
                <li>
                    <a class="page-scroll" href="#general">General</a>
                </li>
                <li>
                    <a class="page-scroll" href="#description">Description</a>
                </li>
                <li>
                    <a class="page-scroll" href="#authors">Authors</a>
                </li>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>