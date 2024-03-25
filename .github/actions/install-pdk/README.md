# install-pdk

## Description

## Usage

To trigger this action from within a workflow, call it using the `steps` snippet something like below:

```yaml
jobs:
  acceptance:
    steps:
      - name: Install PDK
        uses: ./.github/actions/install-pdk
```

Or if you want to over-ride the default pdk version, then something like:

```yaml
jobs:
  acceptance:
    steps:
      - name: Install PDK
        uses: ./.github/actions/install-pdk
        with:
          pdk_version: 3.0.1.3
```
