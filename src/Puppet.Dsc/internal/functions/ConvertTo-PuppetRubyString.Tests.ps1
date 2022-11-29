Describe 'ConvertTo-CanonicalPuppetAuthorName' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }

  Context 'Basic verification' {
    It 'wraps a quoteless string in single quotes' {
      # foo bar baz => 'foo bar baz'
      ConvertTo-PuppetRubyString -String 'foo bar baz' | Should -Be "'foo bar baz'"
    }
    It 'wraps a single-quote-containing string in double quotes' {
      # foo 'bar' baz => "foo 'bar' baz"
      ConvertTo-PuppetRubyString -String "foo 'bar' baz" | Should -Be """foo 'bar' baz"""
    }
    It 'wraps a double-quote containing string in single quotes' {
      # foo "bar" baz => 'foo "bar" baz'
      ConvertTo-PuppetRubyString -String 'foo "bar" baz' | Should -Be "'foo `"bar`" baz'"
    }
    It 'wraps a single-and-double-quote containing string in double quotes and backslash-escapes the internal double-quotes' {
      # 'foo "bar" baz' => "'foo \"bar\" baz'"
      ConvertTo-PuppetRubyString -String "'foo `"bar`" baz'" | Should -Be """'foo \`"bar\`" baz'"""
    }
  }
}
