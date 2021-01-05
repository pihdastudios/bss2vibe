module diet.Parser;

import diet.Attribute;
import diet.Node;

import arsd.dom;

import std.concurrency;
import std.range;
import std.conv;

import std.stdio;

import core.thread;

/// Defines the type of parsed HTML nodes.

public enum Nodes
{
    Doctype = "#documentType",
    Text = "#text",
    Comment = "#comment",
    Div = "div",
    ITxt = "i"
}

public class Parser
{
    public string diet;
    public Element root;
    // Tabs vs Spaces
    public bool tabs;
    // Comma separate attributes
    public bool commas;
    // Use double quotes or single
    public bool doubleQuotes;

    @trusted this(Document root, bool tabs = false, bool commas = true, bool doubleQuotes = false)
    {
        this.root = root.root;
        this.tabs = tabs;
        this.commas = commas;
        this.doubleQuotes = doubleQuotes;
    }

    @trusted public string parse()
    {
        this.walk(this.root, 0);
        return this.diet[1 .. $];
    }

    //SHoulb be a generator
    @trusted public void walk(Element tree, int indentLevel)
    {
        if (tree.children.length == 0)
        {

            if (tree.tagName == Nodes.Text)
            {
                if (tree.toPrettyString() == "")
                {
                    return;
                }
                else
                {
                    const indentStyle = this.tabs ? '\t'.text : "  ";
                    this.diet ~= "\n".text ~ indentStyle.repeat(indentLevel).join() ~ "| " ~ tree.toString();
                    return;
                }

            }
            else
            {
                const node = this.parseHtmlNode(tree, indentLevel);

                if (node)
                {
                    this.diet ~= "\n".text ~ node.toString();
                }
            }
        }
        else if (tree.children.length == 1)
        {

            if (tree.children[0].tagName == Nodes.Text)
            {
                /// child is only text
                const node = this.parseHtmlNode(tree, indentLevel);

                if (node)
                {
                    this.diet ~= "\n".text ~ node.toString();
                }

            }

            else
            {

                const node = this.parseHtmlNode(tree, indentLevel);
                if (node)
                {
                    this.diet ~= "\n".text ~ node.toString();
                }
                foreach (e; tree.children)
                {
                    this.walk(e, indentLevel + 1);
                }
            }
        }
        else
        {

            const node = this.parseHtmlNode(tree, indentLevel);

            if (node)
            {
                this.diet ~= "\n".text ~ node.toString();
            }
            foreach (e; tree.children)
            {

                this.walk(e, indentLevel + 1);

            }
        }
    }

    /**
    * Creates a [PugNode] from a #documentType element.
    *
    * @param indentLevel
    */

    @trusted private Node createDoctypeNode(Element node, int indentLevel)
    {
        return new Node(Nodes.Doctype, node.name, indentLevel, this.tabs, this.commas);
    }

    /**
    * Creates a [PugNode] from a #text element.
    *
    * A #text element containing only line breaks (\n) indicates
    * unnecessary whitespace between elements that should be removed.
    *
    * Actual text in a single #text element has no significant
    * whitespace and should be treated as inline text.
    */

    /**
   * Creates a [PugNode] from a #comment element.
   * Block comments in Pug don't require the dot '.' character.
   *
   * @param indentLevel
   */
    @trusted private Node createCommentNode(Element node, int indentLevel)
    {
        return new Node(Nodes.Comment, node.value, indentLevel, this.tabs, this.commas);

    }

    @trusted private Node createTextNode(Element node, int indentLevel)
    {
        const value = node.innerHTML;
        // // Omit line breaks between HTML elements
        // if ( /  ^ [\n] + $ / .test(value))
        // {
        //     return;
        // }

        return new Node(Nodes.Text, value, indentLevel, this.tabs, this.commas);
    }
    /**
    * Converts an HTML element into a [PugNode].
    *
    * @param node
    * @param indentLevel
    */

    @trusted private Node createElementNode(Element node, int indentLevel)
    {
        string value;
        if (node.children.length == 1 && node.firstChild.tagName == Nodes.Text)
        {
            auto textNode = node.innerHTML;
            value = textNode;
        }

        auto dietNode = new Node(node.tagName, value, indentLevel, this.tabs, this.commas);
        foreach (attr, attr2; node.attributes)
        {
            dietNode.setAttribute(attr, attr2, this.doubleQuotes);
        }
        return dietNode;
    }

    /**
    * Parses the HTML node and converts it to a [PugNode].
    *
    * @param node
    * @param indentLevel
    */

    @trusted private Node parseHtmlNode(Element node, int indentLevel)
    {
        switch (node.tagName)
        {
        case Nodes.Doctype:
            return this.createDoctypeNode(node, indentLevel);
        case Nodes.Comment:
            return this.createCommentNode(node, indentLevel);
        case Nodes.Text:
            return this.createTextNode(node, indentLevel);
        default:
            return this.createElementNode(node, indentLevel);

        }
    }
}

/// converts a single HTML element
@trusted unittest
{
    import arsd.dom : Document;
    import std.uni : icmp;

    auto doc = new Document(`<h1 class="title">Hello, world!</h1>`);
    assert(new Parser(doc).parse() == "h1.title Hello, world!");
}

/// converts a nested HTML fragment
@trusted unittest
{
    import arsd.dom : Document;

    auto doc = new Document(
            `<ul id="fruits" class="list"><li class="item">Mango</li><li class="item">Apple</li></ul>`);
    assert(new Parser(doc).parse() == ("ul#fruits.list
  li.item Mango
  li.item Apple"));
}

/// removes whitespace between HTML elements
@trusted unittest
{
    import arsd.dom : Document;

    auto doc = new Document(`<ul class="list">
  <li>one</li>
  <li>two</li>

  <li>three</li>


  <li>four</li>
</ul>`);
    assert(new Parser(doc).parse() == ("ul.list
  li one
  li two
  li three
  li four"));
}

///transforms html document to pug with default options
@trusted unittest
{
    import arsd.dom : Document;

    auto doc = new Document(`<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Hello World!</title>
  </head>
  <body data-page="home">
    <header id="nav">
      <h1 class="heading">Hello, world!</h1>
    </header>
  </body>
</html>`);

    import std.stdio;

    // writeln(doc.toString());
    writeln(new Parser(doc).parse());
    assert(new Parser(doc).parse() == `doctype html
html(lang='en')
  head
    meta(charset='utf-8')
    title Hello World!
  body(data-page='home')
    header#nav
      h1.heading Hello, world!`);
}

@trusted unittest
{
    import arsd.dom : Document;
    import std.stdio;

    auto doc = new Document(
            `<div class="sidebar-brand-icon rotate-n-15"><i class="fas fa-laugh-wink"></i></div>`);
    writeln(new Parser(doc).parse());
}
