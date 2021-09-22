<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:funct="my.funct" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:function name="funct:date">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="matches($date, '\d{4}-\d{2}-\d{2}')">
                <xsl:value-of select="format-date(xs:date($date), '[D]-[M]-[Y0001]', 'en', 'AD', ())"/>
            </xsl:when><xsl:when test="matches($date, '\d{4}-\d{2}')">
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
              <xsl:if test="//t:education">
                  <div class="w3-container" id="education"> <h4>Education</h4>
                      <p>
                          <xsl:apply-templates select="//t:education" mode="noP"/>
                      </p>
                  </div>
              </xsl:if>
            <xsl:if test="//t:floruit">
                <div class="w3-container" id="floruit"> <h4>Period of Activity</h4>
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
                  <xsl:for-each select="//t:person/t:note"><div class="w3-container"> 
                      <xsl:choose>
                          <xsl:when test="@type"><h4><xsl:value-of select="concat(upper-case(substring(@type, 1,1)), substring(@type, 2))"/></h4></xsl:when>
                          <xsl:otherwise><h4>Notes</h4></xsl:otherwise>
                      </xsl:choose>
                      <xsl:apply-templates select="."/>
                  </div></xsl:for-each>
              </xsl:if>
              <xsl:if test="//t:relation">
                  <div class="w3-container">
                  <p>
                      <xsl:if test="//t:relation[not(@name= 'betmas:formerlyAlsoListedAs')]">
                          <xsl:text>See </xsl:text>
                      </xsl:if>
                      <xsl:for-each select="//t:relation[not(@name= 'betmas:formerlyAlsoListedAs')]">
                          <xsl:sort order="ascending" select="count(preceding-sibling::t:relation)+1"/>
                          <xsl:variable name="p" select="count(preceding-sibling::t:relation)+1"/>
                          <xsl:variable name="tot" select="count(//t:relation)"/>
                          <xsl:apply-templates select="." mode="gendesc"/>
                                    <xsl:choose>
                              <xsl:when test="$p!=$tot">
                                            <xsl:text>, </xsl:text>
                                        </xsl:when>
                              <xsl:otherwise>.</xsl:otherwise>
                                    </xsl:choose>
                      </xsl:for-each>
                      For a table of all relations from and to this record, please go to the <a class="w3-tag w3-gray" href="/persons/{$mainID}/analytic">Relations</a> view. In the Relations boxes on the right of this page, you can also find all available relations grouped by name.
                  </p>
                  </div>
              </xsl:if>
              <button class="w3-button w3-red w3-large" id="showattestations" data-value="person" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
              <div id="allattestations" class="col-md-12"/>
        </div>
           <div class="w3-quarter w3-panel w3-red w3-card-4 w3-padding " id="description" rel="http://xmlns.com/foaf/0.1/name">
               <h3>Names <xsl:if test="//t:person/@sex">
                   <xsl:choose>
                       <xsl:when test="//t:person/@sex = 1">
                           <i class="fa fa-mars"/>
                       </xsl:when>
                       <xsl:when test="//t:person/@sex = 2">
                           <i class="fa fa-venus"/>
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
                               <xsl:if test="//t:person/t:persName[contains(@corresp, $id)]">
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
                           <p>Birth: <xsl:value-of select="funct:datepicker(.)"/>
                                </p>
                       </xsl:for-each>
                       <xsl:for-each select="//t:floruit[@when or @notBefore or @notAfter ]">
                           <p>Period of activity: <xsl:value-of select="funct:datepicker(.)"/>
                                </p>
                       </xsl:for-each>
                       <xsl:for-each select="//t:death[@when or @notBefore or @notAfter ]">
                           <p>Death: <xsl:value-of select="funct:datepicker(.)"/>
                                </p>
                       </xsl:for-each>
                   </xsl:if>
               </xsl:if>
               
               <xsl:if test="//t:occupation">
                   <h3>Occupation</h3>
                   
                   <xsl:for-each select="//t:occupation">
                       <p class="lead" property="http://data.snapdrgn.net/ontology/snap#occupation">
                           <xsl:if test="@from or @to">
                               <xsl:value-of select="funct:date(@from)"/>
                               <xsl:text>-</xsl:text>
                               <xsl:value-of select="funct:date(@to)"/>
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