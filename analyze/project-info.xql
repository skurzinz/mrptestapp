xquery version "3.1";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace repo="http://exist-db.org/xquery/repo";
import module namespace app="http://www.digital-archiv.at/ns/templates" at "../modules/app.xql";
import module namespace config="http://www.digital-archiv.at/ns/config" at "modules/config.xqm";
declare option exist:serialize "method=json media-type=text/javascript content-type=application/json";


let $description := doc(concat($config:app-root, "/repo.xml"))//repo:description/text()
let $authors := normalize-space(string-join(doc(concat($config:app-root, "/repo.xml"))//repo:author//text(), ', '))
let $map := map{
    "title": "DSEBAEAPP",
    "subtitle": "Digital Scholarly Editions Base Application",
    "author": $authors,
    "description": $description,
    "github": "https://github.com/KONDE-AT/mrptestapp",
    "purpose_de": "Ziel von mrptestapp ist die Publikation von Forschungsdaten.",
    "purpose_en": "The purpose of mrptestapp is the publication of research data.",
    "app_type": "digital-edition",
    "base_tech": "eXist-db",
    "framework": "Digital Scholarly Editions Base Application"
}
return 
        $map