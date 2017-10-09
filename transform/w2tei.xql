xquery version "3.0";

module namespace w2tei="http://www.digital-archiv.at/ns/mp-app/w2tei";
import module namespace config="http://www.digital-archiv.at/ns/mp-app/config" at "../modules/config.xqm";

declare function w2tei:selectStylesheet($node as node(), $model as map(*)) {
    
    let $stylelist := doc($config:app-root||'/transform/adds.xml')
    
    for $file in $stylelist//entry
		return
		  <option value="{$file/@file}">{$file/@label}</option>
};