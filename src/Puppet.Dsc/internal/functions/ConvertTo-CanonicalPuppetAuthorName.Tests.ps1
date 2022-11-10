Describe 'ConvertTo-CanonicalPuppetAuthorName' -Tag 'Unit' {
  BeforeAll {
    $ModuleRootPath = Split-Path -Parent $PSCommandPath |
      Split-Path -Parent |
      Split-Path -Parent
    Import-Module "$ModuleRootPath/Puppet.Dsc.psd1"
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  }
  Context 'Basic verification' {
    It 'lower-cases author name' {
      ConvertTo-CanonicalPuppetAuthorName -AuthorName 'FoObAr' | Should -MatchExactly 'foobar'
    }
    It 'replaces invalid characters' {
      ConvertTo-CanonicalPuppetAuthorName -AuthorName 'foo bar&@_*baz' | Should -MatchExactly 'foo_bar_baz'
    }
    It 'trims underscores' {
      ConvertTo-CanonicalPuppetAuthorName -AuthorName '@#foo*(' | Should -MatchExactly 'foo'
    }
    It 'takes input from the pipeline' {
      'Foo Bar' | ConvertTo-CanonicalPuppetAuthorName | Should -MatchExactly 'foo_bar'
    }
  }
}
