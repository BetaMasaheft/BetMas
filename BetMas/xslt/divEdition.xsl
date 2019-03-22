<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    
    <xsl:template match="t:*[@xml:lang='gez']//text()[parent::t:*[name() != 'label'][name() != 'note'][name() != 'persName'] [name() != 'placeName']]">
        
        <xsl:if test=".!='' and .!=' '">
            <span class="word">
            <xsl:value-of select="."/>
        </span>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:app">
        <xsl:apply-templates select="t:lem" mode="text"/>
        <sup id="{ancestor::t:div[@type='textpart'][1]/@n}appNote{position()}">
            <a href="#{ancestor::t:div[@type='textpart'][1]/@n}appPointer{position()}">
                <xsl:value-of select="count(preceding-sibling::t:app) + 1"/>
            </a>
        </sup>
    </xsl:template>
    
    <xsl:template match="t:text">
        <h2>Transcription</h2>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:body">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:div[parent::t:body][not(@type = 'apparatus')]">
        <div class="w3-row" id="{@type}">
            <head>
                <xsl:if test="@corresp">
                    <a href="{@corresp}">
                        <xsl:value-of select="replace(substring-after(@corresp, '#'), '_', ' ')"/>
                        <xsl:if test="@subtype">
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="@subtype"/>
                            <xsl:if test="@n">
                                <xsl:text>: </xsl:text>
                                <xsl:value-of select="@n"/>
                            </xsl:if>
                        </xsl:if>
                    </a>
                </xsl:if>
            </head>
            <br/>
            <xsl:apply-templates/>
        </div>
        <br/>
    </xsl:template>
    
  
    <xsl:template match="t:div[@type = 'textpart'] | t:div[@type='edition'][not(child::t:div)]">
        <xsl:if test="not(descendant::t:pb) and not(parent::t:div[@type='textpart'])">
            <xsl:apply-templates select="preceding::t:pb[1]"/>
        </xsl:if>
        <xsl:variable name="text">
            <xsl:value-of select="./ancestor::t:TEI/@xml:id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="child::t:div[@type = 'textpart']">
                <xsl:if test="parent::t:div[@type='edition']/@resp">
                    <xsl:variable name="r" select="parent::t:div[@type='edition']/@resp"/>
                    Edition by <xsl:choose>
                        <xsl:when test="starts-with($r, '#')">
                            <span class="Zotero Zotero-full">
                                <xsl:attribute name="data-value">
                                    <xsl:value-of select="ancestor::t:TEI//t:bibl[@xml:id = substring-after($r, '#')]/t:ptr/@target"/>
                                </xsl:attribute>
                            </span>
                        </xsl:when>
                        <xsl:otherwise> <xsl:choose>
                            <xsl:when test="$r = 'AB'">Alessandro Bausi</xsl:when>
                            <xsl:when test="$r = 'ES'">Eugenia Sokolinski</xsl:when>
                            <xsl:when test="$r = 'DN'">Denis Nosnitsin</xsl:when>
                            <xsl:when test="$r = 'MV'">Massimo Villa</xsl:when>
                            <xsl:when test="$r = 'DR'">Dorothea Reule</xsl:when>
                            <xsl:when test="$r = 'SG'">Solomon Gebreyes</xsl:when>
                            <xsl:when test="$r = 'PL'">Pietro Maria Liuzzo</xsl:when>
                            <xsl:when test="$r = 'SA'">Stéphane Ancel</xsl:when>
                            <xsl:when test="$r = 'SD'">Sophia Dege</xsl:when>
                            <xsl:when test="$r = 'VP'">Vitagrazia Pisani</xsl:when>
                            <xsl:when test="$r = 'IF'">Iosif Fridman</xsl:when>
                            <xsl:when test="$r = 'SH'">Susanne Hummel</xsl:when>
                            <xsl:when test="$r = 'FP'">Francesca Panini</xsl:when>
                            <xsl:when test="$r = 'AA'">Abreham Adugna</xsl:when>
                            <xsl:when test="$r = 'EG'">Ekaterina Gusarova</xsl:when>
                            <xsl:when test="$r = 'IR'">Irene Roticiani</xsl:when>
                            <xsl:when test="$r = 'MB'">Maria Bulakh</xsl:when>
                            <xsl:when test="$r = 'VR'">Veronika Roth</xsl:when>
                            <xsl:when test="$r = 'MK'">Magdalena Krzyzanowska</xsl:when>
                            <xsl:when test="$r = 'DE'">Daria Elagina</xsl:when>
                            <xsl:when test="$r = 'NV'">Nafisa Valieva</xsl:when>
                            <xsl:when test="$r = 'RHC'">Ran HaCohen</xsl:when>
                            <xsl:when test="$r = 'SS'">Sisay Sahile</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$r"/>
                            </xsl:otherwise>
                        </xsl:choose>
                            
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                
                <h2>
                    <xsl:if test="@subtype">
                        <a href="{if (@corresp) then @corresp else '#mscontent'}">
                            <xsl:value-of select="@subtype"/>
                            <xsl:choose>
                                <xsl:when test="@n">
                                    <xsl:text>: </xsl:text>
                                    <xsl:value-of select="@n"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>: </xsl:text>
                                    <xsl:if test="parent::t:div[@type='textpart']">
                                        <xsl:value-of select="count(parent::t:div[@type='textpart']/preceding-sibling::t:div[@type='textpart']) + 1"/>
                                        <xsl:text>.</xsl:text>
                                    </xsl:if>
                                    <xsl:value-of select="count(preceding-sibling::t:div[@type='textpart']) + 1"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </a>
                    </xsl:if>
                    <xsl:if test="@corresp">
                        <xsl:text> (</xsl:text>
                        <xsl:variable name="id" select="substring-after(@corresp, '#')"/>
                        <xsl:variable name="match" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
<!--            TEST            <xsl:copy-of select="$match"/>-->
                        <xsl:choose>
                            <xsl:when test="starts-with(@corresp, '#')">
                                <xsl:text> </xsl:text>
                                <xsl:if test="$match/t:title">
                                    <xsl:apply-templates select="$match/t:title"/>
                                </xsl:if>
                                <a>
                                    <xsl:choose>
                                        <xsl:when test="$match/name() = 'msItem'">
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="concat('../../manuscripts/', ancestor::t:TEI/@xml:id, @corresp)"/>
                                            </xsl:attribute>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:attribute name="href">
                                                <xsl:value-of select="@corresp"/>
                                            </xsl:attribute>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="substring-after(@corresp, '#')"/>
                                </a>
                            </xsl:when>
                            <xsl:otherwise>
                                <span class="MainTitle" data-value="{@corresp}"/>
                                <a href="{@corresp}">
                                    <xsl:text>  </xsl:text>
                                    <span class="glyphicon glyphicon-share"/>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:if test="@corresp">
                        <div class="parallelversions w3-bar w3-tooltip">
                            <a class="parallelversion w3-small w3-button w3-red" data-textid="{$text}" data-unit="{@corresp}">
                                Versions
                            </a>
                            <span class="w3-tag w3-text">See parallel versions if any is available</span>
                        </div>
                    </xsl:if><!--
                    <div class="ugaritcontrols btn-group">
                        <a class="ugarit btn btn-success btn-xs" data-textid="{$text}" data-currentid="{@n}" data-toggle="tooltip" title="Start a translation alignment with Ugarit" disabled="disabled">
                            Ugarit Alignment
                        </a>
                    </div>
                        <div class="quotations btn-group">
                            <a id="quotations{@n}" class="quotations btn btn-success btn-xs" data-textid="{$text}" data-unit="{@n}" data-toggle="tooltip" title="Check for marked up quotations of a passage in this section">
                                Quotations
                            </a>
                        </div>
                    
                    <div id="AllQuotations{@n}"/>-->
                </h2>
                <xsl:apply-templates select="child::t:label"/>
                <xsl:apply-templates select="child::t:div[@type='textpart']"/>
            </xsl:when>
            <xsl:otherwise>
                <div class="{if(./parent::t:div[@type='textpart']) then 'subtextpart' else ()} w3-row" id="{if(@xml:id) then (@xml:id) else if(@n) then(@n) else(concat('textpart', string(position())))}" lang="{ancestor::t:div[@xml:lang][1]/@xml:lang}">
                    <div class="w3-col" style="width:15%">
                        
                            <xsl:if test="@subtype">
                                <a href="{if (@corresp) then @corresp else '#mscontent'}">
                                    <xsl:value-of select="@subtype"/>
                                    <xsl:choose>
                                        <xsl:when test="@n">
                                            <xsl:text>: </xsl:text>
                                            <xsl:value-of select="@n"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>: </xsl:text>
                                            <xsl:if test="parent::t:div[@type='textpart']">
                                                <xsl:value-of select="count(parent::t:div[@type='textpart']/preceding-sibling::t:div[@type='textpart']) + 1"/>
                                                <xsl:text>.</xsl:text>
                                            </xsl:if>
                                            <xsl:value-of select="count(preceding-sibling::t:div[@type='textpart']) + 1"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </a>
                            </xsl:if>
                          <!--  <xsl:if test="@corresp">
                                <xsl:text> (</xsl:text>
                                <xsl:variable name="id" select="substring-after(@corresp, '#')"/>
                                <xsl:variable name="match" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
                                <xsl:choose>
                                    <xsl:when test="starts-with(@corresp, '#')">
                                        <xsl:text> </xsl:text>
                                        <xsl:if test="$match//t:title">
                                            <xsl:apply-templates select="$match//t:title"/>
                                        </xsl:if>
                                        <a>
                                            <xsl:choose>
                                                <xsl:when test="$match/name() = 'msItem'">
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="concat('../../manuscripts/', ancestor::t:TEI/@xml:id, @corresp)"/>
                                                    </xsl:attribute>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="href">
                                                        <xsl:value-of select="@corresp"/>
                                                    </xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                            <xsl:value-of select="substring-after(@corresp, '#')"/>
                                        </a>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <span class="MainTitle" data-value="{@corresp}"/>
                                        <a href="{@corresp}">
                                            <xsl:text>  </xsl:text>
                                            <span class="glyphicon glyphicon-share"/>
                                        </a>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                          -->  
                        <div class="w3-bar-block">
                            <div class="ugaritcontrols w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray">
                            <a class="ugarit  w3-small" data-textid="{$text}" data-currentid="{@n}" disabled="disabled">
                                    Alignment
                                </a>
                            <span class="w3-text w3-tag">Start a translation alignment with Ugarit</span>
                            </div>
                            <xsl:if test="@corresp">
                                <div class="parallelversions w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray">
                                    <a class="parallelversion  w3-small" data-textid="{$text}" data-unit="{@corresp}">
                                        Versions
                                    </a>
                                    <span class="w3-text w3-tag">See parallel versions if any is available</span>
                                </div>
                            </xsl:if>
                        
                            <div class="quotations w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray">
                            <a id="quotations{@n}" class="quotations  w3-small" data-textid="{$text}" data-unit="{@n}">
                                Quotations
                            </a>
                            <span class="w3-text w3-tag">Check for marked up quotations of a passage in this section</span>
                        </div>
                        
                         
                            <a href="#" class="w3-button w3-padding-small w3-white w3-bar-item" onclick="document.getElementById('textHelp').style.display='block'">
                            <i class="fa fa-info-circle" aria-hidden="true"/>
                        </a>
                        </div>
                        
                        <div id="AllQuotations{@n}"/> 
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
                                        <p>In the text:</p>
                                        <ul class="nodot">
                                            <li>Click on ↗ to see the related items in Pelagios.</li>
                                            <li>Click on <i class="fa fa-hand-o-left"/>
                                                to see the which entities within Beta maṣāḥǝft point to this identifier.</li>
                                            <li>
                                            <sup>[!]</sup> contains additional information related to uncertainties in the encoding.</li>
                                            <li>Superscript digits refer to notes in the apparatus which are displayed on the right.</li>
                                        </ul>
                                    </div>
                            </div>
                        </div>
                        
                    </div>
                    <div class="w3-col" style="width:85%">
                     <div class="w3-twothird w3-container chapterText" id="{@xml:id}">
                         <xsl:apply-templates select="child::node()"/>
                    </div>  
                    <div class="w3-third row apparata ">
                        <xsl:for-each select="t:ab//t:app[not(@type)]">
                            <xsl:sort select="position()"/>
                            <span id="{ancestor::t:div[@type='textpart'][1]/@n}appPointer{position()}"> 
                                <a href="#{ancestor::t:div[@type='textpart'][1]/@n}appnote{position()}">
                                    <xsl:value-of select="count(preceding-sibling::t:app) + 1"/>
                                </a>
                                <xsl:text>) </xsl:text>
                                <xsl:if test="count(./t:lem/node()) ge 1">
                                        <xsl:apply-templates select="./t:lem"/> <xsl:text>: </xsl:text>
                                    </xsl:if>
                                <xsl:if test="count(./t:rdg/node()) ge 1">
                                        <xsl:apply-templates select="./t:rdg"/> <xsl:text>. </xsl:text>
                                    </xsl:if>
                                <xsl:apply-templates select="./t:note/node()"/>
                            </span>
                            <xsl:if test="not(position() = last())">
                                <xsl:text> | </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                        <hr/>
                        <xsl:for-each-group select="t:ab//t:app[@type]" group-by="@type">
                            
                            <span class="badge">
                                <xsl:value-of select="current-grouping-key()"/> </span>
                            <xsl:text>  </xsl:text>
                            <xsl:for-each select="current-group()">
                                <xsl:sort select="position()"/>
                                <span id="{ancestor::t:div[@type='textpart'][1]/@n}appPointer{position()}"> 
                                    <a href="#{ancestor::t:div[@type='textpart'][1]/@n}appnote{position()}">
                                        <xsl:value-of select="count(preceding-sibling::t:app) + 1"/>
                                    </a>
                                    <xsl:text>) </xsl:text>
                                    <xsl:if test="count(./t:lem/node()) ge 1">
                                            <xsl:apply-templates select="./t:lem"/> <xsl:text>: </xsl:text>
                                        </xsl:if>
                                    <xsl:if test="count(./t:rdg/node()) ge 1">
                                            <xsl:apply-templates select="./t:rdg"/> <xsl:text>. </xsl:text>
                                        </xsl:if>
                                    <xsl:apply-templates select="./t:note/node()"/>
                                </span>
                                <xsl:if test="not(position() = last())">
                                    <xsl:text> | </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <hr/>
                        </xsl:for-each-group>
                        
                        
                        
                        
                    </div>
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
       <!-- <div class="{if(./parent::t:div[@type='textpart']) then 'subtextpart' else ()}" id="{if(@xml:id) then (@xml:id) else if(@n) then(@n) else(('textpart', string(position())))}">
           <h2>
                <xsl:if test="@subtype">
                <a href="{if (@corresp) then @corresp else '#mscontent'}">
                    <xsl:value-of select="@subtype"/>
                    <xsl:choose>
                        <xsl:when test="@n">
                            <xsl:text>: </xsl:text>
                            <xsl:value-of select="@n"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>: </xsl:text>
                            <xsl:if test="parent::t:div[@type='textpart']">
                                <xsl:value-of select="count(parent::t:div[@type='textpart']/preceding-sibling::t:div[@type='textpart']) + 1"/>
                                <xsl:text>.</xsl:text>
                            </xsl:if>
                            <xsl:value-of select="count(preceding-sibling::t:div[@type='textpart']) + 1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a>
            </xsl:if>
            <xsl:if test="@corresp">
                <xsl:text> (</xsl:text>
                <xsl:variable name="id" select="substring-after(@corresp, '#')"/>
                <xsl:variable name="match" select="current()//ancestor::t:TEI//t:*[@xml:id = $id]"/>
                <xsl:choose>
                    <xsl:when test="starts-with(@corresp, '#')">
                        <xsl:text> </xsl:text>
                        <xsl:if test="$match//t:title">
                            <xsl:apply-templates select="$match//t:title"/>
                        </xsl:if>
                        <a>
                            <xsl:choose>
                                <xsl:when test="$match/name() = 'msItem'">
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="concat('../../manuscripts/', ancestor::t:TEI/@xml:id, @corresp)"/>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:attribute name="href">
                                        <xsl:value-of select="@corresp"/>
                                    </xsl:attribute>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="substring-after(@corresp, '#')"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="MainTitle" data-value="{@corresp}"/>
                        <a href="{@corresp}">
                            <xsl:text>  </xsl:text>
                            <span class="glyphicon glyphicon-share"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:text>)</xsl:text>
            </xsl:if>
           <div class="ugaritcontrols btn-group">
                    <a class="ugarit btn btn-success btn-xs" data-textid="{$text}" data-currentid="{@n}" data-toggle="tooltip" title="Start a translation alignment with Ugarit" disabled="disabled">
                        Ugarit Alignment
                    </a>
                </div>
               <xsl:if test="@corresp">
                    <div class="parallelversions btn-group">
                   <a class="parallelversion btn btn-success btn-xs" data-textid="{$text}" data-unit="{@corresp}" data-toggle="tooltip" title="See parallel versions if any is available">
                       Versions
                   </a>
               </div>
                </xsl:if>
       </h2>
            
            <br/>
            <div class="col-md-12" id="chapterText">
                <div class="row">
                    <xsl:apply-templates/>
                </div>
                <div class="row apparata">
                    <hr/>
                    <xsl:for-each select="t:ab//t:app[not(@type)]">
                        <xsl:sort select="position()"/>
                      <span id="{ancestor::t:div[@type='textpart'][1]/@n}appPointer{position()}"> 
                            <a href="#{ancestor::t:div[@type='textpart'][1]/@n}appnote{position()}">
                            <xsl:value-of select="count(preceding-sibling::t:app) + 1"/>
                        </a>
                            <xsl:text>) </xsl:text>
                            <xsl:apply-templates select="./t:lem"/> <xsl:text>: </xsl:text>
                            <xsl:apply-templates select="./t:rdg"/>
                        </span>
                        <xsl:if test="not(position() = last())">
                            <xsl:text> | </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                     <hr/>
                        <xsl:for-each-group select="t:ab//t:app[@type]" group-by="@type">
                        
                            <span class="badge">
                            <xsl:value-of select="current-grouping-key()"/> </span>
                        <xsl:text>  </xsl:text>
                            <xsl:for-each select="current-group()">
                            <xsl:sort select="position()"/>
                                <span id="{ancestor::t:div[@type='textpart'][1]/@n}appPointer{position()}"> 
                            <a href="#{ancestor::t:div[@type='textpart'][1]/@n}appnote{position()}">
                            <xsl:value-of select="count(preceding-sibling::t:app) + 1"/>
                        </a>
                            <xsl:text>) </xsl:text>
                            <xsl:apply-templates select="./t:lem"/> <xsl:text>: </xsl:text>
                            <xsl:apply-templates select="./t:rdg"/>
                        </span>
                        <xsl:if test="not(position() = last())">
                            <xsl:text> | </xsl:text>
                        </xsl:if>
                        </xsl:for-each>
                            <hr/>
                    </xsl:for-each-group>
                        
                  
                        
                    
                </div>
            </div>
        </div>
 -->   </xsl:template>
    
    <xsl:template match="t:label">
        <xsl:choose>
            <xsl:when test="parent::t:div[@subtype='Psalmus']"/>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    <xsl:template match="t:ab">
        <div class="w3-container">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="t:ab[ancestor::t:div[@subtype='Psalmus']]">
        <div class="w3-container">
            <h3>
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="t:title/t:ref/@target"/>
                    </xsl:attribute>
                    <xsl:value-of select="t:title"/>
                </a>
            </h3>
            <xsl:apply-templates select="t:l"/>
        </div>
    </xsl:template>
    
    <xsl:template match="t:l">
        <sup>
            
            <xsl:choose>
                <xsl:when test="t:ref[1][@target]">
                    <a target="_blank">
                        <xsl:attribute name="href">
                            <xsl:value-of select="t:ref[1]/@target"/>
                        </xsl:attribute>
                        <xsl:value-of select="@n"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@n"/>
                </xsl:otherwise>
            </xsl:choose>
            
        </sup>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="t:l[ancestor::t:div[@subtype='Psalmus']]">
        <div class="w3-container">
            
        <p>
                <sup>
            <xsl:value-of select="@n"/>
        </sup>
                <xsl:apply-templates/>
            </p>
        </div>
    </xsl:template>


    <!--lb-->
    <xsl:template match="t:lb[parent::t:ab]">
        <xsl:text> | </xsl:text>
       
    </xsl:template>
    <xsl:template match="t:lb[parent::t:l][not(parent::t:ab)]">
        <xsl:if test="preceding-sibling::text()">
            <br/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:lb[not(parent::t:ab)][not(parent::t:l)]">
        <xsl:variable name="line">
            <xsl:if test="@n">
                <xsl:value-of select="@n"/>
            </xsl:if>
        </xsl:variable>
        <br/>
        <!--hard coded carriage return would not be recognized-->
        <xsl:choose>
            <xsl:when test="number(@n) and @n mod number(5) = 0 and not(@n = 0)">
                <xsl:call-template name="margin-num"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="line-numbering-tab"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="margin-num">
        <xsl:value-of select="@n"/>
        <!-- template »line-numbering-tab« found in txt-tpl-linenumberingtab.xsl respectively odf-tpl-linenumberingtab.xsl -->
        <xsl:call-template name="line-numbering-tab"/>
    </xsl:template>

    <!-- $Id: txt-tpl-linenumberingtab.xsl 1543 2011-08-31 15:47:37Z ryanfb $ -->
    <xsl:template name="line-numbering-tab">
        <!--<xsl:text>		</xsl:text>-->
        <span style="padding-left: 5em;"/>
        <!--double tab would look much better but would not be recognized in browser-->
    </xsl:template>
    
    <xsl:template match="t:pb">
        <xsl:choose>
            <xsl:when test="ancestor::t:div[@type='edition']">|<sup>
                    <xsl:value-of select="@n"/>
                </sup>
                <xsl:choose>
                    <xsl:when test="starts-with(@facs, 'http') and ancestor::t:TEI[@type='work']">
                <xsl:variable name="corresp" select="substring-after(@corresp, '#')"/>
                <xsl:variable name="manifest" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/t:ptr/@target"/>
                <xsl:variable name="location" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/@facs"/>
                <span class="imageLink" data-manifest="{$manifest}" data-location="{$location}" data-canvas="{@facs}"/>
            </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="corresp" select="substring-after(@corresp, '#')"/>
                    <xsl:variable name="manifest" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/t:ptr/@target"/>
                    <xsl:variable name="location" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/@facs"/>
                    <span class="imageLink" data-manifest="{$manifest}" data-location="{$location}" data-canvas="{@facs}"/>
                </xsl:otherwise>
            </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <hr id="part{@n}"/>
                <p>
                    <xsl:value-of select="@n"/>
                    
                    <xsl:choose>
                        <xsl:when test="starts-with(@facs, 'http') and ancestor::t:TEI[@type='work']">
                        <xsl:variable name="corresp" select="substring-after(@corresp, '#')"/>
                        <xsl:variable name="manifest" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/t:ptr/@target"/>
                        <xsl:variable name="location" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/@facs"/>
                        <span class="imageLink" data-manifest="{$manifest}" data-location="{$location}" data-canvas="{@facs}"/>
                    </xsl:when>
                        <xsl:otherwise>
                            <xsl:variable name="corresp" select="substring-after(@corresp, '#')"/>
                            <xsl:variable name="manifest" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/t:ptr/@target"/>
                            <xsl:variable name="location" select="ancestor::t:TEI//t:witness[@xml:id = $corresp]/@facs"/>
                            <span class="imageLink" data-manifest="{$manifest}" data-location="{$location}" data-canvas="{@facs}"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
                
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="t:cb">
        <xsl:text>|</xsl:text>
        <sup id="{preceding-sibling::t:pb[1]/@n}{@n}">
            <xsl:value-of select="@n"/>
        </sup>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:handShift">
        <sub>
            <a href="{@new}">
                <xsl:value-of select="substring-after(@new, '#')"/>
            </a>
        </sub>
    </xsl:template>
    
    <xsl:template match="t:surplus">
        {<xsl:apply-templates/>}
    </xsl:template>
    <xsl:template match="t:subst">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:unclear">
        <xsl:value-of select="."/>
        <xsl:text>?</xsl:text>
    </xsl:template>
    <xsl:template match="t:orig">
        <span class="undeciphrable">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <!--    <del></del> is rendered in the html as a overstrike letter-->
    <xsl:template match="t:add">
        <xsl:variable name="id" select="generate-id()"/>
        <xsl:choose>
            <!--            has hand and place-->
            <xsl:when test="@hand and @place">
                <a href="#{$id}" data-toggle="popover" title="Added Text Position" data-content="Note added {                     if(@hand)                      then concat('by ',substring-after(@hand, '#')) else ''}                      at {upper-case(@place)} according to TEI definitions">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <!--            has place overstrike-->
            <xsl:when test="@place = 'overstrike' and preceding-sibling::t:del">
                <xsl:text>{</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>}</xsl:text>
            </xsl:when>

            <!--            has only hand-->
            <xsl:when test="@hand and not(@place)">
                <xsl:text>/</xsl:text>
                <a href="#{$id}" data-toggle="popover" title="Correction author" data-content="Note added { concat('by ',substring-after(@hand, '#')) }">
                    <xsl:apply-templates/>
                </a>
                <xsl:text>/</xsl:text>
            </xsl:when>
            <!--       do nothing with margin notes in text edition-->
            <xsl:when test="@place = 'margin' and ancestor::t:TEI[@type='work']"/>
            <!-- it has only place-->
            <xsl:otherwise>
                <a href="#{$id}" data-toggle="popover" title="Added Text Position" data-content="Note added                      at {upper-case(@place)} according to TEI definitions">
                    <xsl:apply-templates/>
                </a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:gap">
        <xsl:variable name="quantity" select="@quantity"/>
        <a>
            <xsl:if test="@resp">
                <xsl:attribute name="data-value">
                    <xsl:value-of select="@resp"/>
                </xsl:attribute>
                <xsl:attribute name="class">w3-tooltip OmissionResp</xsl:attribute>
            </xsl:if>
        <xsl:choose>
                <xsl:when test="@reason = 'illegible'">
                    <xsl:for-each select="1 to $quantity">
            <xsl:text>+</xsl:text>
        </xsl:for-each>
                </xsl:when>
            <xsl:when test="@reason = 'omitted'">. . . . .</xsl:when>
            <xsl:when test="@reason = 'lost'">[ - ca. <xsl:value-of select="$quantity"/> <xsl:value-of select="@unit"/> - ]</xsl:when>
            <xsl:when test="@reason = 'ellipsis'">(…)</xsl:when>
        </xsl:choose>
        </a>
    </xsl:template>
    
    <xsl:template match="t:space">
        <xsl:variable name="quantity" select="@quantity"/>
        <a>
            <xsl:if test="@resp">
                <xsl:attribute name="data-value">
                    <xsl:value-of select="@resp"/>
                </xsl:attribute>
                <xsl:attribute name="class">w3-tooltip OmissionResp</xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@reason = 'rubrication'">(<xsl:value-of select="@quantity"/> <xsl:value-of select="@unit"/> left for rubrication and never filled)</xsl:when>
            </xsl:choose>
        </a>
    </xsl:template>
    
    <xsl:template match="t:choice[t:sic and t:corr]">
        <xsl:variable name="id" select="generate-id()"/>
        <b>
            <a data-value="{t:corr/@resp}" class="w3-tooltip ChoiceResp" id="{$id}">
            <xsl:value-of select="t:corr"/>
        </a>
        </b>
            
