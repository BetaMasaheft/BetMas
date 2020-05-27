<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:msDesc">
        <div class="w3-twothird well" id="textualcontents{@xml:id}">
<div class="w3-half">
            <xsl:if test="t:history">
                <div id="{@xml:id}history" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:history"/>
            </div>
            </xsl:if>
</div>
            <div class="w3-half">
            <xsl:if test="t:msContents/t:summary">
                <xsl:apply-templates select="t:msContents/t:summary"/>
            </xsl:if>
            </div>
            <xsl:if test="t:msContents">
                <div id="{@xml:id}content" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:msContents"/>
                </div>
            </xsl:if>
            <xsl:if test="t:physDesc/t:additions">
                <div id="{@xml:id}additiones" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
            </xsl:if>
            <xsl:if test="t:physDesc/t:decoDesc">
                <div id="{@xml:id}decoration" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
            </xsl:if>
            <xsl:if test="t:additional">
                <div id="{@xml:id}additionals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </xsl:if>


        </div>
        <div class="w3-third w3-border-left" id="codicologicalInformation{@xml:id}">


        <xsl:if test="t:physDesc//t:objectDesc/t:supportDesc">
            <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:bindingDesc">
            <div id="{@xml:id}binding" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:sealDesc">
            <div id="{@xml:id}seals" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:objectDesc/t:layoutDesc">
            <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc/t:handDesc">
            <div id="{@xml:id}hands" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="ancestor::t:TEI//t:persName[@role]">
            <div id="perswithrolemainview" class="w3-panel w3-red w3-card-4 w3-margin-bottom">
            <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">
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
                <xsl:if test="current-group()/@role"> (<xsl:value-of select="distinct-values(current-group()/@role)" separator=", "/>)</xsl:if>
                <br/>
          </xsl:for-each-group>
          </div>
          </xsl:if>
        </div>
        <xsl:if test="t:msPart">
            <div id="{@xml:id}parts" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:msPart"/>
            </div>
        </xsl:if>
        <xsl:if test="t:msFrag">
            <div id="{@xml:id}fragments" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template mode="unit" match="t:repository">
        <a target="_blank" href="/manuscripts/{@ref}/list" role="button" class="w3-tag w3-gray w3-margin-top" property="http://www.cidoc-crm.org/cidoc-crm/P55_has_current_location" resource="http://betamasaheft.eu/{@ref}">
            <span class="MainTitle" data-value="{@ref}">
                <xsl:value-of select="@ref"/>
            </span>
        </a>
    </xsl:template>
    <xsl:template mode="unit" match="t:collection">
        <p>Collection:  <xsl:value-of select="."/>
        </p>
    </xsl:template>
    <xsl:template mode="unit" match="t:idno">
        <p>
            <xsl:value-of select="."/>
        </p>
    </xsl:template>
    
    <xsl:template mode="unit" match="t:altIdentifier">
        <p>Also identified as</p>
        <xsl:apply-templates mode="unit"/>
    </xsl:template>
    
    <xsl:template match="t:msPart[parent::t:sourceDesc or parent::t:msDesc]">
        <div class="w3-container w3-margin-bottom">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>

            <div class="w3-container w3-margin-bottom">
                <h2>Codicological Unit <xsl:value-of select="substring-after(@xml:id, 'p')"/>
                </h2>
                
            </div>
            <div class="w3-twothird" id="textualcontents{@xml:id}">
                <div class="w3-panel w3-card-2 w3-margin-right">
                    <xsl:apply-templates select="t:msIdentifier" mode="unit"/>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:history">
                        <div id="{@xml:id}history" class="w3-container w3-margin-bottom">
                            <xsl:apply-templates select="t:history"/>
                        </div>
                    </xsl:if>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:msContents/t:summary">
                        <xsl:apply-templates select="t:msContents/t:summary"/>
                    </xsl:if>
                </div>
                <div id="{@xml:id}content" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:msContents except t:summary"/>
                </div>
                <div id="{@xml:id}additiones" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
                <div id="{@xml:id}decoration" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
                <div id="{@xml:id}additionals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </div>
            <div class="w3-third" id="codicologicalInformation{@xml:id}">
              <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
                <div id="{@xml:id}binding" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
                <div id="{@xml:id}hands" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test=".//t:persName[@role]">
                <div id="perswithrolemainview" class="w3-panel w3-red w3-card-4 w3-margin-bottom">
                <xsl:for-each-group select=".//t:persName[@role]" group-by="@ref">
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
                    <xsl:if test="current-group()/@role"> (<xsl:value-of select="distinct-values(current-group()/@role)" separator=", "/>)</xsl:if>
                    <br/>
              </xsl:for-each-group>
              </div>
              </xsl:if>
            </div>




            <div id="{@xml:id}parts" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:msPart"/>
            </div>
            <div id="{@xml:id}fragments" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </div>
        <hr align="left"/>
    </xsl:template>


    <xsl:template match="t:msFrag[parent::t:sourceDesc or parent::t:msDesc]">
        <div class="w3-container w3-margin-bottom">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <div class="w3-container w3-margin-bottom">
                <h2>Fragment <xsl:value-of select="substring-after(@xml:id, 'f')"/>
                </h2>
            </div>
            <div class="w3-twothird" id="textualcontents{@xml:id}">
                
                <div class="w3-panel w3-card-2 w3-margin-right">
                    <xsl:apply-templates select="t:msIdentifier" mode="unit"/>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:history">
                        <div id="{@xml:id}history" class="w3-container w3-margin-bottom">
                            <xsl:apply-templates select="t:history"/>
                        </div>
                    </xsl:if>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:msContents/t:summary">
                        <xsl:apply-templates select="t:msContents/t:summary"/>
                    </xsl:if>
                </div>
                <div id="{@xml:id}content" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:msContents except t:summary"/>
                </div>
                <div id="{@xml:id}additiones" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
                <div id="{@xml:id}decoration" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
                <div id="{@xml:id}additionals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </div>
            <div class="w3-third" id="codicologicalInformation{@xml:id}">
               
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
                </div>
                <div id="{@xml:id}binding" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
                </div>
                <xsl:if test="t:physDesc//t:sealDesc">
                    <div id="{@xml:id}seals" class="w3-container w3-margin-bottom">
                        <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                    </div>
                </xsl:if>
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
                </div>
                <div id="{@xml:id}hands" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:handDesc"/>
                </div>
                <xsl:if test=".//t:persName[@role]">
                    <div id="perswithrolemainview" class="w3-panel w3-red w3-card-4 w3-margin-bottom">
                    <xsl:for-each-group select=".//t:persName[@role]" group-by="@ref">
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
                        <xsl:if test="current-group()/@role"> (<xsl:value-of select="distinct-values(current-group()/@role)" separator=", "/>)</xsl:if>
                        <br/>
                  </xsl:for-each-group>
                  </div>
                  </xsl:if>
            </div>




            <div id="{@xml:id}parts">
                <xsl:apply-templates select="t:msPart"/>
            </div>
            <div id="{@xml:id}fragments">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </div>
        <hr align="left"/>
    </xsl:template>


    <xsl:template match="t:msPart[parent::t:msPart]">
        <div class="msPart w3-container">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <hr align="left" class="msParts"/>
            <div class="w3-twothird well" id="textualcontents{@xml:id}">
                <div class="w3-half">
                    <xsl:if test="t:history">
                        <div id="{@xml:id}history" class="w3-container w3-margin-bottom">
                            <xsl:apply-templates select="t:history"/>
                        </div>
                    </xsl:if>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:msContents/t:summary">
                        <xsl:apply-templates select="t:msContents/t:summary"/>
                    </xsl:if>
                </div>
                <div id="{@xml:id}content">
                    <xsl:apply-templates select="t:msContents except t:summary"/>
                </div>
                <div id="{@xml:id}additiones">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
                <div id="{@xml:id}decoration">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
                <div id="{@xml:id}additionals">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </div>
            <div class="w3-third" id="codicologicalInformation{@xml:id}">
                
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
                <div id="{@xml:id}binding" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
                <div id="{@xml:id}hands" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test=".//t:persName[@role]">
                <div id="perswithrolemainview" class="w3-panel w3-red w3-card-4 w3-margin-bottom">
                <xsl:for-each-group select=".//t:persName[@role]" group-by="@ref">
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
                    <xsl:if test="current-group()/@role"> (<xsl:value-of select="distinct-values(current-group()/@role)" separator=", "/>)</xsl:if>
                    <br/>
              </xsl:for-each-group>
              </div>
              </xsl:if>
            </div>




            <div id="{@xml:id}parts">
                <xsl:apply-templates select="t:msPart"/>
            </div>
            <div id="{@xml:id}fragments">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="t:msFrag[parent::t:msFrag]">
        <div class="msFrag w3-container">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <hr align="left" class="msParts"/>
            <div class="w3-twothird well" id="textualcontents{@xml:id}">
                <div class="w3-half">
                    <xsl:if test="t:history">
                        <div id="{@xml:id}history" class="w3-container w3-margin-bottom">
                            <xsl:apply-templates select="t:history"/>
                        </div>
                    </xsl:if>
                </div>
                <div class="w3-half">
                    <xsl:if test="t:msContents/t:summary">
                        <xsl:apply-templates select="t:msContents/t:summary"/>
                    </xsl:if>
                </div>
                <div id="{@xml:id}content" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:msContents except t:summary"/>
                </div>
                <div id="{@xml:id}additiones" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
                <div id="{@xml:id}decoration" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
                <div id="{@xml:id}additionals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </div>
            <div class="w3-third" id="codicologicalInformation{@xml:id}">
                
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
                <div id="{@xml:id}binding" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals" class="w3-container w3-margin-bottom">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
                <div id="{@xml:id}dimensions" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
                <div id="{@xml:id}hands" class="w3-container w3-margin-bottom">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test=".//t:persName[@role]">
                <div id="perswithrolemainview" class="w3-panel w3-red w3-card-4 w3-margin-bottom">
                <xsl:for-each-group select=".//t:persName[@role]" group-by="@ref">

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
                    <xsl:if test="current-group()/@role"> (<xsl:value-of select="distinct-values(current-group()/@role)" separator=", "/>)</xsl:if>
                            <br/>
              </xsl:for-each-group>
              </div>
              </xsl:if>
            </div>




            <div id="{@xml:id}parts">
                <xsl:apply-templates select="t:msPart"/>
            </div>
            <div id="{@xml:id}fragments">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>