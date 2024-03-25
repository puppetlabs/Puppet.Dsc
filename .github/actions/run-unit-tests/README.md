# configure-winrm

## Description

## Usage

To trigger this action from within a workflow, call it using the `steps` snippet something like below:

```yaml
jobs:
  acceptance:
    steps:
      - name: Run Unit Tests
        uses: ./.github/actions/run-unit-tests
```
