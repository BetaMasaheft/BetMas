<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:msDesc">
        <div class="col-md-8 well" id="textualcontents{@xml:id}">

            <xsl:if test="t:history">
            <div id="{@xml:id}history">
                <xsl:apply-templates select="t:history"/>
            </div>
            <xsl:if test="t:msContents">
                <div id="{@xml:id}content" class="col-md-12">
                    <xsl:apply-templates select="t:msContents"/>
                </div>
            </xsl:if>
            <xsl:if test="t:physDesc/t:additions">
                <div id="{@xml:id}additiones">
                    <xsl:apply-templates select="t:physDesc/t:additions"/>
                </div>
            </xsl:if>
            <xsl:if test="t:physDesc/t:decoDesc">
                <div id="{@xml:id}decoration">
                    <xsl:apply-templates select="t:physDesc/t:decoDesc"/>
                </div>
            </xsl:if>
            <xsl:if test="t:additional">
                <div id="{@xml:id}additionals">
                    <xsl:apply-templates select="t:additional"/>
                </div>
            </xsl:if>

        </xsl:if>

        </div>
        <div class="col-md-4" id="codicologicalInformation{@xml:id}">

        <xsl:if test="t:msContents/t:summary">
            <xsl:apply-templates select="t:msContents/t:summary"/>
        </xsl:if>

        <xsl:if test="t:physDesc//t:objectDesc/t:supportDesc">
            <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:bindingDesc">
            <div id="{@xml:id}binding">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:sealDesc">
            <div id="{@xml:id}seals">
                <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc//t:objectDesc/t:layoutDesc">
            <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="t:physDesc/t:handDesc">
            <div id="{@xml:id}hands">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
        </xsl:if>
        <xsl:if test="ancestor::t:TEI//t:persName[@role]">
          <div id="perswithrolemainview" class="alert alert-info">
            <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">

            <xsl:apply-templates select="."/>
                        <br/>
          </xsl:for-each-group>
          </div>
          </xsl:if>
        </div>
        <xsl:if test="t:msPart">
            <div id="{@xml:id}parts">
                <xsl:apply-templates select="t:msPart"/>
            </div>
        </xsl:if>
        <xsl:if test="t:msFrag">
            <div id="{@xml:id}fragments">
                <xsl:apply-templates select="t:msFrag"/>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:msPart[parent::t:sourceDesc or parent::t:msDesc]">
        <div>
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>

            <div class="col-md-12">
                <h2>Codicological Unit <xsl:value-of select="substring-after(@xml:id, 'p')"/>
                </h2>
            </div>
            <div class="col-md-8 well" id="textualcontents{@xml:id}">
                <div id="{@xml:id}history">
                <xsl:apply-templates select="t:history"/>
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
            <div class="col-md-4" id="codicologicalInformation{@xml:id}">
                <xsl:if test="t:msContents/t:summary">
                <xsl:apply-templates select="t:msContents/t:summary"/>
            </xsl:if>
                <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
            <div id="{@xml:id}binding">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
            <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
            <div id="{@xml:id}hands">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test="ancestor::t:TEI//t:persName[@role]">
              <div id="perswithrolemainview" class="alert alert-info">
                <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">

                <xsl:apply-templates select="."/>
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


    <xsl:template match="t:msFrag[parent::t:sourceDesc or parent::t:msDesc]">
        <div>
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <div class="col-md-12">
                <h2>Fragment <xsl:value-of select="substring-after(@xml:id, 'f')"/>
                </h2>
            </div>
            <div class="col-md-8 well" id="textualcontents{@xml:id}">
                <div id="{@xml:id}history">
                <xsl:apply-templates select="t:history"/>
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
            <div class="col-md-4" id="codicologicalInformation{@xml:id}">
                <xsl:if test="t:msContents/t:summary">
                <xsl:apply-templates select="t:msContents/t:summary"/>
            </xsl:if>
                <div id="{@xml:id}dimensions">
                    <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
                </div>
                <div id="{@xml:id}binding">
                    <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
                </div>
                <xsl:if test="t:physDesc//t:sealDesc">
                    <div id="{@xml:id}seals">
                        <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                    </div>
                </xsl:if>
                <div id="{@xml:id}dimensions">
                    <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
                </div>
                <div id="{@xml:id}hands">
                    <xsl:apply-templates select="t:physDesc/t:handDesc"/>
                </div>
                <xsl:if test="ancestor::t:TEI//t:persName[@role]">
                  <div id="perswithrolemainview" class="alert alert-info">
                    <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">

                    <xsl:apply-templates select="."/>
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
        <div class="msPart col-md-12">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <hr align="left" class="msParts"/>
            <div class="col-md-8 well" id="textualcontents{@xml:id}">
                <div id="{@xml:id}history">
                <xsl:apply-templates select="t:history"/>
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
            <div class="col-md-4" id="codicologicalInformation{@xml:id}">
                <xsl:if test="t:msContents/t:summary">
                <xsl:apply-templates select="t:msContents/t:summary"/>
            </xsl:if>
                <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
            <div id="{@xml:id}binding">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
            <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
            <div id="{@xml:id}hands">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test="ancestor::t:TEI//t:persName[@role]">
              <div id="perswithrolemainview" class="alert alert-info">
                <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">

                <xsl:apply-templates select="."/>
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
        <div class="msFrag col-md-12">
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <hr align="left" class="msParts"/>
            <div class="col-md-8 well" id="textualcontents{@xml:id}">
                <div id="{@xml:id}history">
                <xsl:apply-templates select="t:history"/>
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
            <div class="col-md-4" id="codicologicalInformation{@xml:id}">
                <xsl:if test="t:msContents/t:summary">
                <xsl:apply-templates select="t:msContents/t:summary"/>
            </xsl:if>
                <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:supportDesc"/>
            </div>
            <div id="{@xml:id}binding">
                <xsl:apply-templates select="t:physDesc//t:bindingDesc"/>
            </div>
            <xsl:if test="t:physDesc//t:sealDesc">
                <div id="{@xml:id}seals">
                    <xsl:apply-templates select="t:physDesc//t:sealDesc"/>
                </div>
            </xsl:if>
            <div id="{@xml:id}dimensions">
                <xsl:apply-templates select="t:physDesc//t:objectDesc/t:layoutDesc"/>
            </div>
            <div id="{@xml:id}hands">
                <xsl:apply-templates select="t:physDesc/t:handDesc"/>
            </div>
            <xsl:if test="ancestor::t:TEI//t:persName[@role]">
              <div id="perswithrolemainview" class="alert alert-info">
                <xsl:for-each-group select="ancestor::t:TEI//t:persName[@role]" group-by="@ref">

                <xsl:apply-templates select="."/>
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