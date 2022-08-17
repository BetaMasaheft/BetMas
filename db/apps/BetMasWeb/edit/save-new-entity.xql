xquery version "3.0" encoding "UTF-8";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";   

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes";

declare variable $collection as xs:string := request:get-parameter('collection', ());
declare variable $suffix := request:get-parameter('suffix', ());
declare variable $title := request:get-parameter('title', ());
declare variable $keyword := request:get-parameter('keywords', ());
declare variable $occupation := request:get-parameter('occupation', ());
declare variable $nationality := request:get-parameter('nationality', ());
declare variable $ins := request:get-parameter('institution', ());
declare variable $idno := request:get-parameter('idno', ());
declare variable $sex := request:get-parameter('gender', ());
declare variable $relations := request:get-parameter('relations', ());
declare variable $msParts := request:get-parameter('msParts', ());
declare variable $attested := request:get-parameter('attested', ());
declare variable $birth := request:get-parameter('birth', ());
declare variable $death := request:get-parameter('death', ());
declare variable $floruit := request:get-parameter('floruit', ());
declare variable $note := request:get-parameter('note', ());
declare variable $group := request:get-parameter('group', ());
declare variable $wikidata := request:get-parameter('WD', ());

let $prefix := switch ($collection)
    case 'works'
        return
            <ref><pre>LIT</pre><type>work</type></ref>
    case 'studies'
        return
            <ref><pre>STU</pre><type>studies</type></ref>            
    case 'narratives'
        return
            <ref><pre>NAR</pre><type>nar</type></ref>
    case 'persons'
        return
            <ref><pre>PRS</pre><type>pers</type></ref>
    case 'places'
        return
            <ref><pre>LOC</pre><type>place</type></ref>
    case 'institutions'
        return
            <ref><pre>INS</pre><type>ins</type></ref>
    case 'authority-files'
        return
            <ref><pre>AUT</pre><type>auth</type></ref>
    default return
        <ref><pre></pre><type>mss</type></ref>

let $data-collection := $config:data-root || '/' || $collection || '/new'

let $type := $prefix//type/text()

let $Newid :=
if ($collection = 'manuscripts' or $collection = 'authority-files') then
    $suffix
