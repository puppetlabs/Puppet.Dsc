# Puppetized Module Invocation

## About Puppetized Module Invocation

# SHORT DESCRIPTION

Explanation of how Puppet invokes DSC Resources in a Puppetized PowerShell module.

# LONG DESCRIPTION

When a PowerShell module with DSC Resources is puppetized, Puppet.Dsc exports a type file and a provider file to tell Puppet how to manage the DSC Resource.

While the type file tells Puppet what it needs to know about the API surface of the DSC Resource, it's the provider file that does all of the work.

## The Scaffolded Provider Files

When Puppet.Dsc writes a Puppet provider for the DSC Resource, it doesn't actually write many lines of code. This example is for the `PSRepository` DSC Resource from the PowerShellGet module:

```ruby
require 'puppet/provider/dsc_base_provider/dsc_base_provider'

# Implementation for the dsc_type type using the Resource API.
class Puppet::Provider::DscPsrepository::DscPsrepository < Puppet::Provider::DscBaseProvider
end
```

This provider file does exactly two things:

1. Loads a ruby file: `puppet/provider/dsc_base_provider/dsc_base_provider`. This will be covered more in depth in the next section.
1. Creates a ruby class called `DscPsrepository` which is inherited from `DscBaseProvider`

All this file accomplishes is creating a provider so Puppet knows how to interact with the DSC Resource; all of the logic for doing so exists in the DSC Base Provider instead of being written into every Puppetized module.

## The DSC Base Provider

The DSC Base Provider inherited for each Puppetized DSC Resource's provider is defined in the **puppetlabs-pwshlib** module. This has a few implications:

1. You cannot use a module with Puppetized DSC Resources without pwshlib installed
2. You do not need to update each of your modules with Puppetized DSC Resources to take advantage of provider-level bug fixes; instead, you only need to update pwshlib

The DSC Base Provider is Puppet's interface to calling DSC. At a high level, it is responsible for:

- Marshalling data from Puppet/Ruby to PowerShell and back
- Invoking DSC

And that's it!

The provider is a (relatively) thin wrapper around calling `Invoke-DscResource` to allow users to specify DSC Resources in their Puppet manifests and use DSC to ensure the state of those resources.

Everything the provider does is for that purpose.

### Marshalling Data

When you specify a Puppetized DSC Resource in your manifest, you're creating a data representation of that resource's desired state in the Puppet DSL. Puppet turns that into data in Ruby and makes it available to the provider.

The base provider is responsible for turning that ruby representation of the data into something PowerShell can understand.

After invoking DSC, the provider is also responsible for turning the data returned from PowerShell into the ruby data structures that Puppet expects to work with.

One important note is that the provider has to do some non-trivial work to treat Puppet manifest values for DSC Resource properties as case insensitive but case preserving; while PowerShell and therefore DSC are not case sensitive by default, Puppet is. The provider handles this via canonicalization, which happens during catalogue compilation.

### Handling Sensitive Data

The base provider is implemented to especially handle sensitive data; any sensitive value passed from Puppet for a DSC Resource is always redacted from the logs but passed as-defined to PowerShell.

This enables the use of secrets and credentials without leaking them.

### Invoking DSC

The base provider calls `Invoke-DscResource` at least once and as many as four times:

- During canonicalization, the provider calls `Invoke-DscResource` with the get method; it caches the return value, canonicalizes the manifest values (caching that, too), and returns the canonicalized manifest representation.
- After catalogue compilation, the provider calls its `Get` method; this method reuses the cached query from earlier (if it was successful) and, if the resource was not found in the cache, calls `Invoke-DscResource` with the get method to retrieve it and returns the value to Puppet as the current state of the resource.
- If the `validation_mode` was specified as `resource`, Puppet calls `Invoke-DscResource` once with the `Test` method to determine if the resource is in the desired state, caching the result. Puppet then treats all properties of that resource as in or out of the desired state, reusing the cached value.
- If the current state of the resource does not match the desired state (ie, the canonicalized manifest values), Puppet calls `Invoke-DscResource` with the `Set` method once to set the desired state.

### Debugging

When Puppet is run with the `debug` flag, the base provider emits a lot of debug information into the run log including:

- The data representation of the (uncanonicalized) manifest being retrieved from DSC
- The munged metadata for calling `Invoke-Dsc` (including information about property versions, module metadata, etc)
- The full script being called to invoke the DSC Resource (so you can capture this debug output and verify behavior from outside of Puppet)
- The JSON representation of the raw data returned from the invocation
- The munged ruby hash representation of the data returned from the invocation
- The canonicalized resource representation
- The current state of the resource
- The target state of the resource

This information is not very useful so long as everything goes well; however, when encountering errors or misbehavior, this debug information is very useful for validating behavior. In particular, the scriptblock debug output for what Puppet is using to invoke DSC can be copied and run outside of Puppet.

## See Also

- Troubleshoot puppetized DSC modules - https://ospassist.puppet.com/hc/en-us/articles/1500002388661-Troubleshooting-Puppetized-DSC-modules
- Advanced troubleshooting: dig deeper with pry - https://ospassist.puppet.com/hc/en-us/articles/360061073994-Advanced-troubleshooting-dig-deeper-with-pry
