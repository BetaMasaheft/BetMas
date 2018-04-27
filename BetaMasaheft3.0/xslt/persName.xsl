<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:persName">
        <xsl:choose>
           
            <xsl:when test="not(starts-with(@ref, 'PRS')) and not(starts-with(@ref, 'ETH'))">
                <xsl:choose>
                    <xsl:when test="@ref = 'AB'">Alessandro Bausi</xsl:when>
                    <xsl:when test="@ref = 'ES'">Eugenia Sokolinski</xsl:when>
                    <xsl:when test="@ref = 'DN'">Denis Nosnitsin</xsl:when>
                    <xsl:when test="@ref = 'MV'">Massimo Villa</xsl:when>
                    <xsl:when test="@ref = 'DR'">Dorothea Reule</xsl:when>
                    <xsl:when test="@ref = 'SG'">Solomon Gebreyes</xsl:when>
                    <xsl:when test="@ref = 'PL'">Pietro Maria Liuzzo</xsl:when>
                    <xsl:when test="@ref = 'SA'">Stéphane Ancel</xsl:when>
                    <xsl:when test="@ref = 'SD'">Sophia Dege</xsl:when>
                    <xsl:when test="@ref = 'VP'">Vitagrazia Pisani</xsl:when>
                    <xsl:when test="@ref = 'IF'">Iosif Fridman</xsl:when>
                    <xsl:when test="@ref = 'SH'">Susanne Hummel</xsl:when>
                    <xsl:when test="@ref = 'FP'">Francesca Panini</xsl:when>
                    <xsl:when test="@ref = 'AA'">Abreham Adugna</xsl:when>
                    <xsl:when test="@ref = 'EG'">Ekaterina Gusarova</xsl:when>
                    <xsl:when test="@ref = 'IR'">Irene Roticiani</xsl:when>
                    <xsl:when test="@ref = 'MB'">Maria Bulakh</xsl:when>
                    <xsl:when test="@ref = 'VR'">Veronika Roth</xsl:when>
                    <xsl:when test="@ref = 'MK'">Magdalena Krzyzanowska</xsl:when>
                    <xsl:when test="@ref = 'DE'">Daria Elagina</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@ref"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="filename">
                    <xsl:choose>
                        <xsl:when test="contains(@ref, '#')">
                            <xsl:value-of select="substring-before(@ref, '#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@ref"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <a xmlns="http://www.w3.org/1999/xhtml" href="{@ref}" class="persName">
                    <xsl:choose>
                        <xsl:when test="t:choice">
                            <xsl:apply-templates select="t:choice"/>
                        </xsl:when>
                        <xsl:when test="t:roleName or t:hi">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:when test="text()">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="MainTitle" data-value="{@ref}"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a>
                <xsl:if test="@role"> (<xsl:value-of select="@role"/>)</xsl:if>
                <xsl:if test="@evidence">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="@evidence"/>
                    <xsl:text>) </xsl:text>
                </xsl:if>
                <xsl:if test="@cert = 'low'">
                    <xsl:text> ? </xsl:text>
                </xsl:if>
                <xsl:if test="t:note">
                    <xsl:apply-templates select="t:note"/>
                </xsl:if><!--
                <xsl:if test="t:roleName">
                    <xsl:apply-templates select="t:roleName"/>
                </xsl:if>-->
                <xsl:variable name="id" select="generate-id()"/>
                <a xmlns="http://www.w3.org/1999/xhtml" id="{$id}Ent{$filename}relations">
                    <xsl:text>  </xsl:text>
                    <i class="fa fa-hand-o-left"/>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:persName" mode="nolink">
        <xsl:choose>
            <xsl:when test="not(starts-with(@ref, 'PRS')) and not(starts-with(@ref, 'ETH'))">
                <xsl:choose>
                    <xsl:when test="@ref = 'AB'">Alessandro Bausi</xsl:when>
                    <xsl:when test="@ref = 'ES'">Eugenia Sokolinski</xsl:when>
                    <xsl:when test="@ref = 'DN'">Denis Nosnitsin</xsl:when>
                    <xsl:when test="@ref = 'MV'">Massimo Villa</xsl:when>
                    <xsl:when test="@ref = 'DR'">Dorothea Reule</xsl:when>
                    <xsl:when test="@ref = 'SG'">Solomon Gebreyes</xsl:when>
                    <xsl:when test="@ref = 'PL'">Pietro Maria Liuzzo</xsl:when>
                    <xsl:when test="@ref = 'SA'">Stéphane Ancel</xsl:when>
                    <xsl:when test="@ref = 'SD'">Sophia Dege</xsl:when>
                    <xsl:when test="@ref = 'VP'">Vitagrazia Pisani</xsl:when>
                    <xsl:when test="@ref = 'IF'">Iosif Fridman</xsl:when>
                    <xsl:when test="@ref = 'SH'">Susanne Hummel</xsl:when>
                    <xsl:when test="@ref = 'FP'">Francesca Panini</xsl:when>
                    <xsl:when test="@ref = 'AA'">Abreham Adugna</xsl:when>
                    <xsl:when test="@ref = 'EG'">Ekaterina Gusarova</xsl:when>
                    <xsl:when test="@ref = 'IR'">Irene Roticiani</xsl:when>
                    <xsl:when test="@ref = 'MB'">Maria Bulakh</xsl:when>
                    <xsl:when test="@ref = 'VR'">Veronika Roth</xsl:when>
                    <xsl:when test="@ref = 'MK'">Magdalena Krzyzanowska</xsl:when>
                    <xsl:when test="@ref = 'DE'">Daria Elagina</xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="@ref"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="filename">
                    <xsl:choose>
                        <xsl:when test="contains(@ref, '#')">
                            <xsl:value-of select="substring-before(@ref, '#')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@ref"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <span xmlns="http://www.w3.org/1999/xhtml" class="persName">
                    <xsl:choose>
                        <xsl:when test="t:choice">
                            <xsl:apply-templates select="t:choice"/>
                        </xsl:when>
                        <xsl:when test="t:roleName">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:when test="text()">
                            <xsl:value-of select="."/>
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="MainTitle" data-value="{@ref}"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
                <xsl:if test="@role"> (<xsl:value-of select="@role"/>)</xsl:if>
                <xsl:if test="@evidence">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="@evidence"/>
                    <xsl:text>) </xsl:text>
                </xsl:if>
                <xsl:if test="@cert = 'low'">
                    <xsl:text> ? </xsl:text>
                </xsl:if>
                <xsl:if test="t:note">
                    <xsl:apply-templates select="t:note"/>
                </xsl:if><!--
                <xsl:if test="t:roleName">
                    <xsl:apply-templates select="t:roleName"/>
                </xsl:if>-->
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
   
    <xsl:template match="t:roleName" mode="nolink">
            <xsl:value-of select="concat(., ' ')"/>
    </xsl:template>
    
    <xsl:template match="t:roleName">
        <a xmlns="http://www.w3.org/1999/xhtml" href="#" data-toggle="tooltip" title="role: {@type}">
            <xsl:value-of select="concat(., ' ')"/>
        </a>
    </xsl:template>
</xsl:stylesheet>