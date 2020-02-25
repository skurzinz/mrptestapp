xquery version "3.0";

import module namespace config="http://www.digital-archiv.at/ns/mrptestapp/config" at "config.xqm";

(:declare option exist:serialize "method=xml media-type=text/xml";
:)
let $id := request:get-parameter("id", ())
let $path := 'data/editions/docx/'
(:let $work := collection($config:data)//id($id)
let $entries := local:work2epub($id, $work)
:)
return
        response:stream-binary(
            concat($path, $id),
            'application/octet-stream',
            'download.docx'
            )
            
    
    