else
    let $ids := for $x in switch2:collectionVar($collection)//t:TEI/@xml:id
    return
        analyze-string($x, '([A-Z]+)(\d+)(\w+)')
    let $numericvalue := for $id in $ids//s:group[@nr = '2']
    return
        $id
    let $maxid := max($numericvalue) + 1
    let $formattedID := if($maxid > 999) then ($maxid) else format-number($maxid, '0000')
    return
        ($prefix//pre/text() || $formattedID || replace($suffix, ' ', '_'))
return
    if (collection(concat($config:data-root, '/', $collection))//id($Newid)) then
        (
        <html>
            
            <head>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <link
                    rel="shortcut icon"
                    href="resources/images/minilogo.ico"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                <link
                    rel="stylesheet"
                    href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="resources/css/style.css"/>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                
                <title>This id already exists!</title>
            </head>
            <body>
                <div
                    id="confirmation">
                    <p>Dear {sm:id()//sm:real/sm:username/string()}, unfortunately <span
                            class="lead">{$Newid}</span> already exists!
                        Please, hit the button below and try a different id.</p>
                   <div class="btn-group"> 
                   <a href="/newentry.html?collection={$collection}"
                        class="btn btn-success">Back to create item</a>
                    <a href="/{$collection}/list"
                        class="btn btn-info">or back to list</a></div>
                </div>
            
            </body>
        </html>
        )
    else
        let $editor := editors:editorNames(sm:id()//sm:real/sm:username/string())
               (: get the form data that has been "POSTed" to this XQuery :)
    let $item :=
    document {
        processing-instruction xml-model {
            'href="https://raw.githubusercontent.com/BetaMasaheft/schema/master/tei-betamesaheft.rng" 
schematypens="http://relaxng.org/ns/structure/1.0"'
        },
        processing-instruction xml-model {
            'href="https://raw.githubusercontent.com/BetaMasaheft/schema/master/tei-betamesaheft.rng" 
type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"'
        },
        <TEI
            xmlns="http://www.tei-c.org/ns/1.0"
            xml:id="{$Newid}"
            xml:lang="en"
            type="{$type}">
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                   { element 
                        title{ if($type = 'work') then attribute xml:lang {'gez'} else (),
                        if($type = 'work') then attribute xml:id {'t1'} else (),
                           $title}}
                        <editor
                            role="generalEditor"
                            key="AB"/>
                        <editor
                            key="{$editor}"/>
                        <funder>Akademie der Wissenschaften in Hamburg</funder>
                    </titleStmt>
                    <publicationStmt>
                        <authority>Hiob-Ludolf-Zentrum für Äthiopistik</authority>
                        <publisher>Die Schriftkultur des christlichen Äthiopiens und Eritreas: Eine multimediale
                            Forschungsumgebung / Beta maṣāḥǝft</publisher>
                        <pubPlace>Hamburg</pubPlace>
                        <availability>
                            <licence
                                target="http://creativecommons.org/licenses/by-sa/4.0/"> This file is
                                licensed under the Creative Commons Attribution-ShareAlike 4.0. </licence>
                        </availability>
                    </publicationStmt>
                    <sourceDesc>
                        {
                            if ($ins != '')
                            then
                                <msDesc
                                    xml:id="ms">
                                    <msIdentifier>
                                        <repository
                                            ref="{$ins}"/>
                                        <idno>{$idno}</idno>
                                    </msIdentifier>
                                  {if ( $msParts != '') then (if (xs:integer($msParts)=1) 
                                  then ( <msContents>
                                        <summary>
                                        </summary>
                                        <msItem xml:id="ms_i1">
                                        <locus from=""/>
                                       <title type="" ref=""/>
                                       <textLang mainLang="gez"/> 
                                       </msItem>
                                    </msContents>,
                                    <physDesc>
                        <objectDesc form="Codex">
                            <supportDesc>
                                <support>
                                    <material key="parchment"/>
                                </support>
                                <extent>
                                    <measure unit="leaf"></measure>
                                    <dimensions type="outer" unit="mm">
                                        <height></height>
                                        <width></width>
                                        <depth/>
                                    </dimensions>
                                </extent>
                                
                            </supportDesc>
                            <layoutDesc>
                                <layout >
                                    <locus from="" to=""/>
                                </layout>
                                <layout >
                                    <locus from="" to=""/>
                                </layout>
                            </layoutDesc>
                        </objectDesc>
                        <handDesc>
                            <handNote xml:id="h1" script="Ethiopic">
                                <date notAfter=""/>
                                <desc></desc>
                            </handNote>
                        </handDesc>
                        <decoDesc>
                            <decoNote xml:id="d1">
                                <locus target=""/>
                               
                            </decoNote>
                        </decoDesc>
                        <bindingDesc>
                            <binding contemporary="false" xml:id="binding">
                                <decoNote xml:id="b1"> </decoNote>
                                <decoNote xml:id="b2" type="bindingMaterial">
                                    <material key="leather"/>
                                </decoNote>
                            </binding>
                        </bindingDesc>
                        </physDesc>,  
                        <history>
                     <origin>
                        <origPlace><placeName corresp=""/></origPlace>
                     </origin>
                     <provenance>
                     </provenance>
                  </history>,
                  <additional>
                     <adminInfo>
                        <recordHist>
                           <source>
                              <listBibl type="catalogue">
                                 <bibl></bibl>
                              </listBibl>
                           </source>
                        </recordHist>
                     </adminInfo>
                   </additional>
                                    
                                    )
                                    else (
                                    for $mP in 1 to xs:integer($msParts)
                                    return <msPart
                                        xml:id="p{$mP}">
                                        <msIdentifier>
                                            <idno>
                                            </idno>
                                        </msIdentifier>
                                        <msContents>
                                            <msItem
                                                xml:id="p{$mP}_i1"
                                                class="content">
                                                <locus from=""/>
                                       <title type="" ref=""/>
                                       <textLang mainLang="gez"/> 
                                            </msItem>
                                            <msItem
                                                xml:id="p{$mP}_i2"
                                                class="content">
                                                <locus from=""/>
                                       <title type="" ref=""/>
                                       <textLang mainLang="gez"/> 
                                            </msItem>
                                            
                                            
                                        </msContents>
                                        <physDesc>
                        <objectDesc form="Codex">
                            <supportDesc>
                                <support>
                                    <material key="parchment"/>
                                </support>
                                <extent>
                                    <measure unit="leaf"></measure>
                                    <dimensions type="outer" unit="mm">
                                        <height></height>
                                        <width></width>
                                        <depth/>
                                    </dimensions>
                                </extent>
                                
                            </supportDesc>
                            <layoutDesc>
                                <layout >
                                    <locus from="" to=""/>
                                </layout>
                                <layout >
                                    <locus from="" to=""/>
                                </layout>
                            </layoutDesc>
                        </objectDesc>
                        <handDesc>
                            <handNote xml:id="h1" script="Ethiopic">
                                <date notAfter=""/>
                                <desc></desc>
                            </handNote>
                        </handDesc>
                        <decoDesc>
                            <decoNote xml:id="d1">
                                <locus target=""/>
                               
                            </decoNote>
                        </decoDesc>
                        <bindingDesc>
                            <binding contemporary="false" xml:id="binding">
                                <decoNote xml:id="b1"> </decoNote>
                                <decoNote xml:id="b2" type="bindingMaterial">
                                    <material key="leather"/>
                                </decoNote>
                            </binding>
                        </bindingDesc>
                        </physDesc>
                         <history>
                     <origin>
                        <origPlace><placeName corresp=""/></origPlace>
                     </origin>
                     <provenance>
                     </provenance>
                  </history>
                  <additional>
                     <adminInfo>
                        <recordHist>
                           <source>
                              <listBibl type="catalogue">
                                 <bibl></bibl>
                              </listBibl>
                           </source>
                        </recordHist>
                     </adminInfo>
                   
                  </additional>
                                    
                                    </msPart>)
                                    
                                ) else()      }
                              </msDesc>
                            else
                                <p/>
                        }
                    </sourceDesc>
                
                </fileDesc>
                <encodingDesc>
                    <p>A digital born TEI file</p>
                </encodingDesc>
                <profileDesc>
                    <creation></creation>
                    <abstract>
                        <p>
                        
                        </p>
                    </abstract>
                    {
                        if ($keyword != '' and $collection != 'persons' and $collection != 'places' and $collection != 'institutions') then
                            <textClass>
                                <keywords>
                                    {
                                        for $k in $keyword
                                        return
                                            <term
                                                key="{$k}"/>
                                    }
                                </keywords>
                            </textClass>
                        else
                            ()
                    }
                    <langUsage>
                        <language
                            ident="en">English</language>
                        <language
                            ident="gez">Gǝʿǝz</language>
                    </langUsage>
                </profileDesc>
                <revisionDesc>
                    <change
                        who="{$editor}"
                        when="{format-date(current-date(), "[Y0001]-[M01]-[D01]")}">Created entity</change>
                </revisionDesc>
            </teiHeader>
            <text>
                <body>
                    {
                        if ($collection = 'places' or $collection = 'institutions')
                        then
                            <listPlace>{
                                    element place {
                                            if($wikidata = '') then () else attribute sameAs {'wd:'||$wikidata},
                                       if(exists($keyword)) then attribute type {
                                            for $k in $keyword
                                            return
                                                string-join($k, '')
                                        } else (),
                                        if ($collection = 'institutions') then
                                            (attribute subtype {'institution'})
                                        else
                                            (),
                                        element placeName {$title}
                                    }
                                }
                                {if(exists($relations) or $attested != '') then <listRelation>
                                {
                                           ( for $r in $relations
                                            return
                                                element relation {
                                                    attribute name {$r},
                                                    attribute active {$Newid},
                                                    attribute passive {}
                                                },
                                                if ($attested != '') then for $a in $attested
                                                return
                                                    element relation {
                                                        attribute name {'lawd:hasAttestation'},
                                                        attribute active {$Newid},
                                                        attribute passive {$a}
                                                    } else ())
                                        }
                                </listRelation> else ()}
                            </listPlace>
                        else
                            if ($collection = 'persons')
                            then
                                <listPerson>
                                    {
                                        element {if($group='group') then 'personGrp' else 'person'}  {
                                        
                                            if($wikidata = '') then () else attribute sameAs {$wikidata},
                                            if(exists($sex)) then attribute sex {$sex} else (),
                                            element persName {
                                                attribute xml:lang {'gez'},
                                                attribute xml:id {'n1'},
                                                $title
                                            },
                                            element persName {
                                                attribute xml:lang {'gez'},
                                                attribute type {'normalized'},
                                                attribute corresp {'#n1'}
                                            },
                                           if($keyword = '') then () else   element faith {
                                                attribute type {
                                                    for $k in $keyword
                                                    return
                                                        $k
                                                }
                                            },
                                            if($occupation = '') then () else element occupation {
                                                attribute type {
                                                    for $k in $occupation
                                                    return
                                                        $k
                                                }
                                            },
                                             if($nationality = '') then () else element nationality {
                                                attribute type {
                                                    for $k in $nationality
                                                    return
                                                        $k
                                                }
                                            },
                                            element birth {$birth},
                                            element death {$death},
                                            element floruit {$floruit}
                                            
                                        },
                                        if(exists($relations) or  $attested != '') then (
                                        element listRelation {
                                            (if ($attested = '') then
                                                ()
                                            else
                                                (for $a in $attested
                                                return
                                                    element relation {
                                                        attribute name {'lawd:hasAttestation'},
                                                        attribute active {$Newid},
                                                        attribute passive {$a}
                                                    }),
                                             if ($relations = '') then
                                                ()
                                            else
                                                (
                                            for $r in $relations
                                            return
                                                element relation {
                                                    attribute name {$r},
                                                    attribute active {$Newid},
                                                    attribute passive {}
                                                }
                                            ))
                                        }) else ()
                                        
                                    }
                                </listPerson>
                            
                            else
                                <div
                                    type="bibliography">
                                    {if(exists($relations)  and $attested != '') then <listRelation>
                                        {(if ($attested = '') then
                                                ()
                                            else
                                                (for $a in $attested
                                                return
                                                    element relation {
                                                        attribute name {'lawd:hasAttestation'},
                                                        attribute active {$Newid},
                                                        attribute passive {$a}
                                                    }),
                                             if ($relations = '') then
                                                ()
                                            else
                                                (
                                            for $r in $relations
                                            return
                                                element relation {
                                                    attribute name {$r},
                                                    attribute active {$Newid},
                                                    attribute passive {}
                                                }
                                            ))
                                        }
                                    </listRelation> 
                                    else if(exists($relations)) then (
                                    <listRelation>
                                        {if ($relations = '') then
                                                ()
                                            else
                                                (
                                            for $r in $relations
                                            return
                                                element relation {
                                                    attribute name {$r},
                                                    attribute active {$Newid},
                                                    attribute passive {}
                                                }
                                            )}
                                        </listRelation>
                                    ) else ()}
                                </div>
                    }
                    {comment {$note}}
               
               </body>
            </text>
        </TEI>
    }
    
    (: store the filename :)
    let $file := concat($Newid, '.xml')

    (:confirmation page with instructions for editors:)
    return
    try {
        
    (: create the new file with a still-empty id element :)
    let $store := xmldb:store($data-collection, $file, $item)
(:    permissions:)
   let $assigntoGroup := sm:chgrp(xs:anyURI($data-collection||'/'||$file), 'Cataloguers')
   let $setpermissions := sm:chmod(xs:anyURI($data-collection||'/'||$file), 'rwxrwxr-x')
    return
        <html>
            
            <head>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <link
                    rel="shortcut icon"
                    href="resources/images/minilogo.ico"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                <link
                    rel="stylesheet"
                    href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="resources/css/style.css"/>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                
                <title>Save Confirmation</title>
            </head>
            <body>
                <div id="confirmation" class="container">
                    <div class="jumbotron">
                    <p
                        class="lead">Thank you very much {sm:id()//sm:real/sm:username/string()}!</p>
                    <p>
                        <span
                            class="lead">{$Newid}</span> has been saved!</p>
                    <p>But <span
                            class="label label-warning confirmationwarning">WAIT!</span> you are <span
                            class="label label-warning confirmationwarning">not yet done</span>...</p>
                    <p>Download the file in your BetMas project's <span
                            class="lead">{$collection}</span> folder under <span
                            class="lead">new</span>.<br/>
                        <a
                            id="downloaded"
                            href="/{$file}"
                            download="{$file}"
                            class="btn btn-primary"><i
                                class="fa fa-download"
                                aria-hidden="true"></i> Download</a><br/>
                                open it up and check it is valid and complete. <br/>
                                <span
                            class="label label-warning confirmationwarning">DO THIS!</span><br/>
                        <b>commit it and sync to GIT</b>.</p>
                    <a
                        href="/newentry.html?collection={$collection}">create another entry</a>
                </div>
                </div>
                
                <script
                    type="text/javascript"
                    src="resources/js/confirmonleave.js"/>
            </body>
        </html>}
        catch * {
        <html>
            
            <head>
                <link
                    rel="shortcut icon"
                    href="resources/images/favicon.ico"/>
                <meta
                    name="viewport"
                    content="width=device-width, initial-scale=1.0"/>
                <link
                    rel="shortcut icon"
                    href="resources/images/minilogo.ico"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="$shared/resources/css/bootstrap-3.0.3.min.css"/>
                <link
                    rel="stylesheet"
                    href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>
                <link
                    rel="stylesheet"
                    type="text/css"
                    href="resources/css/style.css"/>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-1.11.0.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
                <script
                    xmlns=""
                    type="text/javascript"
                    src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/loadsource.js"></script>
                <script
                    type="text/javascript"
                    src="$shared/resources/scripts/bootstrap-3.0.3.min.js"></script>
                
                <title>Save Confirmation</title>
            </head>
            <body>
                <div id="confirmation" class="container">
                    <div class="jumbotron">
                    <p
                        class="lead">Thank you very much {sm:id()//sm:real/sm:username/string()} for trying to store a new file!</p>
                    <p> Unfortunately
                        <span
                            class="lead">{$Newid}</span> could not be saved</p>
                    <p>This is the first error which occurred {$err:description}, feel free to copy it and send it to info@betamasaheft.eu.</p>
                    <a
                        href="/newentry.html?collection={$collection}">create another entry</a>
                </div>
                </div>
            </body>
        </html>
        }