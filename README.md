# FireLetter Format

## Installation and use

To install the Quarto extension, create a directory, and use the template file:

```bash
quarto use template JihongZ/FireLetter
```

This will install the format extension and create an example qmd file
that you can use as a starting place for your document.


To use the extension in an existing project without installing the template file:

```bash
quarto install extension JihongZ/FireLetter
```

Note that you will need to update the output format to `format:FireLetter-typst` to enable use of the extension. For book projects, add:

```yaml
Project:
  type:FireLetter-typst
```

to the `_quarto.yml` file.

## Using

_TODO_: Describe how to use your format.

