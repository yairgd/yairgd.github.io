---
title: "My First Post"
date: 2020-02-10T00:17:54+02:00
archives: "2020"
tags: []
author: Yair Gadelov
---

# first post

It is My first Hugo post. I decided to work with Hugo after I had an experience with word press. For me, writing documents in [Markdown](https://daringfireball.net/projects/markdown/syntax#p) format and using GitHub to manage my files, tags, and categories instead of using MySQL database is much easier to manage and deploy.  To learn how to create such a blog in Hugo, you can try this [blog](https://dreambooker.site/2019/08/17/Hugo-Staticman-Travis/), also learn how to plot the kinds of figures [here](https://it.knightnet.org.uk/kb/hugo/embed-diagram/) and [hugo shortcodes](https://gohugo.io/content-management/shortcodes/).

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
