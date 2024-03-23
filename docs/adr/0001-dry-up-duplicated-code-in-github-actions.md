# 1. Dry up duplicated code in github actions

Date: 2024-03-22

## Status

Accepted

## Context

The `Puppet.Dsc` repository contains a number of github workflows and all of them, currently, have duplicated code.  For example, the code to configure `winrm` is duplicated in 6 places throughout the 4 github workflows.  Duplicated code is generally considered bad practice in software development.  By avoiding code duplication through techniques like abstraction, code reuse, and modularization, you can create a codebase that is easier to maintain, understand, and test.

In github workflows there are [3 main ways to dry up duplicated code][1]: Reusable Workflows, Dispatched workflows, and Composite Actions.  Since most of the duplication in this repository is in clusters of repeated steps, then the [Composite Action][2] is probably the best option.  The Composite Action is a reusable piece of code that can be used across multiple GitHub workflows. It allows you to combine multiple steps into a single action, which can then be used in different workflows, reducing code duplication and improving maintainability.

## Decision

Therefore, I decided to dry up duplication in our github actions with Composite Actions.

## Consequences

With a single `action.yml` to change, it is easier now to change behaviour across many workflows.  For example, now there is one place to change the version of the PDK; one place to adjust the `winrm` configuration.

## References

[1]: https://cardinalby.github.io/blog/post/github-actions/dry-reusing-code-in-github-actions/
[2]: https://docs.github.com/en/actions/creating-actions/creating-a-composite-action
