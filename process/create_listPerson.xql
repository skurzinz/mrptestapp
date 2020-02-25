xquery version "3.0";
declare namespace functx = "http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://www.digital-archiv.at/ns/config" at "../modules/config.xqm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $editions := collection(concat($config:app-root, '/data/editions'))

let $persons :=  subsequence($editions//tei:listPerson[@type='attendants']//tei:persName, 1, 10000000000)
(:for $x in $persons:)
(:    return $x:)
let $listPerson := 

<listPerson>{
    for $person in $persons
        let $type := 'person'
        let $namestring := translate(string-join($person//text(), ' '), '()', '')
        let $parts := tokenize($namestring, ' ')
        let $nr_parts := count($parts)
        let $name := if ($nr_parts = 1)
            then 
                $parts[1]
            else if (string-length(normalize-space($parts[1])) = 2) 
                then string-join(($parts[1], $parts[2]), ' ')
            else
                $parts[1]
        let $string := if ($name)
            then
                $name
            else
                "some error with: "||$person//text()
        let $xmlID := 'person_'||util:hash($string, 'md5')
        let $ref := '#'||$xmlID
        let $addedRef := update insert attribute ref {$ref} into $person
        let $rmkey := update delete $person/@key
        group by $xmlID
        where $string != ''
        return 
            <person xml:id="{$xmlID}">
                <persName>
                    <surname>{$string[1]}</surname>
                </persName>
            </person>
}</listPerson>

return $listPerson