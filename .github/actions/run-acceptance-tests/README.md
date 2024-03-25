# run-acceptance-tests

## Description

## Usage

To trigger this action from within a workflow, call it using the `steps` snippet something like below:

```yaml
jobs:
  acceptance:
    steps:
      - name: Run Acceptance Tests
        uses: ./.github/actions/run-acceptance-tests
```
