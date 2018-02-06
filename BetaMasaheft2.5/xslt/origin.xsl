<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:origDate | t:floruit | t:birth | t:death">
        <p class="lead">
            <xsl:choose>
                <xsl:when test="@when">
                    <xsl:value-of select="@when"/>
                </xsl:when>
                <xsl:when test="@from |@to">
                    <xsl:choose>
                        <xsl:when test="@from and @to">
                            <xsl:value-of select="@from"/>
                            <xsl:text>-</xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:when>
                        <xsl:when test="@from and not(@to)">
                            <xsl:text>Before </xsl:text>
                            <xsl:value-of select="@to"/>
                        </xsl:when>
                        <xsl:when test="@to and not(@from)">
                            <xsl:text>After </xsl:text>
                            <xsl:value-of select="@from"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@notBefore and @notAfter">
                            <xsl:value-of select="@notBefore"/>
                            <xsl:text> - </xsl:text>
                            <xsl:value-of select="@notAfter"/>
                        </xsl:when>
                        <xsl:when test="@notAfter and not(@notBefore)">
                            <xsl:text>Before </xsl:text>
                            <xsl:value-of select="@notAfter"/>
                        </xsl:when>
                        <xsl:when test="@notBefore and not(@notAfter)">
                            <xsl:text>After </xsl:text>
                            <xsl:value-of select="@notBefore"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="@evidence">
                <xsl:value-of select="if(@evidence='lettering') then ' (dating on paleographic grounds)' else concat(' (',@evidence, ')')"/>
            </xsl:if>
            <xsl:if test="@cert = 'low'">?</xsl:if>
            
            <xsl:if test="@resp">
                <xsl:variable name="resp">
                    <xsl:choose>
                        <xsl:when test="contains(@resp,'PRS')">
                            <xsl:for-each select="tokenize(normalize-space(@resp), ' ')">
                                <a href="{.}" class="MainTitle" data-value="{.}">
                                    <xsl:value-of select="."/>
                                </a>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="t:corr/@resp = 'AB'">Prof. Alessandro Bausi</xsl:when>
                        <xsl:when test="t:corr/@resp = 'ES'">Eugenia Sokolinski</xsl:when>
                        <xsl:when test="t:corr/@resp = 'DN'">Dr. Denis Nosnitsin</xsl:when>
                        <xsl:when test="t:corr/@resp = 'MV'">Massimo Villa</xsl:when>
                        <xsl:when test="t:corr/@resp = 'DR'">Dorothea Reule</xsl:when>
                        <xsl:when test="t:corr/@resp = 'SG'">Solomon Gebreyes</xsl:when>
                        <xsl:when test="t:corr/@resp = 'PL'">Dr. Pietro Maria Liuzzo</xsl:when>
                        <xsl:when test="t:corr/@resp = 'SA'">Dr Stéphane Ancel</xsl:when>
                        <xsl:when test="t:corr/@resp = 'SD'">Sophia Dege</xsl:when>
                        <xsl:when test="t:corr/@resp = 'VP'">Dr Vitagrazia Pisani</xsl:when>
                        <xsl:when test="t:corr/@resp = 'IF'">Iosif Fridman</xsl:when>
                        <xsl:when test="t:corr/@resp = 'SH'">Susanne Hummel</xsl:when>
                        <xsl:when test="t:corr/@resp = 'FP'">Francesca Panini</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:text> according to </xsl:text>
                <xsl:copy-of select="$resp"/>
            </xsl:if>
        </p>
        <xsl:if test="child::t:* or text()">
            <p class="lead">
                <xsl:apply-templates select="child::node()"/>
            </p>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:origDate | t:floruit | t:birth | t:death" mode="noP">
        <xsl:choose> 
            <xsl:when test="child::t:* or text()">
                <xsl:apply-templates select="child::node()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@when">
                        <xsl:value-of select="@when"/>
                    </xsl:when>
                    <xsl:when test="@from |@to">
                        <xsl:choose>
                            <xsl:when test="@from and @to">
                                <xsl:value-of select="@from"/>
                                <xsl:text>-</xsl:text>
                                <xsl:value-of select="@to"/>
                            </xsl:when>
                            <xsl:when test="@from and not(@to)">
                                <xsl:text>Before </xsl:text>
                                <xsl:value-of select="@to"/>
                            </xsl:when>
                            <xsl:when test="@to and not(@from)">
                                <xsl:text>After </xsl:text>
                                <xsl:value-of select="@from"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="@notBefore and @notAfter">
                                <xsl:value-of select="@notBefore"/>
                                <xsl:text> - </xsl:text>
                                <xsl:value-of select="@notAfter"/>
                            </xsl:when>
                            <xsl:when test="@notAfter and not(@notBefore)">
                                <xsl:text>Before </xsl:text>
                                <xsl:value-of select="@notAfter"/>
                            </xsl:when>
                            <xsl:when test="@notBefore and not(@notAfter)">
                                <xsl:text>After </xsl:text>
                                <xsl:value-of select="@notBefore"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:if test="@cert = 'low'">?</xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@evidence">
            <xsl:value-of select="concat(' (',if(@evidence='lettering') then 'dating on paleographic grounds' else @evidence, ')')"/>
        </xsl:if>
        <xsl:if test="@resp">
            <xsl:variable name="resp">
                <xsl:choose>
                    <xsl:when test="contains(@resp,'PRS')">
                        <xsl:for-each select="tokenize(normalize-space(@resp), ' ')">
                            <a href="{.}" class="MainTitle" data-value="{.}">
                                <xsl:value-of select="."/>
                            </a>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:when test="t:corr/@resp = 'AB'">Prof. Alessandro Bausi</xsl:when>
                    <xsl:when test="t:corr/@resp = 'ES'">Eugenia Sokolinski</xsl:when>
                    <xsl:when test="t:corr/@resp = 'DN'">Dr. Denis Nosnitsin</xsl:when>
                    <xsl:when test="t:corr/@resp = 'MV'">Massimo Villa</xsl:when>
                    <xsl:when test="t:corr/@resp = 'DR'">Dorothea Reule</xsl:when>
                    <xsl:when test="t:corr/@resp = 'SG'">Solomon Gebreyes</xsl:when>
                    <xsl:when test="t:corr/@resp = 'PL'">Dr. Pietro Maria Liuzzo</xsl:when>
                    <xsl:when test="t:corr/@resp = 'SA'">Dr Stéphane Ancel</xsl:when>
                    <xsl:when test="t:corr/@resp = 'SD'">Sophia Dege</xsl:when>
                    <xsl:when test="t:corr/@resp = 'VP'">Dr Vitagrazia Pisani</xsl:when>
                    <xsl:when test="t:corr/@resp = 'IF'">Iosif Fridman</xsl:when>
                    <xsl:when test="t:corr/@resp = 'SH'">Susanne Hummel</xsl:when>
                    <xsl:when test="t:corr/@resp = 'FP'">Francesca Panini</xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:text> (according to </xsl:text>
            <xsl:copy-of select="$resp"/>
            <xsl:text>)</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:origPlace">
        <p>
            <b>Original Location: </b>
            <xsl:apply-templates/>
        </p>
        <p>
            <xsl:apply-templates select="parent::t:origin/t:provenance"/>
        </p>
    </xsl:template>
    
    <xsl:template match="t:origin">
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>