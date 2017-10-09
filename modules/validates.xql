xquery version "3.0";

module namespace validates="http://www.digital-archiv.at/ns/mp-app/validates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="http://www.digital-archiv.at/ns/mp-app/templates" at "app.xql";
import module namespace config="http://www.digital-archiv.at/ns/mp-app/config" at "config.xqm";
import module namespace functx = "http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace repo="http://exist-db.org/xquery/repo";


(:~
: The validates:is-tag-used returns a HTML td element containing TRUE or FALSE if an element is used in an xml document. 
:)
declare function validates:is-tag-used($tag as xs:string, $taglist) as node(){
    let $test :=if (functx:is-value-in-sequence($tag, $taglist))
        then
            <td bgcolor="#00FF00">TRUE</td>
        else
            <td bgcolor="#FF0000">FALSE</td>
    return $test
};

(:~
 : returns all documents stored in 'resources/schemas/' as html option list
:)
declare function validates:fetch_schemas($node as node(), $model as map(*)) {
for $x in collection(concat($config:app-root, '/resources/schemas/'))
return
                        <option value="{app:getDocName($x)}">{app:getDocName($x)}</option>
};

(:~
 : iterates over TEI-documents and validates them. Returns valdiation station and optionally error msgs.
:)
declare function validates:toc_validates($node as node(), $model as map(*)) {
if (request:get-parameter("schema", "") != "")
then
let $schema := xs:anyURI(concat($config:app-root, '/resources/schemas/',(request:get-parameter("schema", ""))))
let $directory := request:get-parameter("directory", "editions")
let $collection := concat($config:app-root, '/data/', $directory, '/')
    for $doc in collection($collection)//tei:TEI
    let $xml := root($doc)
    let $validation_report := validation:validate-report($doc, $schema)
    let $result :=              
        if (contains($validation_report//status/text(),"invalid"))
            then
                <tr>
                    <td>
                        <a href="{concat(app:hrefToDoc($doc),'&amp;directory=',$directory)}">{app:getDocName($doc)}</a>
                    </td>
                    <td bgcolor="#FF0000">failed</td>
                    <td><strong><abbr title="only the first three errors are displayed">Oh no!</abbr></strong><br />{for $x in validation:validate-report($doc, $schema)//message[position() lt 4]
                        return 
                            <li>line {data($x/@line)}: {$x/text()}</li>}
                    </td>
                    <td>
                        {$validation_report//duration}
                    </td>
                </tr>
            else 
                <tr>
                    <td>
                        <a href="{concat(app:hrefToDoc($doc),'&amp;directory=',$directory)}">{app:getDocName($doc)}</a>
                    </td>
                    <td bgcolor="#00FF00">passed</td>
                    <td>no problem, well done!</td>
                    <td>{$validation_report//duration}</td>
                </tr>
                
order by $xml
return
$result
else
<tr>Please select a schema</tr>
};

(:~
 : iterates over TEI-documents and gives an overview of the used TEI-tags.
:)
declare function validates:tag_usage($node as node(), $model as map(*)) {
for $doc in collection(concat($config:app-root, '/data/editions/'))
let $part := request:get-parameter("part-to-analyze", "")
let $tags := 
    if ($part eq "header")
        then $doc//tei:teiHeader//*
    else if ($part eq "body")
        then $doc//tei:body//*
    else
        $doc//tei:TEI//*   
let $tag_names :=  for $x in $tags return name($x)
let $distinct_names := distinct-values($tag_names)
return 
<tr>
    <td>
        <a href="{concat(replace(concat($config:app-root, '/pages/'), '/db/', '/exist/'),app:hrefToDoc($doc, "statistics.xsl"))}">{app:getDocName($doc)}</a>
    </td>
    <td>{count($distinct_names)}</td>
    {validates:is-tag-used("rs", $distinct_names)}
    {validates:is-tag-used("persName", $distinct_names)}
    {validates:is-tag-used("placeName", $distinct_names)}
    {validates:is-tag-used("note", $distinct_names)}
</tr>
};

(:~
 : Takes a tag name and gives an overview of it's usage in the corpus as well the related attributes and values.
:)
declare function validates:tag_usage_attributes($node as node(), $model as map(*)) {
if (request:get-parameter("tag-of-question", "") eq "") 
then
<p>please type in a tag's name</p>
else
let $tag_name := request:get-parameter("tag-of-question", "")
let $table := 
<table>
    <thead>
        <tr>
            <th>filename</th>
            <th>attributes | values</th>
        </tr>
    </thead>
    <tbody>
    {for $doc in collection(concat($config:app-root, '/data/editions/'))[.//*[name()=$tag_name]]
    let $tags := $doc//*[name()=$tag_name]
    let $tag_names :=  for $x in $tags[position() lt 4] 
    return <tag>
                <name>{name($x)}</name>
                {for $y in $x/@* return 
                    <attr>
                        <name>{name($y)}</name>
                        <value>{string($y)}</value>
                    </attr>}
            </tag>
    
    return
        <tr>
            <td>
                <a href="{concat(replace(concat($config:app-root, '/pages/'), '/db/', '/exist/'),app:hrefToDoc($doc, "statistics.xsl"))}">{app:getDocName($doc)}</a>
            </td>
            <td><ul class="list-unstyled">{for $x in $tag_names/attr return <li>&lt;{$tag_name}&#32;{$x/name}="{$x/value}"&gt; </li>}</ul></td>
        </tr>
    }
    </tbody>
</table>
return
$table

};