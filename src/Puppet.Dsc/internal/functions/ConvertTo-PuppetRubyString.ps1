function ConvertTo-PuppetRubyString {
  <#
    .SYNOPSIS
      Convert a string to a valid literal string for Puppet ruby files
    .DESCRIPTION
      Convert a string to a valid literal string for interpolation into a Puppet ruby file;
      wrap it in the appropriate quotes and, if necessary, escape double quotes.
    .PARAMETER String
      The string to convert for interpolation
    .EXAMPLE
      ConvertTo-PuppetRubyString -String "foo bar baz"

      This command will convert the string `foo bar baz` to `'foo bar baz'`
    .EXAMPLE
      ConvertTo-PuppetRubyString -String "foo 'bar' baz"

      This command will convert the string `foo 'bar' baz` to `"foo 'bar' baz"`
    .EXAMPLE
      ConvertTo-PuppetRubyString -String 'foo "bar" baz'

      This command will convert the string `foo "bar" baz` to `'foo "bar" baz'`
    .EXAMPLE
      ConvertTo-PuppetRubyString -String "'foo `"bar`" baz'"

      This command will convert the string `'foo "bar" baz'` to `"'foo \"bar\" baz'"`
  #>
  [CmdletBinding()]
  [OutputType([String])]
  param (
    [Parameter(ValueFromPipeline)]
    [string]$String
  )

  begin {}

  process {
    if ($String -match "'") {
      # Puppet strings does not currently handle %q() delimited strings
      # See: https://github.com/puppetlabs/puppet-strings/issues/263
      # Once merged, should be able to update this function appropriately.
      # if ($String -match "'") {
      #   "%q($String)"
      # }
      # Write as a double-quoted string with double-quotes escaped for ruby
      """$($String.replace('"', '\"'))"""
    } else {
      # Write as single-quoted string
      "'$String'"
    }
  }

  end {}
}
