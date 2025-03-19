// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

#show ref: it => locate(loc => {
  let suppl = it.at("supplement", default: none)
  if suppl == none or suppl == auto {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let target = query(it.target, loc).first()
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}

#let _title-size = 44pt
  
#let FireLetter(
  background: rgb("f4f1eb"),
  title: "",
  from-details: none,
  to-details: none,
  margin: 2.1cm,
  vertical-center-level: 2,
  body
) = {
  set page(fill: background, margin: margin)
  set text(font: ("HankenGrotesk"))
  
  // Links should be purple.
  show link: set text(rgb("#800080"))
  
  let body = [
    #set text(size: 11pt, weight: "medium")
    #show par: set block(spacing: 2em)
    #body
  ]

  let header = {
    grid(
      columns: (1fr, auto),
      [
        #set text(size: _title-size, weight: "bold")
        #set par(leading: 0.4em)
        #title
      ],
      align(end, box(
        inset: (top: 1em),
        [
          #set text(size: 10.2pt, fill: rgb("4d4d4d"))
          #from-details
        ]
      )),
    )
    v(_title-size)
    text(size: 9.2pt, to-details)
    v(_title-size)
  }
  
  layout(size => context [
    #let header-sz = measure(block(width: size.width, header))
    #let body-sz = measure(block(width: size.width, body))

    #let ratio = (header-sz.height + body-sz.height) / size.height
    #let overflowing = ratio > 1

    #if overflowing or vertical-center-level == none {
      header
      body
    } else {
      // If no overflow of the first page, we do a bit of centering magic for style
      
      grid(
        rows: (auto, 1fr),
        header,
        box([
          #v(1fr * ratio)
          #body
          #v(vertical-center-level * 1fr)
        ]),
      )
    }
  ])
}

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
#show: FireLetter.with(
  title: [Jihong \
Zhang \

],
  from-details: [Appt. x \
Mos Espa, \
Tatooine \
anakin\@example.com \
\+999 xxxx xxx \

],
  to-details: [Sheev Palpatine \
500 Republica, \
Ambassadorial Sector, Senate District, \
Galactic City, ~Coruscant

],
)
#import "@preview/fontawesome:0.1.0": *


Dear Emperor,

Let me talk about my skills.

= Quarto
<quarto>
Quarto enables you to weave together content and executable code into a finished document. To learn more about Quarto see #link("https://quarto.org");.

= Typst
<typst>
You can check Quarto Typst documentation at #link("https://quarto.org/docs/output-formats/typst.html");.

- This is a list
  - This is second-level list
    - This is third-level list?

#block[
#callout(
body: 
[
+ Numbered list 1 \
+ Numbered list 2

]
, 
title: 
[
Add Callout Title
]
, 
background_color: 
rgb("#dae6fb")
, 
icon_color: 
rgb("#0758E5")
, 
icon: 
fa-info()
)
]
#block[
#callout(
body: 
[
- Bold font #strong[works];?

- Italic font #emph[works];?

- Striketrough font #strike[works];?

- `Source Code` (Monospace works with backticks \`)

]
, 
title: 
[
Tip
]
, 
background_color: 
rgb("#ccf1e3")
, 
icon_color: 
rgb("#00A047")
, 
icon: 
fa-lightbulb()
)
]
Here is a span with a green.

Horizontal Rules:

#horizontalrule

You can hyperlink as #link("https://jihongzhang.org")[Link] here.

#quote(block: true)[
This is quoted text.

– Jihong Zhang
]

== Running Code
<running-code>
When you click the #strong[Render] button a document will be generated that includes both content and the output of embedded code. You can embed code like this:

```r
library(ggplot2)
ggplot(mtcars, aes(x = mpg, y = disp)) + geom_point()
```

#figure([
#box(image("template_files/figure-typst/fig-my-plot-1.svg"))
], caption: figure.caption(
position: bottom, 
[
My Plot
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
numbering: "1", 
)
<fig-my-plot>


You can also cite your plot @fig-my-plot.

You can add options to executable code like this

#block[
#block[
```
[1] 4
```

]
]
The `echo: false` option disables the printing of code (only output is displayed).

Image:

Sincerely,

Mr.~Skywalker
