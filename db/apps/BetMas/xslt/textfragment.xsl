<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dts="https://w3id.org/dts/api#" xmlns:funct="my.funct" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:param name="mainID"/>
<!--    <xsl:param name="translation"/>-->
    <xsl:function name="funct:date">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, '\d{4}-\d{2}-\d{2}')">
                <xsl:value-of select="format-date(xs:date($date), '[D]-[M]-[Y0001]', 'en', 'AD', ())"/>
            </xsl:when>
            <xsl:when test="matches($date, '\d{4}-\d{2}')">
                <xsl:variable name="monthnumber" select="substring-after($date, '-')"/>
                <xsl:variable name="monthname">
                    <xsl:choose>
                        <xsl:when test="$monthnumber = '01'">January</xsl:when>
                        <xsl:when test="$monthnumber = '02'">February</xsl:when>
                        <xsl:when test="$monthnumber = '03'">March</xsl:when>
                        <xsl:when test="$monthnumber = '04'">April</xsl:when>
                        <xsl:when test="$monthnumber = '05'">May</xsl:when>
                        <xsl:when test="$monthnumber = '06'">June</xsl:when>
                        <xsl:when test="$monthnumber = '07'">July</xsl:when>
                        <xsl:when test="$monthnumber = '08'">August</xsl:when>
                        <xsl:when test="$monthnumber = '09'">September</xsl:when>
                        <xsl:when test="$monthnumber = '10'">October</xsl:when>
                        <xsl:when test="$monthnumber = '11'">November</xsl:when>
                        <xsl:when test="$monthnumber = '12'">December</xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="concat(replace(substring-after($date, '-'), $monthnumber, $monthname), ' ', substring-before($date, '-'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="format-number($date, '####')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="funct:datepicker">
        <xsl:param name="element"/>
        <xsl:choose>
            <xsl:when test="$element/@notBefore or $element/@notAfter">
                <xsl:if test="not($element/@notBefore)">Before </xsl:if>
                <xsl:if test="not($element/@notAfter)">After </xsl:if>
                <xsl:if test="$element/@notBefore">
                    <xsl:value-of select="funct:date($element/@notBefore)"/>
                </xsl:if>
                <xsl:if test="$element/@notBefore and $element/@notAfter">
                    <xsl:text>-</xsl:text>
                </xsl:if>
                <xsl:if test="$element/@notAfter">
                    <xsl:value-of select="funct:date($element/@notAfter)"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="funct:date($element/@when)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$element/@cert">
            <xsl:value-of select="concat(' (certainty: ', $element/@cert, ')')"/>
        </xsl:if>
    </xsl:function>
    <xsl:template match="/">
        <div>
                <div id="transcription">
                <xsl:if test="not(./child::t:div)">
                    <xsl:attribute name="class">w3-container chapterText</xsl:attribute>
                </xsl:if>
                    <xsl:apply-templates/>
                    <div class="w3-modal" id="textHelp">
                        <div class="w3-modal-content">
                            <header class="w3-container w3-red">
                                <h2>Text visualization help</h2>
                                <span class="w3-button w3-display-topright" onclick="document.getElementById('textHelp').style.display='none'">
                                    <i class="fa fa-times"/>
                                </span>
                            </header>
                            <div class="w3-container w3-margin">
                                Page breaks are indicated with a line and the number of the page break.
                                Column breaks are indicated with a pipe (|) followed by the name of the column.
                                <p>In the text navigation bar:</p>
                                <ul class="nodot">
                                    <li>References are relative to the current level of the view. If you want to see further navigation levels, please click the arrow to open in another page.</li>
                                    <li>Each reference available for the current view can be clicked to scroll to that point. alternatively you can view the section clicking on the arrow.</li>
                                    <li>Using an hyphen between references, like LIT3122Galaw.1-2 you can get a view of these two sections only</li>
                                    <li>Clicking on an index will call the list of relevant annotated entities and print a parallel navigation aid. This is not limited to the context but always refers to the entire text. 
                                        Also these references can either be clicked if the text is present in the context or can be opened clicking on the arrow, to see them in another page.</li>
                                </ul>
                                
                                <p>In the text:</p>
                                <ul class="nodot">
                                    <li>Click on ↗ to see the related items in Pelagios.</li>
                                    <li>Click on <i class="fa fa-hand-o-left"/>
                                        to see the which entities within Beta maṣāḥǝft point to this identifier.</li>
                                    <li>
                                        <sup>[!]</sup> contains additional information related to uncertainties in the encoding.</li>
                                    <li>Superscript digits refer to notes in the apparatus which are displayed on the right.</li>
                                    <li>to return to the top of the page, please use the back to top button</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    
                  </div>
                <script type="text/javascript" src="resources/js/pelagios.js"/>
               <img id="loadingRole" src="resources/Loading.gif" style="display: none;"/>
                <div id="versions" class="w3-container"/>   
           <xsl:if test="//t:pb[@facs]">
                    <div id="viewer" class="w3-container"/>
                    <xsl:variable name="iiifMSWitColl" select="concat('/api/iiif/witnesses/', $mainID)"/>
                    <script type="text/javascript">
                        <xsl:text>var data = [{collectionUri: "</xsl:text>
                        <xsl:value-of select="$iiifMSWitColl"/>
                        <xsl:text>"}]</xsl:text>
                    </script>
                    <script type="text/javascript" src="resources/js/editionmirador.js"/>
                </xsl:if>
                <div id="roleAttestations" class="w3-container"/>  
            </div>
        
        <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="t:relation"/>
    <xsl:include href="resp.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
</xsl:stylesheet>