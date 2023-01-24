<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [1.0.5](https://github.com/puppetlabs/Puppet.Dsc/tree/1.0.5) - 2023-01-24

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/1.0.4...1.0.5)

### Fixed

- (GH-240) Fix incorrect enum generation [#244](https://github.com/puppetlabs/Puppet.Dsc/pull/244) ([chelnak](https://github.com/chelnak))

## [1.0.4](https://github.com/puppetlabs/Puppet.Dsc/tree/1.0.4) - 2022-11-11

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/1.0.3...1.0.4)

### Fixed

- Adding case insensitive enum values [#230](https://github.com/puppetlabs/Puppet.Dsc/pull/230) ([nickgw](https://github.com/nickgw))

## [1.0.3](https://github.com/puppetlabs/Puppet.Dsc/tree/1.0.3) - 2022-11-04

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/1.0.2...1.0.3)

### Fixed

- (CONT-257) Add PDKTemplateRef parameter [#231](https://github.com/puppetlabs/Puppet.Dsc/pull/231) ([chelnak](https://github.com/chelnak))
- (GH-217) - Set LegacyDscForgePage [#219](https://github.com/puppetlabs/Puppet.Dsc/pull/219) ([pmcmaw](https://github.com/pmcmaw))

## [1.0.2](https://github.com/puppetlabs/Puppet.Dsc/tree/1.0.2) - 2022-03-18

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/1.0.0...1.0.2)

## [1.0.0](https://github.com/puppetlabs/Puppet.Dsc/tree/1.0.0) - 2021-07-28

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.7.0...1.0.0)

### Added

- (GH-68) Move Puppetization Automation helper functions into the module & document usage [#189](https://github.com/puppetlabs/Puppet.Dsc/pull/189) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (GH-74) Add Concept docs for module invocation [#188](https://github.com/puppetlabs/Puppet.Dsc/pull/188) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-186) Handle missing Project URI in PowerShell module metadata [#187](https://github.com/puppetlabs/Puppet.Dsc/pull/187) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.7.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.7.0) - 2021-07-06

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.6.0...0.7.0)

### Added

- (GH-172) Add implementation to generated types [#178](https://github.com/puppetlabs/Puppet.Dsc/pull/178) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MAINT) Define nested cim instance types as enums [#180](https://github.com/puppetlabs/Puppet.Dsc/pull/180) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.6.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.6.0) - 2021-06-28

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.5.0...0.6.0)

### Added

