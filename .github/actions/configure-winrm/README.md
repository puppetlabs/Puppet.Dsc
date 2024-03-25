# configure-winrm

## Description

## Usage

To trigger this action from within a workflow, call it using the `steps` snippet something like below:

```yaml
jobs:
  acceptance:
    steps:
      - name: Configure WinRM
        uses: ./.github/actions/configure-winrm
```
