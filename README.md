# UnpaywallLookup - a plugin to find the OA version of a document

UnpaywallLookup is a simple workflow component that can be used in the submission workflow, 
for example in the Upload stage.

The component queries the Unpaywall API and indicates whether a PDF is available as
Open Access.

## Installation

- copy the available plug-ins, configuration and phrases to their corresponding places
- edit the cfg.d/z_unpaywall_api.pl file and add the missing information
- edit the phrase file(s) so that it matches your repository
- in your workflow definition (usually cfg/workflows/eprint/default.xml), add
  &lt;component type="Upload_Unpaywall"/> where you want to have it
- restart your web server