- (GH-148) Activate acceptance tests [#170](https://github.com/puppetlabs/Puppet.Dsc/pull/170) ([david22swan](https://github.com/david22swan))
- (GH-153) Ensure generated readme contains module name info [#163](https://github.com/puppetlabs/Puppet.Dsc/pull/163) ([david22swan](https://github.com/david22swan))
- (GH-145) Add validation mode flag to puppetized DSC Resources [#147](https://github.com/puppetlabs/Puppet.Dsc/pull/147) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-133) Throw if PSRemoting is disabled [#135](https://github.com/puppetlabs/Puppet.Dsc/pull/135) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-93) Allow alternate fixture references [#134](https://github.com/puppetlabs/Puppet.Dsc/pull/134) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (GH-139) Clarification added regarding the DSC Local Configuration Manager (LCM) [#165](https://github.com/puppetlabs/Puppet.Dsc/pull/165) ([david22swan](https://github.com/david22swan))
- (GH-150) Add known installation limitations to readme [#164](https://github.com/puppetlabs/Puppet.Dsc/pull/164) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-149) Add long path info to generated readme [#162](https://github.com/puppetlabs/Puppet.Dsc/pull/162) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-64) Add docs for customizing private modules [#161](https://github.com/puppetlabs/Puppet.Dsc/pull/161) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.5.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.5.0) - 2021-02-10

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.4.0...0.5.0)

### Added

- (GH-113) Vendor modules not found in module repo [#127](https://github.com/puppetlabs/Puppet.Dsc/pull/127) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Add CertReq parameters to hard-coded list [#124](https://github.com/puppetlabs/Puppet.Dsc/pull/124) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MAINT) Fix metadata summary entry definition [#123](https://github.com/puppetlabs/Puppet.Dsc/pull/123) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-114) - Adding PSCredential and CIM Instance examples [#122](https://github.com/puppetlabs/Puppet.Dsc/pull/122) ([pmcmaw](https://github.com/pmcmaw))

## [0.4.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.4.0) - 2021-01-27

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.3.0...0.4.0)

### Added

- (GH-75) Update pwshlib pin in generated module metadata [#119](https://github.com/puppetlabs/Puppet.Dsc/pull/119) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-111) Add PowerShellGet as module dependency [#118](https://github.com/puppetlabs/Puppet.Dsc/pull/118) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (GH-89) Fix various bugs for puppetization [#116](https://github.com/puppetlabs/Puppet.Dsc/pull/116) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-75) - PowerShell module dependencies are installable side by side [#115](https://github.com/puppetlabs/Puppet.Dsc/pull/115) ([pmcmaw](https://github.com/pmcmaw))

## [0.3.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.3.0) - 2020-12-14

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.2.0...0.3.0)

### Added

- (MAINT) Add JoinOU to parameter list [#107](https://github.com/puppetlabs/Puppet.Dsc/pull/107) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (MAINT) Ensure changelog actually updates [#108](https://github.com/puppetlabs/Puppet.Dsc/pull/108) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.2.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.2.0) - 2020-12-04

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/0.1.0...0.2.0)

### Added

- (MAINT) Update version pins for metadata.json [#101](https://github.com/puppetlabs/Puppet.Dsc/pull/101) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-80) Typify read only properties [#99](https://github.com/puppetlabs/Puppet.Dsc/pull/99) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-74, GH-81) Handle parameters in type generation and collapse ensure keywords [#88](https://github.com/puppetlabs/Puppet.Dsc/pull/88) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-72) Clarify property usage in generated readme [#84](https://github.com/puppetlabs/Puppet.Dsc/pull/84) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Enable puppetizing prerelease modules [#76](https://github.com/puppetlabs/Puppet.Dsc/pull/76) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Add project CHANGELOG file [#58](https://github.com/puppetlabs/Puppet.Dsc/pull/58) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Add function to update changelog [#57](https://github.com/puppetlabs/Puppet.Dsc/pull/57) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Add known limitations to generated readmes [#56](https://github.com/puppetlabs/Puppet.Dsc/pull/56) ([michaeltlombardi](https://github.com/michaeltlombardi))

### Fixed

- (GH-85) Make puppetizing prerelease modules switchable [#100](https://github.com/puppetlabs/Puppet.Dsc/pull/100) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Ensure struct keys are downcased [#98](https://github.com/puppetlabs/Puppet.Dsc/pull/98) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (MAINT) Only write attributes if parameter is not null [#97](https://github.com/puppetlabs/Puppet.Dsc/pull/97) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-59) Correct text in troubleshooting section [#91](https://github.com/puppetlabs/Puppet.Dsc/pull/91) ([pmcmaw](https://github.com/pmcmaw))
- (GH-71) Fix type def of props with optional nested cim instances [#78](https://github.com/puppetlabs/Puppet.Dsc/pull/78) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-66) Ensure type desc strings parse for reference [#77](https://github.com/puppetlabs/Puppet.Dsc/pull/77) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (maint) Correct links in README [#54](https://github.com/puppetlabs/Puppet.Dsc/pull/54) ([binford2k](https://github.com/binford2k))

## [0.1.0](https://github.com/puppetlabs/Puppet.Dsc/tree/0.1.0) - 2020-09-18

[Full Changelog](https://github.com/puppetlabs/Puppet.Dsc/compare/26224299b16de79c34ca635566ea1c1f985d67e4...0.1.0)
