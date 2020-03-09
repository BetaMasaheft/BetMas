<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:template match="t:locus">
        <xsl:param name="text" tunnel="yes"/>
        <xsl:variable name="parent" select="parent::node()"/>
        
        <xsl:variable name="anc" select="ancestor::t:*[@xml:id][1]"/>
        <xsl:variable name="ancID" select="replace($anc/@xml:id, '\.', '_')"/>
        <xsl:if test="parent::t:ab[not(@type = 'CruxAnsata' or @type = 'ChiRho' or @type = 'coronis')]">
            <xsl:text>(Excerpt from </xsl:text>
        </xsl:if>
        <xsl:choose>
<!--            deals with the empty use of locus-->
            <xsl:when test="not(text())">
                <xsl:choose>
<!--                    if there is a @target pointing to one or a list of non consecutive folia-->
                    <xsl:when test="@target">
                        <xsl:choose>
<!--                            a list of references to folia-->
                            <xsl:when test="contains(@target,' ')">
<!--                                this will need a plural abbreviation-->
                                <xsl:choose>
                                    <xsl:when test="//t:extent/t:measure[@unit='page']">pp.</xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>ff. </xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
<!--                                stores eventual reference to external id-->
                                <xsl:variable name="f" select="@facs"/>
<!--                                tokenize the content of @target by space-->
                                <xsl:for-each select="tokenize(@target,' ')">
                                    <a href="{.}">
                                        <xsl:choose>
<!--                                            if there is an external reference, then add attributes to call the modal containing the images-->
                                            <xsl:when test="$f  and not($text = 'only')">
                                                <xsl:attribute name="onclick">
                                                    <xsl:value-of select="concat('document.getElementById(&#34;images',concat(replace(normalize-space($f), ' ', '_'), $ancID), '&#34;).style.display=&#34;block&#34;')"/>
                                                </xsl:attribute>
                                                </xsl:when>
<!--                                            MISSING THE OPTION FOR INTERNAL IMAGE SERVER-->
                                            <xsl:otherwise>
<!--                                            if there is no image or external reference then add a simple popover-->
                                                <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                                <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="concat(substring-after(.,'#'), ' ')"/>
                                                </span>
                                                
                                            </xsl:otherwise>
                                        </xsl:choose>
                                        <xsl:value-of select="concat(substring-after(.,'#'), ' ')"/>
                                    </a>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
<!--                                The case in which @target conainst only one reference-->
                                <a href="{@target}">
                                    <xsl:choose>
                                       
                                       <!--                                            if there is an external reference, then add attributes to call the modal containing the images-->
                                        <xsl:when test="@facs  and not($text = 'only')">
                                            <xsl:attribute name="onclick">
                                                <xsl:value-of select="concat('document.getElementById(&#34;images',concat(replace(normalize-space(@facs), ' ', '_'), $ancID), '&#34;).style.display=&#34;block&#34;')"/>
                                            </xsl:attribute>
                                        </xsl:when>
                                       
                                       <!--                                            MISSING THE OPTION FOR INTERNAL IMAGE SERVER-->
                                        <xsl:otherwise>
                                           
                                           <!--                                            if there is no image or external reference then add a simple popover-->
                                            <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                            <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="concat(substring-after(@target,'#'), ' ')"/>
                                            </span>
                                            
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:choose>
                                        <xsl:when test="//t:extent/t:measure[@unit='page']">p.</xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>f. </xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:value-of select="substring-after(@target,'#')"/>
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
<!--                        if there is no target there might be a @from, a @to or both-->
                        <xsl:choose>
                            <xsl:when test="//t:extent/t:measure[@unit='page']">pp.</xsl:when>
                            <xsl:otherwise>
                                <xsl:text>ff. </xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                        <a href="#{@from}">
                            <xsl:choose>
                                <xsl:when test="@facs  and not($text = 'only')">
                                    <xsl:attribute name="onclick">
                                        <xsl:value-of select="concat('document.getElementById(&#34;images',concat(replace(normalize-space(@facs), ' ', '_'), $ancID), '&#34;).style.display=&#34;block&#34;')"/>
                                    </xsl:attribute>
                                    
                                    
                                </xsl:when>
                                
                                <!--                                            MISSING THE OPTION FOR INTERNAL IMAGE SERVER-->
                                <xsl:otherwise>
                                <!--                                            if there is no image or external reference then add a simple popover-->
                                    <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                    <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="@from"/>
                                    </span>
                                    
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="@from"/>
                        </a>
                        <xsl:text>-</xsl:text>
                        <a href="#{@to}">
                            <xsl:choose>
                                <xsl:when test="@facs  and not($text = 'only')">
                                    <xsl:attribute name="onclick">
                                        <xsl:value-of select="concat('document.getElementById(&#34;images',concat(replace(normalize-space(@facs), ' ', '_'), $ancID), '&#34;).style.display=&#34;block&#34;')"/>
                                    </xsl:attribute>
                                    
                                   
                                </xsl:when>
                                <xsl:otherwise>
                <!--                                            if there is no image or external reference then add a simple popover-->
                                    <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                    <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="@to"/>
                                    </span>
                                    </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="@to"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="@n">
                    <xsl:text>, l.</xsl:text>
                    <xsl:value-of select="@n"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
<!--                if there is text or other data inside locus-->
                <xsl:choose>
                    <xsl:when test="@target">
                        <a href="{@target}">
                            <xsl:choose>
                                <xsl:when test="@facs  and not($text = 'only')">
                                    <xsl:attribute name="onclick">
                                        <xsl:value-of select="concat('document.getElementById(&#34;images',concat(replace(normalize-space(@facs), ' ', '_'), $ancID, '&#34;).style.display=&#34;block&#34;'))"/>
                                    </xsl:attribute>
                                </xsl:when>
                               
                               <!--                                            MISSING THE OPTION FOR INTERNAL IMAGE SERVER-->
                                <xsl:otherwise>
                                <!--                                            if there is no image or external reference then add a simple popover-->
                                    <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                    <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="concat(substring-after(@target,'#'), ' ')"/>
                                    </span>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="."/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <a href="#{@from}">
                            <xsl:choose>
                                <xsl:when test="@facs  and not($text = 'only')">
                                    <xsl:attribute name="onclick">
                                        <xsl:value-of select="concat('document.getElementById(&#34;images',                                             concat(replace(normalize-space(@facs), ' ', '_'),                                              $ancID, '&#34;).style.display=&#34;block&#34;'))"/>
                                    </xsl:attribute>
                                </xsl:when>
                                
                                <!--                                            MISSING THE OPTION FOR INTERNAL IMAGE SERVER-->
                                <xsl:otherwise>
                                <!--                                            if there is no image or external reference then add a simple popover-->
                                    <xsl:attribute name="class">w3-tooltip</xsl:attribute>
                                    <span class="w3-text w3-tag">There is no image available at the moment for <xsl:value-of select="@from"/>
                                    </span>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="."/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="@cert = 'low'">
            <xsl:text> (?)</xsl:text>
        </xsl:if>
<!--        if there is a refernce to an external resource build the modal conatining the openseadragon javascript-->
        <xsl:if test="@facs and not($text = 'only')">
            <xsl:variable name="anc" select="ancestor::t:*[@xml:id][1]"/>
            <xsl:variable name="ancID" select="replace($anc/@xml:id, '\.', '_')"/>
            <xsl:variable name="modalid" select="concat('images',replace(normalize-space(@facs), ' ', '_'), $ancID)"/>
            <div class="w3-modal" id="{$modalid}">
                
                    
                    <!-- Modal content-->
                    <div class="w3-modal-content">
                            <header class="w3-container">
                                <h4>Images relevant for <span class="MainTitle" data-value="{$mainID}#{$ancID}"/>, from <xsl:value-of select="ancestor::t:TEI//t:msIdentifier/t:idno/@facs"/>
                        </h4>
                                <div>
                                    <xsl:choose>
                                        <xsl:when test="@target">You are viewing a sequence of images including ff. <xsl:value-of select="replace(string-join(tokenize(normalize-space(@target), ' #'), ', '), '#', '')"/>
                                </xsl:when>
                                        <xsl:otherwise>You are viewing a sequence of images from f. <xsl:value-of select="@from"/> <xsl:if test="@to">to f. <xsl:value-of select="@to"/>
                                    </xsl:if>
                                </xsl:otherwise>
                                   </xsl:choose>
                                </div>
                                <button class="w3-button w3-gray w3-display-topright" onclick="document.getElementById('{$modalid}').style.display='none'">Close</button>
                            </header>
                        
                        <div class="w3-container">
                            <xsl:variable select="ancestor::t:TEI//t:msIdentifier/t:idno/@facs" name="MainFacs"/>
                            <xsl:variable name="mid">
                                <xsl:choose>
                                    <xsl:when test="parent::t:witness">
                                    <xsl:value-of select="parent::t:witness/@corresp"/>
                                </xsl:when>
                                    <xsl:otherwise>
                                    <xsl:value-of select="$mainID"/>
                                </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:variable name="manifest">
                                <xsl:choose>
                                    <xsl:when test="starts-with($MainFacs, 'http')">
                                    <xsl:value-of select="$MainFacs"/>
                                </xsl:when>
                                    <xsl:otherwise>
                                    <xsl:value-of select="concat('https://betamasaheft.eu/api/iiif/',$mid, '/manifest')"/>
                                </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:variable name="firstCanv">
                                <xsl:variable name="fc">
                                    <xsl:choose>
                                        <xsl:when test="contains(@facs, ' ')">
                                            <xsl:value-of select="substring-before(@facs, ' ')"/>
                                        </xsl:when>
                                        <xsl:otherwise> <xsl:value-of select="@facs"/>
                                    </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:variable name="fcc" select="replace($fc, '[a-z\s]', '')"/>
                                
                                <xsl:if test="not(starts-with($MainFacs, 'http'))">
                                    <xsl:value-of select="concat('?FirstCanv=', 'https://betamasaheft.eu/api/iiif/',$mid, '/canvas/p', format-number(xs:integer($fcc), '###'))"/>
                                </xsl:if>
                            </xsl:variable>
                            <xsl:variable name="mirador" select="concat('https://betamasaheft.eu/manuscripts/',$mid, '/viewer', $firstCanv)"/>
                            <p class="w3-panel w3-red">
                            <a href="{$manifest}" target="_blank">
                                <img src="/resources/images/iiif.png" width="20px"/>
                            </a>
                                <a href="{$mirador}" target="_blank">Open with Mirador Viewer</a>
                        </p>
                           
                            <div id="openseadragon{replace(@facs, ' ', '_')}{ancestor::t:*[@xml:id][1]/@xml:id}"/>
                            <script type="text/javascript">
                                <xsl:text>
                           OpenSeadragon({
                           id: "openseadragon</xsl:text>
                                <xsl:value-of select="concat(replace(@facs, ' ', '_'), ancestor::t:*[@xml:id][1]/@xml:id)"/>
                                <xsl:text>",
                           prefixUrl: "../resources/openseadragon/images/",
                           preserveViewport: true,
                           visibilityRatio:    1,
                           minZoomLevel:       1,
                           defaultZoomLevel:   1,</xsl:text>
                                <xsl:if test="(@from and @to) or @target[contains(., ' ')]">    sequenceMode:      true,</xsl:if>
                                <xsl:text>tileSources:   [</xsl:text>
<!--                             the desired output is here a list of the images included in the range
                                in this format
                                ["http://gallica.bnf.fr/iiif/ark:/12148/btv1b525023971/f213/info.json",
                                "http://gallica.bnf.fr/iiif/ark:/12148/btv1b525023971/f213/info.json" ]
                                
                                where the info.json is the standard response of an image server compliant with iiif image api server
                                -->
                                <xsl:variable name="f" select="@facs"/>
                                <xsl:variable name="idnoFacs" select="ancestor::t:TEI//t:msIdentifier/t:idno/@facs"/>
                                <xsl:choose>
<!--                                    check the source of the image, parsing the url provided in the main idno facs-->
                                    
<!--                                    images from gallica
                                    
                                    one for each side of a folio, not openinings. eg. BNFet102
                                    -->
                                    <xsl:when test="contains($idnoFacs, 'gallica')">
                                        <xsl:variable name="iiif" select="replace($idnoFacs,'/ark:', '/iiif/ark:')"/>
                                <xsl:choose>
                                    <xsl:when test="@from and @to">
                                        <xsl:variable name="from" select="                                             if(contains(@from, 'r'))                                              then substring-before(@from, 'r')                                                                                          else  if(contains(@from, 'v'))                                              then (substring-before(@from, 'v'))                                                                                          else @from                                                                                          "/>
                                        <xsl:variable name="to" select="                                                 if(contains(@to, 'r'))                                                  then substring-before(@to, 'r')                                                                                                   else  if(contains(@to, 'v'))                                                  then (substring-before(@to, 'v'))                                                                                                  else @to                                                                                                  "/>
                                        <xsl:variable name="count" select="(number($to) - number($from)) * 2"/>
                                        <xsl:variable name="tiles">
                                            <xsl:for-each select="0 to (xs:integer($count) +1 )">
                                                <xsl:text>"</xsl:text>
                                                <xsl:value-of select="concat($iiif,'/f', (xs:integer(substring-after($f, 'f')) + current()),'/info.json')"/>
                                                <xsl:text>"</xsl:text>
                                                <xsl:if test="not(current()=(xs:integer($count) +1 ))">,</xsl:if>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="$tiles"/>
                                    </xsl:when>
                                    <xsl:when test="@from and not(@to)">
                                        <xsl:text>"</xsl:text>
                                        <xsl:value-of select="concat($iiif,'/', @facs,'/info.json')"/>
                                        <xsl:text>"</xsl:text>
                                    </xsl:when>
                                    <xsl:when test="@target">
                                        <xsl:for-each select="tokenize(@facs, ' ')">
                                            <xsl:text>"</xsl:text>
                                            <xsl:value-of select="concat($iiif,'/', .,'/info.json')"/>
                                            <xsl:text>"</xsl:text>
                                            <xsl:if test="not(position()=last())">,</xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                </xsl:choose>
                                    </xsl:when>
                                    
<!--                                    images from our server -->
                                    <xsl:when test="matches($idnoFacs, '\w{3}/\d{3}/\w{3,4}-\d{3}')">
                                    <xsl:variable name="iiif" select="$idnoFacs"/>
                                    <xsl:variable name="fullIIIF" select="concat('/iiif/',$idnoFacs)"/>
                                    <!--                                    expected format: of //t:TEI//t:msIdentifier/t:idno/@facs is : BMQ/003/BMQM-003 where the 
                                    first folder is the institution folder, then there is the number of the manuscript and the prefix of the photos which must have been converted to .tif 
                                    -->
                                    <xsl:choose>
                                        <xsl:when test="@from and @to">
                                            <xsl:variable name="from" select="                                             if(contains(@from, 'r'))                                              then substring-before(@from, 'r')                                                                                          else  if(contains(@from, 'v'))                                              then (substring-before(@from, 'v'))                                                                                          else @from                                                                                          "/>
                                            <xsl:variable name="to" select="                                                 if(contains(@to, 'r'))                                                  then substring-before(@to, 'r')                                                                                                   else  if(contains(@to, 'v'))                                                  then (substring-before(@to, 'v'))                                                                                                  else @to                                                                                                  "/>
                                            <xsl:variable name="count" select="(number($to) - number($from)) * 2"/>
                                            <xsl:variable name="tiles">
                                                <xsl:for-each select="0 to (xs:integer($count) +1 )">
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:value-of select="concat($fullIIIF,'_', format-number((xs:integer($f) + current()), '000'),'.tif/info.json')"/>
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:if test="not(current()=(xs:integer($count) +1 ))">,</xsl:if>
                                                </xsl:for-each>
                                            </xsl:variable>
                                            <xsl:value-of select="$tiles"/>
                                        </xsl:when>
                                        <xsl:when test="@from and not(@to)">
                                            <xsl:text>"</xsl:text>
                                            <xsl:value-of select="concat($fullIIIF,'_', @facs,'.tif/info.json')"/>
                                            <xsl:text>"</xsl:text>
                                        </xsl:when>
                                        <xsl:when test="@target">
                                            <xsl:for-each select="tokenize(@facs, ' ')">
                                                <xsl:text>"</xsl:text>
                                                <xsl:value-of select="concat($fullIIIF,'_', .,'.tif/info.json')"/>
                                                <xsl:text>"</xsl:text>
                                                <xsl:if test="not(position()=last())">,</xsl:if>
                                            </xsl:for-each>
                                        </xsl:when>
                                    </xsl:choose>
                                    
                                </xsl:when>
<!--                                    EMIP .  -->
                                    <xsl:when test="matches($idnoFacs, 'EMIP/Codices/\d+/')">
                                        
                                        <xsl:variable name="iiif" select="$idnoFacs"/>
                                        <xsl:variable name="fullIIIF" select="concat('/iiif/',$idnoFacs)"/>
                                        <!--                                    expected format: of //t:TEI//t:msIdentifier/t:idno/@facs is : EMIP/Codices/8/ where the 
                                    first folder is the institution folder, then there Codices, for the process of transformation and the number of the manuscript. Photos converted to .tif have names which are not prefixed. 
                                    -->
                                        <xsl:choose>
                                            <xsl:when test="@from and @to">
                                                <xsl:choose>
                                                    <xsl:when test="matches(@from, 'i') or matches(@to, 'i')"/>
                                                    <xsl:otherwise>
                                                <xsl:variable name="from" select="                                             if(contains(@from, 'r'))                                              then substring-before(@from, 'r')                                                                                          else  if(contains(@from, 'v'))                                              then (substring-before(@from, 'v'))                                                                                          else @from                                                                                          "/>
                                                <xsl:variable name="to" select="                                                 if(contains(@to, 'r'))                                                  then substring-before(@to, 'r')                                                                                                   else  if(contains(@to, 'v'))                                                  then (substring-before(@to, 'v'))                                                                                                  else @to                                                                                                  "/>
                                                <xsl:variable name="count" select="(number($to) - number($from)) * 2"/>
                                                <xsl:variable name="tiles">
                                                    <xsl:for-each select="0 to (xs:integer($count) +1)">
                                                        <xsl:text>"</xsl:text>
                                                        <xsl:value-of select="concat($fullIIIF, format-number((xs:integer($f) + current()), '000'),'.tif/info.json')"/>
                                                        <xsl:text>"</xsl:text>
                                                        <xsl:if test="not(current()=(xs:integer($count) +1 ))">,</xsl:if>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                <xsl:value-of select="$tiles"/>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </xsl:when>
                                            <xsl:when test="@from and not(@to)">
                                                <xsl:text>"</xsl:text>
                                                <xsl:value-of select="concat($fullIIIF, string(@facs),'.tif/info.json')"/>
                                                <xsl:text>"</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="@target">
                                                <xsl:for-each select="tokenize(string(@facs), ' ')">
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:value-of select="concat($fullIIIF, .,'.tif/info.json')"/>
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:if test="not(position()=last())">,</xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                        </xsl:choose>
                                        
                                    </xsl:when>
                                    
<!--                                    laurenziana-->
                                    <xsl:when test="matches($idnoFacs, 'Laurenziana')">
                                        <xsl:variable name="iiif" select="$idnoFacs"/>
                                        <xsl:variable name="fullIIIF" select="concat('/iiif/',$idnoFacs)"/>
                                        <!--                                    expected format: of //t:TEI//t:msIdentifier/t:idno/@facs is : Laurenziana/BML_001/BML_001-
                                           -->
                                        <xsl:choose>
                                            <xsl:when test="@from and @to">
                                                <xsl:variable name="from" select="                                             if(contains(@from, 'r'))                                              then substring-before(@from, 'r')                                                                                          else  if(contains(@from, 'v'))                                              then (substring-before(@from, 'v'))                                                                                          else @from                                                                                          "/>
                                                <xsl:variable name="to" select="                                                 if(contains(@to, 'r'))                                                  then substring-before(@to, 'r')                                                                                                   else  if(contains(@to, 'v'))                                                  then (substring-before(@to, 'v'))                                                                                                  else @to                                                                                                  "/>
                                                <xsl:variable name="count" select="(number($to) - number($from)) * 2"/>
                                                <xsl:variable name="tiles">
                                                    <xsl:for-each select="0 to (xs:integer($count) +1 )">
                                                        <xsl:text>"</xsl:text>
                                                        <xsl:value-of select="concat($fullIIIF, format-number((xs:integer($f) + current()), '000'),'.tif/info.json')"/>
                                                        <xsl:text>"</xsl:text>
                                                        <xsl:if test="not(current()=(xs:integer($count) +1 ))">,</xsl:if>
                                                    </xsl:for-each>
                                                </xsl:variable>
                                                <xsl:value-of select="$tiles"/>
                                            </xsl:when>
                                            <xsl:when test="@from and not(@to)">
                                                <xsl:text>"</xsl:text>
                                                <xsl:value-of select="concat($fullIIIF, @facs,'.tif/info.json')"/>
                                                <xsl:text>"</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="@target">
                                                <xsl:for-each select="tokenize(@facs, ' ')">
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:value-of select="concat($fullIIIF, .,'.tif/info.json')"/>
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:if test="not(position()=last())">,</xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                        </xsl:choose>
                                        
                                    </xsl:when>
                                    <xsl:when test="contains($idnoFacs, 'vatlib')">
                                        <!--                                  
                                            images infos are at 
                                            http://digi.vatlib.it/iiifimage/MSS_Vat.et.1/Vat.et.1_0003.jp2/info.json
                                        
                                        http://digi.vatlib.it/iiif/MSS_Vat.et.1/manifest.json
                                        http://digi.vatlib.it/mss/detail/Vat.et.1
                                        as for gallica many assumptions are made, which could be avoided using jquery to build the viewer instead of this xslt script.
                                        -->
                                        <xsl:variable name="msname" select="substring-after(substring-before($idnoFacs, 'manifest.json'), 'MSS_')"/>
                                        <xsl:variable name="iiif" select="concat('https://digi.vatlib.it/iiifimage/MSS_', $msname, substring-before($msname, '/'), '_')"/>
                                        <!--                                    expected format: of //t:TEI//t:msIdentifier/t:idno/@facs is : 
                                        http://digi.vatlib.it/iiif/MSS_Vat.et.1/manifest.json
                                        -->
                                        <xsl:choose>
                                            <xsl:when test="(@from and @to) and (matches(@from, '\d') and matches(@to, '\d'))">
                                                <xsl:variable name="from" select="                                             if(contains(@from, 'r'))                                              then substring-before(@from, 'r')                                                                                          else  if(contains(@from, 'v'))                                              then (substring-before(@from, 'v'))                                                                                          else @from                                                                                          "/>
                                                <xsl:variable name="to" select="                                                 if(contains(@to, 'r'))                                                  then substring-before(@to, 'r')                                                                                                   else  if(contains(@to, 'v'))                                                  then (substring-before(@to, 'v'))                                                                                                  else @to                                                                                                  "/>
                                                <xsl:variable name="count" select="(number($to) - number($from)) + 1"/><!--how many images to take, images are openings in this case, + 1 is to include the verso-->
                                                <xsl:variable name="tiles">
                                                    
                                                    <!--                                                        the format-number function in the concat takes what is in @facs of the current locus (stored in variable $f) and adds to it progressively the number in count. 
                                                            So, starting from 6 and looping on count=3 we will have the following sequence 6, 6+1=7, 6+2=8, 6+3=9 -->
                                                    <xsl:sequence select="for $x in 0 to (xs:integer($count)) return concat('&#34;',$iiif,                                                              format-number(                                                             (xs:integer($f) + $x)                                                             , '0000'),                                                             '.jp2/info.json','&#34;,')"/>
                                                </xsl:variable>
                                                <xsl:variable name="str" select="string-join($tiles, ' ')"/><!--makes the sequence into a string-->
                                                <xsl:value-of select="substring($str, 1, string-length($str) - 1)"/><!--strips the last commma-->
                                            </xsl:when>
                                            <xsl:when test="@from and not(@to) and matches(@from, '\d')">
                                                <xsl:text>"</xsl:text>
                                                <xsl:value-of select="concat($iiif, @facs,'.jp2/info.json')"/>
                                                <xsl:text>"</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="@target and matches(@target, '\d')">
                                                <xsl:for-each select="tokenize(@facs, ' ')">
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:value-of select="concat($iiif, .,'.jp2/info.json')"/>
                                                    <xsl:text>"</xsl:text>
                                                    <xsl:if test="not(position()=last())">,</xsl:if>
                                                </xsl:for-each>
                                            </xsl:when>
                                        </xsl:choose>
                                        
                                    </xsl:when>
                                </xsl:choose>
                                <xsl:text> ]
                           });
                        </xsl:text>
                            </script>
                            <p class="w3-panel w3-red">
                            <a href="https://openseadragon.github.io/">OpenSeadragon Viewer</a>
                        </p>
                        </div>
                        </div>
                        
                
            </div>
        </xsl:if>
        <xsl:if test="parent::t:ab">
            <xsl:text>)</xsl:text>
            <br/>
        </xsl:if>
<!--    <xsl:apply-templates/>-->
    </xsl:template>
</xsl:stylesheet>