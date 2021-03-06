<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dts="https://w3id.org/dts/api#" xmlns:funct="my.funct" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs t" version="2.0">
    
    <xsl:function name="funct:ID">
<!--        calculates on the basis of the available attributes the id to match the ref of DTS
        produces in dts:rn() of the dts.xqm module, reproduced below.
        in this way the pointers loaded from the API and printed by dtsAnno.js , as well as the references
        in the dtsclient.xqm can either scroll to that position or allow a view with that part only.-->
        <xsl:param name="node"/>
        <xsl:choose>
            <xsl:when test="$node//t:cb">
                <xsl:value-of select="string($node/preceding::t:pb[@n][1]/@n)||string($node/@n)"/>
            </xsl:when>
            <xsl:when test="$node/@corresp">
                <xsl:value-of select="$node/@corresp"/>
            </xsl:when>
            <xsl:when test="$node/@n">
                <xsl:value-of select="$node/@n"/>
            </xsl:when>
            <xsl:when test="$node/@xml:id">
                <xsl:value-of select="$node/@xml:id"/>
            </xsl:when>
            <xsl:when test="$node/@subtype">
                <xsl:value-of select="$node/@subtype"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('tei:', $node/name(),'[', $node/position() , ']')"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <!--if ($n/name()='cb') then 
        (string($n/preceding::t:pb[@n][1]/@n)||string($n/@n)) 
        else if ($n/name()='pb' and $n/@corresp) then 
        (string($n/@n) || '[' ||substring-after($n/@corresp, '#')||']') 
        else if($n/@n) then string($n/@n)
        else if($n/@xml:id) then string($n/@xml:id)
        else if($n/@subtype) then string($n/@subtype)
        else 'tei:' ||$n/name() ||'['|| $n/position() || ']'-->
    </xsl:function>
    
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
            <xsl:if test="@xml:id='Transkribus'"><xsl:attribute name="style">color:gray;</xsl:attribute></xsl:if>
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
    
    <xsl:template name="title">
        <xsl:param name="div"/>
        <xsl:param name="text"/>
        
            <div class="w3-bar">
                <div class="w3-bar-item">
                    <i>
                        <xsl:apply-templates select="child::t:label"/>
                        <xsl:text> </xsl:text>
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
                            <xsl:text> </xsl:text>
                        </xsl:if>
                        <xsl:if test="@subtype">
                                <xsl:value-of select="@subtype"/>
                                <xsl:if test="@n">
                                    <xsl:text>: </xsl:text>
                                    <xsl:value-of select="@n"/>
                                </xsl:if>
                            <xsl:text> </xsl:text>
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
                                    
                                    <a href="/{@corresp}">
                                        <span class="MainTitle" data-value="{@corresp}"/>
                                        <xsl:text>  </xsl:text>
                                        <span class="glyphicon glyphicon-share"/>
                                    </a>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:text>) </xsl:text>
                        </xsl:if>
                        <xsl:if test="@corresp and ancestor::t:TEI/@type='work'">
                            <span class="parallelversions  w3-tooltip">
                                <a class="parallelversion w3-red" data-textid="{$text}" data-unit="{@corresp}">
                                    Versions
                                </a>
                                <span class="w3-tag w3-text">See parallel versions if any is available</span>
                            </span>
                        </xsl:if>
                    </i>
                </div>
                <xsl:if test="t:ab[descendant::text()]">
                   
                        <div class="ugaritcontrols w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                            <a class="ugarit  w3-small" data-textid="{$text}" data-currentid="{@n}" disabled="disabled">
                                Alignment
                            </a>
                            <span class="w3-text w3-tag">Start a translation alignment with Ugarit</span>
                        </div>
                        <xsl:if test="@corresp">
                            <div class="parallelversions w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                                <a class="parallelversion  w3-small" data-textid="{$text}" data-unit="{@corresp}">
                                    Versions
                                </a>
                                <span class="w3-text w3-tag">See parallel versions if any is available</span>
                            </div>
                        </xsl:if>
                        
                    <div class="quotations w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                            <a id="quotations{@n}" class="quotations  w3-small" data-textid="{$text}" data-unit="{@n}">
                                Quotations
                            </a>
                            <span class="w3-text w3-tag">Check for marked up quotations of a passage in this section</span>
                        </div>
                        
                        
                    <a href="#" class="w3-button w3-padding-small w3-gray w3-right w3-bar-item" onclick="document.getElementById('textHelp').style.display='block'">
                            <i class="fa fa-info-circle" aria-hidden="true"/>
                        </a>
                    
                </xsl:if>
                <a href="#transcription" class="page-scroll w3-button w3-padding-small w3-right w3-bar-item w3-gray">back to top</a>
            </div>
    </xsl:template>
    
    <xsl:template match="t:div[@type = 'textpart'] | t:div[@type='edition'][not(child::t:div)]">
        <div id="{funct:ID(.)}">
        <xsl:if test="not(descendant::t:pb) and not(parent::t:div[@type='textpart'])">
            <xsl:apply-templates select="preceding::t:pb[1]"/>
        </xsl:if>
        <xsl:variable name="text">
            <xsl:value-of select="./ancestor::t:TEI/@xml:id"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="child::t:div[@type = 'textpart']">
                <xsl:call-template name="title">
                    <xsl:with-param name="div" select="."/>
                    <xsl:with-param name="text" select="$text"/>
                </xsl:call-template>
                <xsl:apply-templates select="child::node()[name() !='div' and name()!='label']"/>
                <xsl:apply-templates select="child::t:div[@type='textpart']"/>
            </xsl:when>
            <xsl:otherwise>
                <div class="{if(./parent::t:div[@type='textpart']) then 'subtextpart' else ()} w3-row" id="{funct:ID(.)}" lang="{ancestor-or-self::t:div[@xml:lang][1]/@xml:lang}">
                    <xsl:call-template name="title">
                            <xsl:with-param name="div" select="."/>
                            <xsl:with-param name="text" select="$text"/>
                        </xsl:call-template>
                    
                    <div>
                     <div id="{@xml:id}">
                         <xsl:choose>
                             <xsl:when test="t:ab//t:app">
                                 <xsl:attribute name="class">w3-twothird w3-padding chapterText</xsl:attribute>
                             </xsl:when>
                             <xsl:otherwise>
                                        <xsl:attribute name="class">w3-container w3-padding chapterText</xsl:attribute>
                                    </xsl:otherwise>
                         </xsl:choose>
                         <xsl:apply-templates select="child::node()[name()!='label']"/>
                    </div>  
                     <xsl:if test="t:ab//t:app"> 
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
                   </xsl:if> 
                        <div id="AllQuotations{@n}"/> 
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
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
        <div class="w3-container">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="t:lg">
        <div class="w3-container" style="white-space: pre-line;">
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
        <xsl:apply-templates select="node() except t:ref"/>
    <xsl:if test="ancestor::t:lg"><xsl:text>
     </xsl:text></xsl:if>
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
       <xsl:choose>
           <xsl:when test="@break"> <xsl:text>|</xsl:text>
            </xsl:when>
           <xsl:otherwise> <xsl:text> |</xsl:text>
               <sup id="{funct:ID(.)}">
                    <xsl:value-of select="@n"/>
                </sup>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
       
    </xsl:template>
    
    <xsl:template match="t:lb[ancestor::t:ab][parent::t:placeName or parent::t:persName or parent::t:w]">
        <xsl:choose>
            <xsl:when test="@break"> <xsl:text>|</xsl:text>
            </xsl:when>
            <xsl:otherwise> <xsl:text> |</xsl:text>
                <sup>
                    <xsl:value-of select="@n"/>
                </sup>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:template>
    
    <xsl:template match="t:lb[parent::t:l][not(parent::t:ab)]">
        <xsl:if test="preceding-sibling::text()">
            <br/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="t:lb[not(parent::t:ab)][not(parent::t:l)][not(parent::t:w)][not(parent::t:persName)][not(parent::t:placeName)]">
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

    <xsl:template name="line-numbering-tab">
        <!--<xsl:text>		</xsl:text>-->
        <span style="padding-left: 5em;"/>
        <!--double tab would look much better but would not be recognized in browser-->
    </xsl:template>
    
    <xsl:template match="t:pb">
        <xsl:choose>
            <xsl:when test="ancestor::t:div[@type='edition'] or ancestor::dts:fragment">|<sup id="{funct:ID(.)}">
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
        <sup id="{funct:ID(.)}">
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
        <xsl:variable name="extent" select="@extent"/>
        <a>
            <xsl:if test="@resp">
                <xsl:attribute name="data-value">
                    <xsl:value-of select="@resp"/>
                </xsl:attribute>
                <xsl:attribute name="class">w3-tooltip OmissionResp</xsl:attribute>
            </xsl:if>
        <xsl:choose>
                <xsl:when test="@reason = 'illegible'">
                    <xsl:choose>
                        <xsl:when test="@quantity">
                            <xsl:for-each select="1 to $quantity">
            <xsl:text>+</xsl:text>
        </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="@extent">
                            <xsl:for-each select="1 to $extent">
                                <xsl:text>▧</xsl:text>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                           <xsl:text>[...]</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
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
   
    <xsl:template match="t:choice[t:sic and t:orig]">
        <xsl:variable name="id" select="generate-id()"/>
        {<xsl:value-of select="t:corr"/>}
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