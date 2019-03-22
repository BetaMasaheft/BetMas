<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:template match="/">
       <div class="w3-twothird" id="MainData">
           <div class="w3-container">
          <div class="w3-threequarter w3-padding" id="history">
            <xsl:if test="//t:birth">
                <div class="w3-container" id="birth"> <h4>Birth</h4>
                <p>
                            <xsl:apply-templates select="//t:birth" mode="noP"/>
                        </p>
                </div>
            </xsl:if>
            <xsl:if test="//t:floruit">
                <div class="w3-container" id="floruit"> <h4>Floruit</h4>
                    <p>
                            <xsl:apply-templates select="//t:floruit" mode="noP"/>
                        </p>
                </div>
            </xsl:if>
            <xsl:if test="//t:death">
                <div class="w3-container" id="death"> <h4>Death</h4>
                   <p>
                            <xsl:apply-templates select="//t:death" mode="noP"/>
                        </p>
                </div>
            </xsl:if>
              <xsl:if test="//t:person/t:note">
                  <div class="w3-container"> <h4>Notes</h4>
                      <xsl:apply-templates select="//t:person/t:note"/>
                  </div>
              </xsl:if>
              
              <button class="w3-button w3-red w3-large" id="showattestations" data-value="person" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
              <div id="allattestations" class="col-md-12"/>
        </div>
           <div class="w3-quarter w3-panel w3-red w3-card-4 w3-padding " id="description" rel="http://xmlns.com/foaf/0.1/name">
               <h3>Names <xsl:if test="//t:person/@sex">
                   <xsl:choose>
                       <xsl:when test="//t:person/@sex = 1">
                           <i class="icon-large icon-male"/>
                       </xsl:when>
                       <xsl:when test="//t:person/@sex = 2">
                           <i class="icon-large icon-female"/>
                       </xsl:when>
                   </xsl:choose>
               </xsl:if>
                   <xsl:if test="//t:person/@sameAs">
                       <a href="{//t:person/@sameAs}">
                           <span class="icon-large icon-vcard"/>
                       </a>
                   </xsl:if>
               </h3>
               
               <ul class="nodot">
               <xsl:choose>
                   <xsl:when test="//t:personGrp">
                       <xsl:for-each select="//t:personGrp/t:persName[@xml:id]">
                           <xsl:sort select="if (@xml:id) then @xml:id else text()"/>
                           <xsl:variable name="id" select="@xml:id"/>
                           <li>
                               <xsl:if test="@xml:id">
                                   <xsl:attribute name="id">
                                       <xsl:value-of select="@xml:id"/>
                                   </xsl:attribute>
                               </xsl:if>
                               <xsl:if test="@type">
                                   <xsl:value-of select="concat(@type, ': ')"/>
                               </xsl:if>
                               <xsl:if test="t:roleName">
                                   <xsl:apply-templates select="t:roleName"/>
                               </xsl:if>
                               <xsl:choose>
                                   <xsl:when test="@ref">
                                       <a href="{@ref}" target="_blank">
                                           <xsl:value-of select=". except t:roleName"/>
                                       </a>
                                   </xsl:when>
                                   <xsl:otherwise>
                                       <xsl:value-of select=". except t:roleName"/>
                                   </xsl:otherwise>
                               </xsl:choose>
                               <xsl:if test="@xml:lang">
                                   <sup>
                                       <xsl:value-of select="@xml:lang"/>
                                   </sup>
                               </xsl:if>
                               <xsl:if test="//t:personGrp/t:persName[@corresp]">
                                   <xsl:text> (</xsl:text>
                                   <xsl:for-each select="//t:personGrp/t:persName[substring-after(@corresp, '#') = $id]">
                                       <xsl:sort/>
                                       <xsl:value-of select="."/>
                                       <xsl:if test="@xml:lang">
                                           <sup>
                                               <xsl:value-of select="@xml:lang"/>
                                           </sup>
                                       </xsl:if>
                                       <xsl:if test="position() != last()">
                                           <xsl:text>, </xsl:text>
                                       </xsl:if>
                                   </xsl:for-each>
                                   <xsl:text>)</xsl:text>
                               </xsl:if>
                           </li>
                       </xsl:for-each>
                       <xsl:if test="//t:personGrp/t:persName[not(@xml:id or @corresp)]">
                           <xsl:for-each select="//t:personGrp/t:persName[not(@xml:id or @corresp)]">
                               <xsl:sort/>
                               <li>
                                   <xsl:if test="@type">
                                       <xsl:value-of select="concat(@type, ': ')"/>
                                   </xsl:if>
                                   <xsl:if test="t:roleName">
                                       <xsl:apply-templates select="t:roleName"/>
                                   </xsl:if>
                                   <xsl:choose>
                                       <xsl:when test="@ref">
                                           <a href="{@ref}" target="_blank">
                                               <xsl:value-of select=". except t:roleName"/>
                                           </a>
                                       </xsl:when>
                                       <xsl:otherwise>
                                           <xsl:value-of select=". except t:roleName"/>
                                       </xsl:otherwise>
                                   </xsl:choose>
                                   <xsl:if test="@xml:lang">
                                       <sup>
                                           <xsl:value-of select="@xml:lang"/>
                                       </sup>
                                   </xsl:if>
                               </li>
                           </xsl:for-each>
                       </xsl:if>
                   </xsl:when>
                   <xsl:otherwise>
                       <xsl:for-each select="//t:person/t:persName[@xml:id]">
                           <xsl:sort select="if (@xml:id) then @xml:id else text()"/>
                           <xsl:variable name="id" select="@xml:id"/>
                           <li>
                               <xsl:if test="@xml:id">
                                   <xsl:attribute name="id">
                                       <xsl:value-of select="@xml:id"/>
                                   </xsl:attribute>
                               </xsl:if>
                               <xsl:if test="@type">
                                   <xsl:value-of select="concat(@type, ': ')"/>
                               </xsl:if>
                               <xsl:choose>
                                   <xsl:when test="@ref">
                                       <a href="{@ref}" target="_blank">
                                           <xsl:value-of select="."/>
                                       </a>
                                   </xsl:when>
                                   <xsl:otherwise>
                                       <xsl:apply-templates/>
                                   </xsl:otherwise>
                               </xsl:choose>
                               <xsl:if test="@xml:lang">
                                   <sup>
                                       <xsl:value-of select="@xml:lang"/>
                                   </sup>
                               </xsl:if>
                               <xsl:if test="//t:person/t:persName[@corresp]">
                                   <xsl:text> (</xsl:text>
                                   <xsl:for-each select="//t:person/t:persName[substring-after(@corresp, '#') = $id]">
                                       <xsl:sort/>
                                       <xsl:value-of select="."/>
                                       <xsl:if test="@xml:lang">
                                           <sup>
                                               <xsl:value-of select="@xml:lang"/>
                                           </sup>
                                       </xsl:if>
                                       <xsl:if test="position() != last()">
                                           <xsl:text>, </xsl:text>
                                       </xsl:if>
                                   </xsl:for-each>
                                   <xsl:text>)</xsl:text>
                               </xsl:if>
                           </li>
                       </xsl:for-each>
                       <xsl:if test="//t:person/t:persName[not(@xml:id or @corresp)]">
                           <xsl:for-each select="//t:person/t:persName[not(@xml:id or @corresp)]">
                               <xsl:sort/>
                               <li>
                                   <xsl:if test="@type">
                                       <xsl:value-of select="concat(@type, ': ')"/>
                                   </xsl:if>
                                   <xsl:choose>
                                       <xsl:when test="@ref">
                                           <a href="{@ref}" target="_blank">
                                               <xsl:value-of select="."/>
                                           </a>
                                       </xsl:when>
                                       <xsl:otherwise>
                                           <xsl:apply-templates/>
                                       </xsl:otherwise>
                                   </xsl:choose>
                                   <xsl:if test="@xml:lang">
                                       <sup>
                                           <xsl:value-of select="@xml:lang"/>
                                       </sup>
                                   </xsl:if>
                               </li>
                           </xsl:for-each>
                       </xsl:if>
                   </xsl:otherwise>
               </xsl:choose>
               </ul>
               <xsl:if test="//t:floruit/@* or //t:birth/@* or //t:death/@*">
                   <h3>Dates </h3>
                   <xsl:if test="//t:birth[@when or @notBefore or @notAfter ] or                             //t:death[@when or @notBefore or @notAfter  ] or                             //t:floruit[@when or @notBefore or @notAfter ]">
                       <xsl:for-each select="//t:birth[@when or @notBefore or @notAfter ]">
                           <p>Birth: <xsl:choose>
                               <xsl:when test="@notBefore or @notAfter">
                                   <xsl:value-of select="@notBefore"/>
                                   <xsl:text>-</xsl:text>
                                   <xsl:value-of select="@notAfter"/>
                               </xsl:when>
                               <xsl:otherwise>
                                            <xsl:value-of select="@when"/>
                                        </xsl:otherwise>
                           </xsl:choose>
                               <xsl:if test="@cert">
                                        <xsl:value-of select="concat(' (', @cert, ')')"/>
                                    </xsl:if>
                           </p>
                       </xsl:for-each>
                       <xsl:for-each select="//t:floruit[@when or @notBefore or @notAfter ]">
                           <p>Floruit: <xsl:choose>
                               <xsl:when test="@notBefore or @notAfter">
                                   <xsl:value-of select="@notBefore"/>
                                   <xsl:text>-</xsl:text>
                                   <xsl:value-of select="@notAfter"/>
                               </xsl:when>
                               <xsl:otherwise>
                                            <xsl:value-of select="@when"/>
                                        </xsl:otherwise>
                           </xsl:choose>
                               <xsl:if test="@cert">
                                        <xsl:value-of select="concat(' (', @cert, ')')"/>
                                    </xsl:if>
                           </p>
                       </xsl:for-each>
                       <xsl:for-each select="//t:death[@when or @notBefore or @notAfter ]">
                           <p>Death: <xsl:choose>
                               <xsl:when test="@notBefore or @notAfter">
                                   <xsl:value-of select="@notBefore"/>
                                   <xsl:text>-</xsl:text>
                                   <xsl:value-of select="@notAfter"/>
                               </xsl:when>
                               <xsl:otherwise>
                                            <xsl:value-of select="@when"/>
                                        </xsl:otherwise>
                           </xsl:choose>
                               <xsl:if test="@cert">
                                        <xsl:value-of select="concat(' (', @cert, ')')"/>
                                    </xsl:if>
                           </p>
                       </xsl:for-each>
                   </xsl:if>
               </xsl:if>
               
               <xsl:if test="//t:occupation">
                   <h3>Occupation</h3>
                   
                   <xsl:for-each select="//t:occupation">
                       <p class="lead" property="http://data.snapdrgn.net/ontology/snap#occupation">
                           <xsl:if test="@from or @to">
                               <xsl:value-of select="@from"/>
                               <xsl:text>-</xsl:text>
                               <xsl:value-of select="@to"/>
                           </xsl:if>
                           <xsl:apply-templates select="."/>
                           <xsl:text> (</xsl:text>
                           <xsl:value-of select="@type"/>
                           <xsl:text>)
                </xsl:text>
                       </p>
                   </xsl:for-each>
               </xsl:if>
               <xsl:if test="//t:residence/text()">
                   <h3>Residence</h3>
                   <p class="lead">
                       <xsl:apply-templates select="//t:residence"/>
                   </p>
               </xsl:if>
               <xsl:if test="//t:faith">
                   <h3>Faith</h3>
                   <p class="lead">
                       <xsl:apply-templates select="//t:faith"/>
                   </p>
               </xsl:if>
               <xsl:if test="//t:nationality">
                   <h3>Nationality</h3>
                   <p class="lead">
                       <xsl:apply-templates select="//t:nationality"/>
                   </p>
               </xsl:if>
           </div>
           
       </div>
        <div id="bibliography">
            <xsl:apply-templates select="//t:listBibl"/>
        </div>
       </div> 
        <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="t:surname">
        <xsl:value-of select="."/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename">
        <xsl:value-of select="."/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:nationality">
        <xsl:choose>
            <xsl:when test="text()">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@type"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:include href="resp.xsl"/>
    <!-- elements templates-->
    <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="editorKey.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/>
    <xsl:include href="faith.xsl"/>
    <xsl:include href="provenance.xsl"/>
    <xsl:include href="handDesc.xsl"/>
    <xsl:include href="msContents.xsl"/>
    <xsl:include href="history.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    
<!--    elements with references-->
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
                           <!-- includes also region, country and settlement-->
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/> 
                            <!--produces also the javascript for graph-->
</xsl:stylesheet>