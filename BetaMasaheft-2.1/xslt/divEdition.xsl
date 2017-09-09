<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    
    <xsl:template match="t:*[@xml:lang='gez']//text()">
        
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
        <div class="row-fluid" id="{@type}">
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
    
    
    <xsl:template match="t:div[@type = 'textpart']">
        <xsl:variable name="text">
            <xsl:value-of select="./ancestor::t:TEI/@xml:id"/>
        </xsl:variable>
        <div class="{if(parent::t:div[@type='textpart']) then 'subtextpart' else ()}" id="{if(@xml:id) then (@xml:id) else if(@n) then(@n) else(('textpart', string(position())))}">
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
                    <a class="ugarit btn btn-success" data-textid="{$text}" data-currentid="{@n}" data-toggle="tooltip" title="Start a translation alignment with Ugarit">
                        <i class="fa fa-exchange" aria-hidden="true"/>
                    </a>
                </div>
       </h2>
            
            <br/>
            <div class="col-md-12">
                <div class="row">
                    <xsl:apply-templates/>
                </div>
                <div class="row apparata">
                    <hr/>
                    <xsl:for-each select=".//t:app[not(@type)]">
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
                        <xsl:for-each-group select=".//t:app[@type]" group-by="@type">
                        
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
    </xsl:template>
    
    <xsl:template match="t:label">
        <xsl:choose>
            <xsl:when test="parent::t:div[@subtype='Psalmus']"/>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    <xsl:template match="t:ab">
        <div class="container-fluid">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="t:ab[ancestor::t:div[@subtype='Psalmus']]">
        <div class="container-fluid">
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
        <div class="col-md-12">
            
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
        <hr id="{@n}"/>
        <p>
            <xsl:value-of select="@n"/>
        </p>
        <xsl:apply-templates/>
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
        <a data-toggle="tooltip">
            <xsl:if test="@resp">
                <xsl:attribute name="data-value">
                    <xsl:value-of select="@resp"/>
                </xsl:attribute>
                <xsl:attribute name="class">OmissionResp</xsl:attribute>
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
        <a data-toggle="tooltip">
            <xsl:if test="@resp">
                <xsl:attribute name="data-value">
                    <xsl:value-of select="@resp"/>
                </xsl:attribute>
                <xsl:attribute name="class">OmissionResp</xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@reason = 'rubrication'">(<xsl:value-of select="@quantity"/> <xsl:value-of select="@unit"/> left for rubrication and never filled)</xsl:when>
            </xsl:choose>
        </a>
    </xsl:template>
    
    <xsl:template match="t:choice[t:sic and t:corr]">
        <xsl:variable name="id" select="generate-id()"/>
        <b>
            <a data-toggle="tooltip" data-value="{t:corr/@resp}" class="ChoiceResp" id="{$id}">
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
        <a data-toggle="tooltip" class="CorrResp" data-value="{@resp}">
            <xsl:value-of select="."/>
            <xsl:text> (!)</xsl:text>
        </a>
    </xsl:template>
    
    <xsl:template match="t:del">
        <xsl:choose>
            <xsl:when test="@resp">
                <a data-toggle="tooltip" class="CorrResp" data-value="{@resp}">
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
                <a data-toggle="tooltip" data-resp="{$resp}" data-wit="@wit" class="RdgRespMs">
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
        
        <b>
            <xsl:choose>
                <xsl:when test="contains(@wit, ' ')">
                <xsl:for-each select="tokenize(@wit, ' ')">
                    <a data-toggle="tooltip" data-resp="{$resp}" data-wit="{.}" class="RdgResp">
                        <xsl:value-of select="substring-after(.,'#')"/>
                    </a>
                </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <a data-toggle="tooltip" data-resp="{$resp}" data-wit="@wit" class="RdgResp">
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