<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
  <!--  <xsl:template match="t:listRelation | t:listBibl[@type = 'relations']">
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title">Graph of the relations declared for this entity.</h4>
                </div>
                <div class="modal-body">
                    <div id="BetMasRelView" class="container"/>
                    <p>In the graphic visualization different colors indicate different types of
                        entities:</p>
                    <ul>
                        <li>Lime for Persons </li>
                        <li>Green for Institutions </li>
                        <li>Yellow for Places </li>
                        <li>Red for Works </li>
                        <li>Pink for Narrative Units </li>
                        <li>Blue for Manuscripts </li>
                    </ul>
                    <div class="table-responsive">
                        <table class="table table-hover" width="100%">
                            <caption>Table visualization of each relation</caption>
                            <thead>
                                <tr>
                                    <th>Subject</th>
                                    <th>Relation</th>
                                    <th>Object</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody>
                                <xsl:for-each select="t:relation">
                                    <tr>
                                        <th>
                                            <xsl:value-of select="@active"/>
                                        </th>
                                        <th>
                                            <xsl:value-of select="@name"/>
                                        </th>
                                        <th>
                                            <xsl:value-of select="@passive"/>
                                        </th>
                                        <th>
                                            <xsl:apply-templates select="t:desc"/>
                                        </th>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                    <script type="text/javascript">
            // create an array with nodes
            var nodes = new vis.DataSet([
            <xsl:variable name="list">
                            <list>
                                <xsl:for-each select="t:relation">
                                    
<!-\-                    this needs to stay here in order to process all the relation nodes in one time, sequence them and remove doubles-\->

                    <!-\-                    pick up node labels from files for @active-\->
                    
                    <!-\-needs more cases for multiple entries in active and passive-\->
                                    <xsl:for-each select="@active">
                                        <xsl:variable name="filename" select="substring-after(., '#')"/>
                                        <xsl:variable name="id">
                                            <xsl:choose>
                                                <xsl:when test="starts-with($filename, 'INS') or starts-with($filename, 'PRS') or starts-with($filename, 'LOC') or starts-with($filename, 'LIT') or starts-with($filename, 'NAR')">
                                                    <xsl:analyze-string select="$filename" regex="((\w{{3}})(\d+))(\w+)">
                                                        <xsl:matching-substring>
                                                            <xsl:value-of select="regex-group(1)"/>
                                                        </xsl:matching-substring>
                                                        <xsl:non-matching-substring>
                                                            <xsl:value-of select="."/>
                                                        </xsl:non-matching-substring>
                                                    </xsl:analyze-string>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$filename"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="path" select="                                                 if ($filename = document('../data/authority-files/taxonomy.xml')//t:catDesc) then                                                     'Authority-Files'                                                 else                                                     (if (starts-with($filename, 'PRS')) then                                                         'Persons'                                                     else                                                         (if (starts-with($filename, 'LOC')) then                                                             ('Places')                                                         else                                                             (if (starts-with($filename, 'INS')) then                                                                 ('Institutions')                                                             else                                                                 (if (starts-with($filename, 'LIT')) then                                                                     ('Works')                                                                 else                                                                     (if (starts-with($filename, 'NAR')) then                                                                         ('Narrative')                                                                     else                                                                         ('Manuscripts'))))))"/>
                                        <xsl:variable name="label" select="document(concat('../data/', lower-case($path), '/', $filename, '.xml'))//t:TEI"/>
                                        <li>{id:"<xsl:value-of select="$id"/>", label:"<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">
                                                    <xsl:value-of select="normalize-space($label//t:person/t:persName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[@xml:id = 't1'], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:otherwise>
                                            </xsl:choose>",
color: "<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">lime</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">yellow</xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">green</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">red</xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">pink</xsl:when>
                                                <xsl:otherwise>rgba(97,195,238,0.5)</xsl:otherwise>
                                            </xsl:choose>"},</li>
                                    </xsl:for-each>
       
       
<!-\-       pick up labels from files for @passive -\->
                                    <xsl:for-each select="tokenize(@passive, ' ')">
                                        <xsl:variable name="filename" select="substring-after(., '#')"/>
                                        <xsl:variable name="id">
                                            <xsl:choose>
                                                <xsl:when test="starts-with($filename, 'INS') or starts-with($filename, 'PRS') or starts-with($filename, 'LOC') or starts-with($filename, 'LIT') or starts-with($filename, 'NAR')">
                                                    <xsl:analyze-string select="$filename" regex="((\w{{3}})(\d+))(\w+)">
                                                        <xsl:matching-substring>
                                                            <xsl:value-of select="regex-group(1)"/>
                                                        </xsl:matching-substring>
                                                        <xsl:non-matching-substring>
                                                            <xsl:value-of select="."/>
                                                        </xsl:non-matching-substring>
                                                    </xsl:analyze-string>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$filename"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="path" select="                                                 if ($filename = document('../data/authority-files/taxonomy.xml')//t:catDesc) then                                                     ('Authority-Files')                                                 else                                                     (if (starts-with($filename, 'PRS')) then                                                         ('Persons')                                                     else                                                         (if (starts-with($filename, 'LOC')) then                                                             ('Places')                                                         else                                                             (if (starts-with($filename, 'INS')) then                                                                 ('Institutions')                                                             else                                                                 (if (starts-with($filename, 'LIT')) then                                                                     ('Works')                                                                 else                                                                     (if (starts-with($filename, 'NAR')) then                                                                         ('Narrative')                                                                     else                                                                         ('Manuscripts'))))))"/>
                                        <xsl:variable name="label" select="document(concat('../data/', lower-case($path), '/', $filename, '.xml'))//t:TEI"/>
                                        <li>{id:"<xsl:value-of select="$id"/>", label:"<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">
                                                    <xsl:value-of select="normalize-space($label//t:person/t:persName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[@xml:id = 't1'], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:otherwise>
                                            </xsl:choose>",
                            color: "<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">lime</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">yellow</xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">green</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">red</xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">pink</xsl:when>
                                                <xsl:otherwise>rgba(97,195,238,0.5)</xsl:otherwise>
                                            </xsl:choose>"},</li>
                                    </xsl:for-each>
                
                
                
                    <!-\-       pick up labels from files for @mutual -\->
                                    <xsl:for-each select="tokenize(@mutual, ' ')">
                                        <xsl:variable name="filename" select="substring-after(., '#')"/>
                                        <xsl:variable name="id">
                                            <xsl:choose>
                                                <xsl:when test="starts-with($filename, 'INS') or starts-with($filename, 'PRS') or starts-with($filename, 'LOC') or starts-with($filename, 'LIT') or starts-with($filename, 'NAR')">
                                                    <xsl:analyze-string select="$filename" regex="((\w{{3}})(\d+))(\w+)">
                                                        <xsl:matching-substring>
                                                            <xsl:value-of select="regex-group(1)"/>
                                                        </xsl:matching-substring>
                                                        <xsl:non-matching-substring>
                                                            <xsl:value-of select="."/>
                                                        </xsl:non-matching-substring>
                                                    </xsl:analyze-string>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$filename"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:variable>
                                        <xsl:variable name="path" select="                                                 if ($filename = document('../data/authority-files/taxonomy.xml')//t:catDesc) then                                                     ('Authority-Files')                                                 else                                                     (if (starts-with($filename, 'PRS')) then                                                         ('Persons')                                                     else                                                         (if (starts-with($filename, 'LOC')) then                                                             ('Places')                                                         else                                                             (if (starts-with($filename, 'INS')) then                                                                 ('Institutions')                                                             else                                                                 (if (starts-with($filename, 'LIT')) then                                                                     ('Works')                                                                 else                                                                     (if (starts-with($filename, 'NAR')) then                                                                         ('Narrative')                                                                     else                                                                         ('Manuscripts'))))))"/>
                                        <xsl:variable name="label" select="document(concat('../data/', lower-case($path), '/', $filename, '.xml'))//t:TEI"/>
                                        <li>{id:"<xsl:value-of select="$id"/>", label:"<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">
                                                    <xsl:value-of select="normalize-space($label//t:person/t:persName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">
                                                    <xsl:value-of select="normalize-space($label//t:place/t:placeName[1])"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[@xml:id = 't1'], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="normalize-space(replace($label//t:titleStmt/t:title[1], '"', ' '))"/>
                                                </xsl:otherwise>
                                            </xsl:choose>",
                            color: "<xsl:choose>
                                                <xsl:when test="starts-with($filename, 'PRS')">lime</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LOC')">yellow</xsl:when>
                                                <xsl:when test="starts-with($filename, 'INS')">green</xsl:when>
                                                <xsl:when test="starts-with($filename, 'LIT')">red</xsl:when>
                                                <xsl:when test="starts-with($filename, 'NAR')">pink</xsl:when>
                                                <xsl:otherwise>rgba(97,195,238,0.5)</xsl:otherwise>
                                            </xsl:choose>"},</li>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </list>
                        </xsl:variable>
            
<!-\-
                            prints each of the strings above with id and label only once//-\->
                        <xsl:for-each select="distinct-values($list//li)">
                            <xsl:value-of select="."/>
                        </xsl:for-each>
               
           
            ]);
            
     <!-\-
                            edges//-\->      
            var edges = new vis.DataSet([
            
            <xsl:apply-templates mode="graphedges" select="//t:relation"/>
            ]);
            
            
            
            // create a network
            var container = document.getElementById('BetMasRelView');
            var directionInput = "LR";
            var layoutMethod = "hubsize";
            
            var data = {
                     nodes: nodes,
                     edges: edges
            };
            
            var options = {
            fit: true,
                    autoResize: true,
                    height: '100%',
                    width: '100%',
                    layout:{
                            hierarchical: {
                                direction: directionInput,
                                sortMethod: layoutMethod
                                     }
                                     },
                    nodes: {
                                   shadow:true
                                    },
                    edges: {
                            smooth: {
                                enabled: true,
                                type: "dynamic",
                                //   roundness: 0.7
                                        },
                                },
                <!-\-    physics: {
                    hierarchicalRepulsion: {
                                 centralGravity: 0.0,
                                 springLength: 100,
                                 springConstant: 0.01,
                                  nodeDistance: 120,
                                 damping: 0.09
                    },
                    maxVelocity: 50,
                    minVelocity: 0.1
                   
                                    },-\->
<!-\-                    interaction: {
                                    navigationButtons: true,
                                    keyboard: true
                                    }-\->
            };
            
            
            var network = new vis.Network(container, data, options);
            
        </script>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template mode="graphedges" match="t:relation">
        <xsl:variable name="edgelabel" select="@name"/>
        <xsl:if test="@active">
            <!-\-needs more cases for multiple entries in active and passive-\->
            <xsl:variable name="activeid">
                <xsl:variable name="filenameac" select="substring-after(@active, '#')"/>
                <xsl:choose>
                    <xsl:when test="starts-with($filenameac, 'INS') or starts-with($filenameac, 'PRS') or starts-with($filenameac, 'LOC') or starts-with($filenameac, 'LIT') or starts-with($filenameac, 'NAR')">
                        <xsl:analyze-string select="$filenameac" regex="((\w{{3}})(\d+))(\w+)">
                            <xsl:matching-substring>
                                <xsl:value-of select="regex-group(1)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$filenameac"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="passiveid">
                <list>
                    <xsl:for-each select="tokenize(normalize-space(@passive), '#')">
                        <xsl:variable name="name" select="                                 if (contains(., '#')) then                                     substring-after(., '#')                                 else                                     ."/>
                        <value>
                            <xsl:choose>
                                <xsl:when test="starts-with($name, 'INS') or starts-with($name, 'PRS') or starts-with($name, 'LOC') or starts-with($name, 'LIT') or starts-with($name, 'NAR')">
                                    <xsl:analyze-string select="." regex="((\w{{3}})(\d+))(\w+)">
                                        <xsl:matching-substring>
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                        <xsl:non-matching-substring>
                                            <xsl:value-of select="."/>
                                        </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$name"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </value>
                    </xsl:for-each>
                </list>
            </xsl:variable>
            <xsl:for-each select="$passiveid//value[text()]"> {from: "<xsl:value-of select="$activeid"/>", to: "<xsl:value-of select="replace(., ' ', '')"/>" ,
                    label:"<xsl:value-of select="$edgelabel"/>"}, </xsl:for-each>
        </xsl:if>
        <xsl:if test="@mutual">
            <xsl:variable name="mutualid">
                <list>
                    <xsl:for-each select="tokenize(normalize-space(@mutual), ' ')">
                        <value>
                            <xsl:variable name="filename" select="                                     if (contains(., '#')) then                                         substring-after(., '#')                                     else                                         ."/>
                            <xsl:choose>
                                <xsl:when test="starts-with($filename, 'INS') or starts-with($filename, 'PRS') or starts-with($filename, 'LOC') or starts-with($filename, 'LIT') or starts-with($filename, 'NAR')">
                                    <xsl:analyze-string select="." regex="((\w{{3}})(\d+))(\w+)">
                                        <xsl:matching-substring>
                                            <xsl:value-of select="regex-group(1)"/>
                                        </xsl:matching-substring>
                                        <xsl:non-matching-substring>
                                            <xsl:value-of select="                                                     if (contains(., '#')) then                                                         substring-after(., '#')                                                     else                                                         ."/>
                                        </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="                                             if (contains($filename, '#')) then                                                 substring-after($filename, '#')                                             else                                                 $filename"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </value>
                    </xsl:for-each>
                </list>
            </xsl:variable>
            <xsl:for-each select="$mutualid//value[text()]">
                <xsl:variable name="from" select="replace(., ' ', '')"/>
                <xsl:for-each select="$mutualid//value[. != $from]"> {from: "<xsl:value-of select="$from"/>", to: "<xsl:value-of select="replace(., ' ', '')"/>" ,
                        label:"<xsl:value-of select="$edgelabel"/>"}, </xsl:for-each>

<!-\-value: 3, can be used as well in the edges and be rendered as tickness of the connection-\->

                <!-\-needs more cases for multiple entries-\->
                <!-\-  <xsl:if test="$mutualid/t:temp[position()>2]">
            {from: "<xsl:value-of select="$mutualid/t:temp[position()=1]"/>", to: "<xsl:value-of
                select="$mutualid/t:temp[position()=2]"/>" , label:"<xsl:value-of select="@name"/>"},
        </xsl:if>-\->
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
  -->
    <xsl:template match="t:desc">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <xsl:include href="VARIAsmall.xsl"/><!--includes many templates which don't do much but are all used-->
    <xsl:include href="locus.xsl"/>
    <xsl:include href="bibl.xsl"/>
    <xsl:include href="origin.xsl"/>
    <xsl:include href="date.xsl"/>
    <xsl:include href="ref.xsl"/>
    <xsl:include href="persName.xsl"/>
    <xsl:include href="placeName.xsl"/>
    <xsl:include href="title.xsl"/>
</xsl:stylesheet>