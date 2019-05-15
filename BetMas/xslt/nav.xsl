<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    
    
<!--    in the w3-bar all links directly in the bar, 
        as w3-bar-item not sure about the nested ones-->
    
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="t:TEI/@type = 'mss'">
                <xsl:if test="//t:placeName">
                            <a class="w3-bar-item page-scroll" href="/IndexPlaces?entity={string(t:TEI/@xml:id)}">Places Index</a>
                 </xsl:if>
                        <xsl:if test="//t:persName">
                            <a class="w3-bar-item page-scroll" href="/IndexPersons?entity={string(t:TEI/@xml:id)}">Persons Index</a>
                        </xsl:if>
                            <a class="w3-bar-item page-scroll" href="#general">General</a>
                            <a class="w3-bar-item page-scroll" href="#description">Description</a>
                            <a class="w3-bar-item page-scroll" href="#generalphysical">Physical description</a>
                        <xsl:if test="//t:msPart or //t:msFrag">
                            <div class="w3-bar-item">
                                Main parts
                                <ul>
                                <xsl:for-each select="//t:msPart">
                                    <li>
                                        <a class="page-scroll" href="#{@xml:id}">Codicological unit <xsl:value-of select="substring-after(@xml:id, 'p')"/>
                                        </a>
                                    </li>
                                </xsl:for-each>
                                    <xsl:for-each select="//t:msFrag">
                                        <li>
                                            <a class="page-scroll" href="#{@xml:id}">Fragment <xsl:value-of select="substring-after(@xml:id, 'f')"/>
                                            </a>
                                        </li>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </xsl:if>
                        <xsl:if test="//t:additional//t:listBibl">
                            
                            <a class="w3-bar-item page-scroll" href="#catalogue">Catalogue</a>
                            
                        </xsl:if>
                        <xsl:if test="//t:body[t:div]">
                            
                                <a class=" w3-bar-item page-scroll" href="#transcription">Transcription </a>
                            
                        </xsl:if>
                        
                            <a class="w3-bar-item page-scroll" href="#footer">Authors</a>
                        
                
                <button class="w3-button w3-red w3-bar-item" onclick="openAccordion('NavByIds')">Show more links</button>
                <ul class="w3-bar-item w3-hide" id="NavByIds">
                            <xsl:for-each select="//*[not(self::t:TEI)][@xml:id]">
                                <xsl:sort select="position()"/>
                                <li>
                                    <a class="page-scroll" href="#{@xml:id}">
                                        <xsl:choose>
                                            <xsl:when test="@xml:id = 'ms'">General manuscript description</xsl:when>
                                            <xsl:when test="starts-with(@xml:id, 'p') and matches(@xml:id, '^\w\d+$')">Codicological Unit <xsl:value-of select="substring-after(@xml:id, 'p')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="starts-with(@xml:id, 'f') and matches(@xml:id, '^\w\d+$')">Fragment <xsl:value-of select="substring-after(@xml:id, 'f')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 't') and matches(@xml:id, '\w\d+')">Title <xsl:value-of select="substring-after(@xml:id, 't')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'b') and matches(@xml:id, '\w\d+')">Binding <xsl:value-of select="substring-after(@xml:id, 'b')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'a') and matches(@xml:id, '\w\d+')">Addition <xsl:value-of select="substring-after(@xml:id, 'a')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'e') and matches(@xml:id, '\w\d+')">Extra <xsl:value-of select="substring-after(@xml:id, 'e')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'i') and matches(@xml:id, '_\w\d+')">Content Item <xsl:value-of select="substring-after(@xml:id, 'i')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'q') and matches(@xml:id, '\w\d+')">Quire <xsl:value-of select="substring-after(@xml:id, 'q')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'coloph')">Colophon
                                                <xsl:value-of select="substring-after(@xml:id, 'coloph')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'h') and matches(@xml:id, '\w\d+')">Hand <xsl:value-of select="substring-after(@xml:id, 'h')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'div')">Divider <xsl:value-of select="substring-after(@xml:id, 'div')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:when test="contains(@xml:id, 'd') and matches(@xml:id, '\w\d+')">Decoration <xsl:value-of select="substring-after(@xml:id, 'd')"/>
                                                <xsl:if test="./ancestor::t:msPart">
                                                    <xsl:variable name="currentMsPart">
                                                        <xsl:value-of select="substring-after(./ancestor::t:msPart/@xml:id, 'p')"/>
                                                    </xsl:variable> of codicological unit
                                                    <xsl:value-of select="$currentMsPart"/>
                                                </xsl:if>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="name()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </ul>
                    
                
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'work'">
                
                    <a class="w3-bar-item page-scroll" href="#description">Description</a>
                
                <xsl:if test="//t:placeName">
                    <a class="w3-bar-item page-scroll" href="/IndexPlaces?entity={string(t:TEI/@xml:id)}">Places Index</a>
                </xsl:if>
                <xsl:if test="//t:persName">
                    <a class="w3-bar-item page-scroll" href="/IndexPersons?entity={string(t:TEI/@xml:id)}">Persons Index</a>
                </xsl:if>
                <xsl:if test="//t:body[t:div[@type='edition'][t:ab or t:div[@type='textpart']]]">
                    
                    <a class="w3-bar-item page-scroll w3-red" href="/works/{t:TEI/@xml:id}/text">Text</a>
                    
                </xsl:if>
                <xsl:if test="//t:body[t:div[@type='translation'][t:ab or t:div[@type='textpart']]]">
                    
                    <a class="w3-bar-item page-scroll w3-red" href="/works/{t:TEI/@xml:id}/text">Translation</a>
                    
                </xsl:if>
                
                <a class="w3-bar-item page-scroll" href="#bibliography">Bibliography</a>
                
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'nar'">
                
                <a class="w3-bar-item page-scroll" href="#general">General</a>
                
                
                <a class="w3-bar-item page-scroll" href="#description">Description</a>
                
                
                <a class="w3-bar-item page-scroll" href="#authors">Authors</a>
                
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'ins' or t:TEI/@type = 'place'">
                <a class="w3-bar-item page-scroll" href="/IndexPlaces?pointer={string(t:TEI/@xml:id)}">Places Index</a>
                
                <a class="w3-bar-item page-scroll" href="#general">General</a>
                
                
                <a class="w3-bar-item page-scroll" href="#description">Description</a>
                
                
                <a class="w3-bar-item page-scroll" href="#map">Map</a>
                
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'pers'">
                <a class="w3-bar-item page-scroll" href="/IndexPersons?pointer={string(t:TEI/@xml:id)}">Persons Index</a>
                <a class="w3-bar-item page-scroll" href="#general">General</a>
                
                <xsl:if test="//t:birth">
                    
                        <a class="w3-bar-item page-scroll" href="#birth">Birth</a>
                
                </xsl:if>
                <xsl:if test="//t:death">
                    
                        <a class="w3-bar-item page-scroll" href="#death">Death</a>
                
                </xsl:if>
                <xsl:if test="//t:floruit">
                
                    <a class="w3-bar-item page-scroll" href="#floruit">Floruit</a>
                
                </xsl:if>
            </xsl:when>
            <xsl:when test="t:TEI/@type = 'auth'">
                
                    <a class="w3-bar-item page-scroll" href="#general">General</a>
                
                
                    <a class="w3-bar-item page-scroll" href="#description">Description</a>
                
                
                <a class="w3-bar-item page-scroll" href="#authors">Authors</a>
                
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>