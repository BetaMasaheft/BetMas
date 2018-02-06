<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:date">
        <xsl:choose>
            <xsl:when test="text()"/>
            <xsl:otherwise>
                <xsl:choose>
                <xsl:when test="@when">
                <xsl:value-of select="@when"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@notBefore and @notAfter">
                        <xsl:value-of select="@notBefore"/>
                        <xsl:text>-</xsl:text>
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
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:if test="@evidence"> (<xsl:value-of select="@evidence"/>)</xsl:if>
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
        <xsl:apply-templates/>
        <xsl:if test="not(following-sibling::text())">
            <br/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:date[@calendar]">
        <xsl:variable name="id" select="generate-id(.)"/>
        <xsl:apply-templates/>
        <a id="date{$id}calendar">
            <i class="fa fa-calendar-plus-o" aria-hidden="true"/>
        </a>
    </xsl:template>
    <xsl:template name="calendar">
        <xsl:param name="dates"/>
        <xsl:for-each select="//t:date[@calendar]">
            <div class="hidden">
            <div id="dateInfo{generate-id(.)}">
                <table class="table table-hover table-responsive">
                    <thead>
                        <tr>
                            <th>info</th>
                            <th>value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Standard date</td>
                            <td>
                                <xsl:choose>
                                    <xsl:when test="@when">
                                        <xsl:value-of select="@when"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:choose>
                                            <xsl:when test="@notBefore and @notAfter">
                                                <xsl:value-of select="@notBefore"/>
                                                <xsl:text>-</xsl:text>
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
                            </td>
                        </tr>
                        <tr>
                            <td>Date in current calendar</td>
                            <td>
                                <xsl:choose>
                                    <xsl:when test="@when-custom">
                                        <xsl:value-of select="@when-custom"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:choose>
                                            <xsl:when test="@notBefore-custom and @notAfter-custom">
                                                <xsl:value-of select="@notBefore-custom"/>
                                                <xsl:text>-</xsl:text>
                                                <xsl:value-of select="@notAfter-custom"/>
                                            </xsl:when>
                                            <xsl:when test="@notAfter-custom and not(@notBefore-custom)">
                                                <xsl:text>Before </xsl:text>
                                                <xsl:value-of select="@notAfter-custom"/>
                                            </xsl:when>
                                            <xsl:when test="@notBefore-custom and not(@notAfter-custom)">
                                                <xsl:text>After </xsl:text>
                                                <xsl:value-of select="@notBefore-custom"/>
                                            </xsl:when>
                                        </xsl:choose>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                        <tr>
                            <td>Calendar</td>
                            <td>
                                <xsl:value-of select="@calendar"/>
                            </td>
                        </tr>
                        <xsl:if test="@dur">
                            <tr>
                                <td>Duration</td>
                                <td>
                                    <xsl:value-of select="@dur"/>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="@type">
                            <tr>
                                <td>Date type</td>
                                <td>
                                    <xsl:value-of select="@type"/>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="@evidence">
                            <tr>
                                <td>Evidence</td>
                                <td>
                                    <xsl:value-of select="@evidence"/>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="@cert">
                            <tr>
                                <td>Certainty</td>
                                <td>
                                    <xsl:value-of select="@cert"/>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="@resp">
                            <tr>
                                <td>Attribution</td>
                                <td>
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
                                            <xsl:when test="t:corr/@resp = 'DR'">Dorotdea Reule</xsl:when>
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
                                    <xsl:copy-of select="$resp"/>
                                </td>
                            </tr>
                        </xsl:if>
                    </tbody>
                </table>
            </div>
        </div>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>