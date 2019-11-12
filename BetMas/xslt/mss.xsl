<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:key name="decotype" match="//t:decoNote" use="@type"/>
    <xsl:key name="additiontype" match="//t:item[contains(@xml:id, 'a')]/t:desc" use="@type"/>
    <xsl:variable name="mainidno" select="//t:msIdentifier/t:idno"/>
    <xsl:variable name="mainID" select="t:TEI/@xml:id"/>
    <xsl:template match="/">
        <div class="w3-twothird" id="MainData">
        <span property="http://www.cidoc-crm.org/cidoc-crm/P48_has_preferred_identifier" content="{$mainID}"/>
        <div class="w3-container" id="description" typeof="http://lawd.info/ontology/AssembledWork https://betamasaheft.eu/mss">
            <xsl:if test="//t:date[@evidence = 'internal-date'] or //t:origDate[@evidence = 'internal-date']">
                <h1>
                    <span class="label label-primary">Dated</span>
                </h1>    
                
            </xsl:if>
            
                <div id="maintoogles" class="btn-group">
                
                    <div class="w3-bar">
                        <a class="w3-bar-item  w3-hide-medium w3-hide-small w3-button w3-gray" id="tooglecodicologicalInformation">Hide/show codicological information</a>
                        <a class="w3-bar-item w3-hide-medium w3-hide-small w3-button w3-gray" id="toogletextualcontents">Hide/show contents</a>
                    </div>
            </div>
            
            <h2>General description</h2>
            <div class="w3-third  w3-padding">
                <h4 property="http://purl.org/dc/elements/1.1/title">
                <xsl:apply-templates select="//t:titleStmt/t:title"/>
            </h4>
               
                <button class="w3-button w3-red w3-large" id="showattestations" data-value="mss" data-id="{string(t:TEI/@xml:id)}">Show attestations</button>
                <div id="allattestations" class="w3-container"/>
            <xsl:if test="//t:listPerson/t:person[@ref]">
                <h3>People</h3>
                <xsl:for-each select="//t:listPerson/t:person">
                    <p>
                        <xsl:apply-templates/>
                    </p>
                </xsl:for-each>
            </xsl:if>
            </div>
            <div class="w3-third  w3-padding">
                <h4>Number of Text units: <span class="label label-default">
                        <xsl:value-of select="count(//t:msItem[contains(@xml:id, 'i')])"/>
                    </span>
            </h4>
            </div>
            <span property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts" content="{count(//t:msContents/t:msItem)}"/>
            <div class="w3-third  w3-padding">
                <h4>Number of Codicological units: <span class="label label-default">
                        <xsl:choose>
                    <xsl:when test="//t:msPart">
                        <xsl:value-of select="count(//t:msPart)"/>
                    </xsl:when>
                    <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose>
                    </span>
            </h4>
            </div>
        </div>
            <xsl:if test="//t:relation">
                <div class="w3-container">
                    <p>
                        <xsl:if test="//t:relation[not(starts-with(@name, 'sdc:'))][not(contains(@passive, $mainID))]">
                            <xsl:text>See </xsl:text>
                        </xsl:if>
                        <xsl:for-each select="//t:relation[not(starts-with(@name, 'sdc:'))][not(contains(@passive, $mainID))]">
                            <xsl:sort order="ascending" select="count(preceding-sibling::t:relation)+1"/>
                            <xsl:variable name="p" select="count(preceding-sibling::t:relation)+1"/>
                            <xsl:variable name="tot" select="count(//t:relation)"/>
                            <xsl:apply-templates select="." mode="gendesc"/><xsl:choose>
                                <xsl:when test="$p!=$tot"><xsl:text>, </xsl:text></xsl:when>
                                <xsl:otherwise>.</xsl:otherwise></xsl:choose>
                        </xsl:for-each>
                        For a table of all relations from and to this record, please go to the <a class="w3-tag w3-gray" href="/manuscripts/{$mainID}/analytic">Relations</a> view. In the Relations boxes on the right of this page, you can also find all available relations grouped by name.
                    </p>
                </div>
            </xsl:if>
        <div class="w3-container" id="generalphysical">
            <xsl:apply-templates select="//t:msDesc"/>
        </div>
        <img id="loadingRole" src="resources/Loading.gif" style="display: none;"/>  
        <div id="roleAttestations"/>
        </div>
        <xsl:call-template name="resp">
            <xsl:with-param name="resp" select="."/>
        </xsl:call-template>
        <xsl:call-template name="calendar">
            <xsl:with-param name="dates" select="."/>
        </xsl:call-template>
    </xsl:template>
    

    
    <xsl:include href="resp.xsl"/>
   <xsl:include href="certainty.xsl"/>
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="msselements.xsl"/>
     <xsl:include href="dimensions.xsl"/>
    <xsl:include href="extent.xsl"/>
    <xsl:include href="foliation.xsl"/>
    <xsl:include href="material.xsl"/>
    <xsl:include href="handNote.xsl"/>
    <xsl:include href="bindingDesc.xsl"/>
    <xsl:include href="summary.xsl"/>
    <xsl:include href="msItem.xsl"/>
    <xsl:include href="colophon.xsl"/>
    <xsl:include href="condition.xsl"/>
    <xsl:include href="layoutDesc.xsl"/>
    <xsl:include href="additions.xsl"/>
    <xsl:include href="decoDesc-1.xsl"/>
    <xsl:include href="collation.xsl"/>
    <xsl:include href="collationstep1.xsl"/>
    <xsl:include href="collationstep2.xsl"/>
    <xsl:include href="collationstep3.xsl"/>
    <xsl:include href="collationstep4.xsl"/>
    <xsl:include href="collationdiagrams.xsl"/>
    <xsl:include href="VARIAsmall.xsl"/> 
    <xsl:include href="faith.xsl"/>
    <xsl:include href="provenance.xsl"/>
    <xsl:include href="handDesc.xsl"/>
    <xsl:include href="msContents.xsl"/>
    <xsl:include href="history.xsl"/>
    <xsl:include href="divEdition.xsl"/>
    
<!--        elements with references-->
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <!-- includes also region, country and settlement-->
    <xsl:include href="title.xsl"/>
    <xsl:include href="repo.xsl"/>
    <!--produces also the javascript for graph-->
</xsl:stylesheet>