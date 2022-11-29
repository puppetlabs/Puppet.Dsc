Function ConvertTo-CanonicalPuppetAuthorName {
  <#
    .SYNOPSIS
      Convert a string to a valid Puppet module author name
    .DESCRIPTION
      Convert a string to a valid Puppet module author name, replacing any non-alphanumeric
      characters with underscores, downcasing the strin, and trimming any extraneous underscores.
    .PARAMETER AuthorName
      The string to convert into a canonicalized Puppet module author name.
    .EXAMPLE
      "foo bar" | ConvertTo-CanonicalPuppetAuthorName

      This command will return the string 'foo_bar', which is a valid Puppet module author name.
  #>
  [cmdletbinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [string]$AuthorName
  )

  Begin {}

  Process {
    # Puppet module author names must be lower cased alphanumeric
    $CanonicalAuthorName = $AuthorName.ToLower() -replace '[^a-zA-Z\d]+', '_'
    # An author name likely should neither end nor begin with one or more underscores
    $CanonicalAuthorName.trim('_')
  }

  End {}
}
