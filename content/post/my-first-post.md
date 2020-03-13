---
title: "My First Post"
date: 2020-02-10T00:17:54+02:00
archives: "2020"
tags: ["hugo"]
author: Yair Gadelov
---
It is My first Hugo post. I decided to work with Hugo after I had an experience with word press. For me, writing documents in [Markdown](https://daringfireball.net/projects/markdown/syntax#p) format and using GitHub to manage my files, tags, and categories instead of using MySQL database is much easier to manage and deploy.  To learn how to create such a blog in Hugo, you can try this [blog](https://dreambooker.site/2019/08/17/Hugo-Staticman-Travis/),

## diagram
Learn how to plot the kinds of figures. See also [hugo shortcodes](https://gohugo.io/content-management/shortcodes/).

* [gravizo](https://it.knightnet.org.uk/kb/hugo/embed-diagram/) 
{{< gravizo "DOT Language (GraphViz) Example" >}}
  digraph G {
    aize ="4,4";
    main [shape=box];
    main -> parse [weight=8];
    parse -> execute;
    main -> init [style=dotted];
    main -> cleanup;
    execute -> { make_string; printf}
    init -> make_string;
    edge [color=red];
    main -> printf [style=bold,label="100 times"];
    make_string [label="make a string"];
    node [shape=box,style=filled,color=".7 .3 1.0"];
    execute -> compare;
  }
{{< /gravizo >}}

* [mermaid setup](https://codewithhugo.com/mermaid-js-hugo-shortcode/) and [examples](https://mermaid-js.github.io/mermaid/#/)
{{< mermaid >}}
classDiagram
	Class01 <|-- AveryLongClass : Cool
	Class03 *-- Class04
	Class05 o-- Class06
	Class07 .. Class08
	Class09 --> C2 : Where am i?
	Class09 --* C3
	Class09 --|> Class07
	Class07 : equals()
	Class07 : Object[] elementData
	Class01 : size()
	Class01 : int chimp
	Class01 : int gorilla
	Class08 <--> C2: Cool label
{{</mermaid>}}


* [flowcharts setup](https://github.com/adrai/flowchart.js) and [examples](https://support.typora.io/Draw-Diagrams-With-Markdown/)
{{< flowcharts >}}
st=>start: Start|past:>https://github.com/adrai/flowchart.js[blank]
e=>end: End:>http://www.google.com
op1=>operation: My Operation|past:$myFunction
op2=>operation: Stuff|current
sub1=>subroutine: My Subroutine|invalid
cond=>condition: Yes
or No?|approved:>http://www.google.com
c2=>condition: Good idea|rejected
io=>inputoutput: catch something...|request
para=>parallel: parallel tasks

st->op1(right)->cond
cond(yes, right)->c2
cond(no)->para
c2(true)->io->e
c2(false)->e

para(path1, bottom)->sub1(left)->op1
para(path2, right)->op2->e

st@>op1({"stroke":"Red"})@>cond({"stroke":"Red","stroke-width":6,"arrow-end":"classic-wide-long"})@>c2({"stroke":"Red"})@>op2({"stroke":"Red"})@>e({"stroke":"Red"})

{{< /flowcharts >}}

## mathematical equations
See [here](https://github.com/KaTeX/KaTeX) for more info on how to integrate latex mathematical equation syntax in HTML pages.  The following:
```latex
$$\int_{a}^{b} x^2 dx$$
```
will render to:
$$\int_{a}^{b} x^2 dx$$