<!--        the following script makes it possible to click on the text to see the alternative the sic has a (!) appended-->
        <script type="text/javascript">
            <xsl:text>$('#</xsl:text>
            <xsl:value-of select="$id"/>
            <xsl:text>').bind('click', function() {
            $(this).html($(this).html() == '</xsl:text>
            <xsl:value-of select="t:corr"/>
            <xsl:text>' ? '</xsl:text>
            <xsl:value-of select="concat(t:sic, ' (!)')"/>
            <xsl:text>' : '</xsl:text>
            <xsl:value-of select="t:corr"/>
            <xsl:text>');
            });</xsl:text>
        </script>
    </xsl:template>
    
    <xsl:template match="t:sic">
        <span class="w3-tooltip">
        <a class="CorrResp" data-value="{@resp}">
            <xsl:value-of select="."/>
            <xsl:text> (!)</xsl:text>
        </a>
            <span class="w3-text w3-tag">
                <xsl:value-of select="@resp"/>
            </span>
        </span>
    </xsl:template>
    
    <xsl:template match="t:del">
        <xsl:choose>
            <xsl:when test="@resp">
                <a class="w3-tooltip CorrResp" data-value="{@resp}">
            <xsl:choose>
                <xsl:when test="@rend = 'erasure'">
                    <xsl:text>〚</xsl:text>
                    <xsl:choose>
                        <xsl:when test="not(text())">
                                    <xsl:value-of select="concat(@extent, ' ', @unit)"/>
                                </xsl:when>
                        <xsl:otherwise>
                                    <xsl:apply-templates/>
                                </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:text>〛</xsl:text>
                </xsl:when>
                <xsl:when test="@rend = 'strikethrough'">
                    <strike>
                        <xsl:choose>
                            <xsl:when test="not(text())">
                                        <xsl:value-of select="concat(@extent, ' ', @unit)"/>
                                    </xsl:when>
                            <xsl:otherwise>
                                        <xsl:apply-templates/>
                                    </xsl:otherwise>
                        </xsl:choose>
                    </strike>
                </xsl:when>
            </xsl:choose>
        
        </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                <xsl:when test="@rend = 'erasure'">
                    <xsl:text>〚</xsl:text>
                    <xsl:choose>
                        <xsl:when test="not(text())">
                                <xsl:value-of select="concat(@extent, ' ', @unit)"/>
                            </xsl:when>
                        <xsl:otherwise>
                                <xsl:apply-templates/>
                            </xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:text>〛</xsl:text>
                </xsl:when>
               
                <xsl:when test="@rend = 'strikethrough'">
                    <strike>
                        <xsl:choose>
                            <xsl:when test="not(text())">
                                    <xsl:value-of select="concat(@extent, ' ', @unit)"/>
                                </xsl:when>
                            <xsl:otherwise>
                                    <xsl:apply-templates/>
                                </xsl:otherwise>
                        </xsl:choose>
                    </strike>
                </xsl:when>
            </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="t:supplied">
        <xsl:choose>
            <xsl:when test="@reason = 'undefined'">
            <xsl:text>[</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>(?)]</xsl:text><!--ok?-->
        </xsl:when>
            <xsl:when test="@reason = 'lost'">
                <xsl:text>[</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>]</xsl:text>
            </xsl:when>
            <xsl:when test="@reason = 'omitted'">
                <xsl:text>&lt;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&gt;</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="t:div[@type = 'apparatus']">
        <div class="row-fluid" id="apparatus">
            <hr/>
            <xsl:for-each select="t:app">
                <xsl:sort select="position()"/>
                <a href="{@from}">
                    <xsl:value-of select="concat(substring-after(@from, '#'), ', ', @loc, ' ')"/>
                </a>
                <xsl:apply-templates/>
                <xsl:if test="not(position() = last())">
                    <xsl:text> | </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </div>
    </xsl:template>
    <xsl:template match="t:lem">
        <xsl:variable name="resp" select="@resp"/>
        <xsl:variable name="listWit" select="ancestor::t:TEI//t:listWit"/>
        <xsl:apply-templates select="child::node() except t:app"/>
        <xsl:text> </xsl:text>
       
        <xsl:choose>
            <xsl:when test="contains(@wit, ' ')">
            <xsl:for-each select="tokenize(@wit, ' ')">
            <xsl:variable select="substring-after(.,'#')" name="trimmedid"/>
                <xsl:variable select="$listWit//t:witness[@xml:id=$trimmedid]/@corresp" name="witness"/>
                    <a data-toggle="tooltip" data-html="true" title="">
                
            <xsl:value-of select="substring-after(.,'#')"/>
        </a>
        </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <a data-resp="{$resp}" data-wit="@wit" class="w3-tooltip RdgRespMs">
                    <xsl:value-of select="substring-after(@wit,'#')"/>
                </a>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="t:lem" mode="text">
           <xsl:apply-templates/>
       </xsl:template>
    
    <xsl:template match="t:rdg">
        <xsl:variable name="resp" select="@resp"/>
        
        <b lang="{@xml:lang}">
            <xsl:choose>
                <xsl:when test="contains(@wit, ' ')">
                <xsl:for-each select="tokenize(@wit, ' ')">
                    <a data-resp="{$resp}" data-wit="{.}" class="w3-tooltip RdgResp">
                        <xsl:value-of select="substring-after(.,'#')"/>
                    </a>
                </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <a data-resp="{$resp}" data-wit="@wit" class="w3-tooltip RdgResp">
                        <xsl:value-of select="substring-after(@wit,'#')"/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>
        </b>
        <xsl:text> </xsl:text>
        <xsl:if test="@xml:lang">
            <xsl:text> Cfr. </xsl:text>
            <xsl:value-of select="@xml:lang"/>
        </xsl:if>
        <xsl:if test="not(position() = last())">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>