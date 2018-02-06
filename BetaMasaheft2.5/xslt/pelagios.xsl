<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    
    <xsl:output method="text"/>
    <xsl:template match="/"> 
        
        <xsl:choose>
            <xsl:when test="//t:objectType[@ref]">  
                &lt;http://betamasaheft.aai.uni-hamburg.de/api/BetMas/places/all#<xsl:value-of select="//t:text/@xml:id"/>&gt;
            a pelagios:AnnotatedThing' ;
            dcterms:title "<xsl:value-of select="//t:titleStmt/t:title"/>" ;
                foaf:homepage &lt;http://betamasaheft.aai.uni-hamburg.de:8080/exist/apps/OEDUc/inscription/<xsl:value-of select="//t:text/@xml:id"/>&gt; ;
                dcterms:language "<xsl:value-of select="//t:titleStmt/t:title/text()"/>" ;
                dcterms:subject "<xsl:value-of select="//t:objectType/@ref"/>" ;
            .
            
            <xsl:for-each-group select="//t:placeName" group-by="@ref">
                <xsl:sort select="@ref"/>
                <xsl:variable name="rank" select="position()"/>
                &lt;http://betamasaheft.aai.uni-hamburg.de/api/OEDUc/places/all#<xsl:value-of select="//t:text/@xml:id"/>/annotations/<xsl:value-of select="$rank"/>&gt;
                a oa:Annotation ;
                oa:hasTarget &lt;http://betamasaheft.aai.uni-hamburg.de/api/OEDUc/places/all#<xsl:value-of select="//t:text/@xml:id"/>&gt; ;
                oa:hasBody &lt;<xsl:value-of select="normalize-space(@ref)"/>&gt; ;
                oa:annotatedAt "<xsl:value-of select="current-dateTime()"/>"^^xsd:date ;
                .
            </xsl:for-each-group>
            
            
            
        </xsl:when>
            <xsl:otherwise>
                there is no objectType
               <!-- <http://pietroliuzzo.github.io/Aristodemo/rdf/places.ttl#papyrus>
                a pelagios:AnnotatedThing' ;
                dcterms:title "Edizione di FGrHist 104 [Aristodemo]" ;
                foaf:homepage <http://pietroliuzzo.github.io/Aristodemo/index.html> ;
                dcterms:description "The edition of a papyrus P.Oxy 27.2469, containing a fragment of an historical work by an anonymous author, collected by Felix Jacoby in Die Fragmente der Griechischer Historiker under number 104 with the name of Aristodemus." ;
                dcterms:temporal "101/200" ;
                dcterms:language "grc" ;
                dcterms:subject "papyrus" ;
                .
                
                
                <xsl:for-each-group select="//t:placeName" group-by="@ref">
                    <xsl:sort select="@ref" />
                    <xsl:variable name="rank" select="position()" />
                    <http://pietroliuzzo.github.io/Aristodemo/rdf/places.ttl#papyrus/annotations/<xsl:value-of select="$rank" />>
                    a oa:Annotation ;
                    oa:hasTarget <http://pietroliuzzo.github.io/Aristodemo/rdf/places.ttl#papyrus> ;
                    oa:hasBody <<xsl:value-of select="normalize-space(@ref)"/>> ;
                    oa:annotatedAt "<xsl:value-of select="current-dateTime()"/>"^^xsd:date ;
                    .
                </xsl:for-each-group>
                -->
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
</xsl:stylesheet>