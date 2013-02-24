# Annotation to Markdown

A Ruby script to extract eBooks annotations from your eReader device to Markdown files, ready to be published with Jekyll.

Built for [cdrc](https://github.com/cdrc) who uses it with his Cybook Odyssey eReader.

## Usage

Download the script:

    $ git clone git://github.com/sphax3d/annotation_to_markdown.git
    $ cd annotation_to_markdown

Define some parameters in the script:

- `XML_DIRECTORY` is the source directory of your eBooks annotations on the eReader device.
- `MD_DRECTORY` is the destination directory of the extracted annotations in Markdown.
- `MD_TEMPLATE` is the template of the annotation files in Markdown. The default template is used to publish a quote with Jekyll.

Create the destination directory of the annotations if necessary:

    $ mkdir markdown-annotations

Plug your device and launch the script:

    $ ruby annotation_to_markdown.rb

Check out your destination directory !

Report any issues at https://github.com/sphax3d/annotation_to_markdown/issues

Contributions are welcome, and appreciated.

## Supported devices

- Cybook Odyssey eReader.

## To-do list

- Improve classes API
- Write tests

## License

Copyright © 2013 Benjamin Danon <benjamin@sphax3d.org>  
This work is free. You can redistribute it and/or modify it under the  
terms of the Do What The Fuck You Want To Public License, Version 2,  
as published by Sam Hocevar. See the COPYING file for more details.  

Code available on Github at https://github.com/sphax3d/annotation_to_markdown
