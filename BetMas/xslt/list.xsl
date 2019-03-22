<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>
    <xsl:template match="/">
        <div xmlns="http://www.w3.org/1999/xhtml" data-template="templates:surround" data-template-with="templates/list.html" data-template-at="content">
            <div class="w3-container">
                <div class="w3-responsive">
                    <table class="w3-table w3-hoverable" id="completeList">
                        <thead>
                            <tr>
                                <td>id</td>
                                <td>type</td>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each select="//exist:resource">
                                <tr>
                                    <td>
                                        <a href="{substring-before(@name, '.xml')}">
                                            <xsl:value-of select="document(concat('../data/authority-files/',@name))//t:TEI//t:titleStmt/t:title/text()"/>
                                        </a>
                                    </td>
                                    <td>
                                        <xsl:value-of select="document(concat('../data/authority-files/',@name))//t:TEI/@type"/>
                                    </td>
                                </tr>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>