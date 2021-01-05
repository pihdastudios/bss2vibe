module diet.Node;

import diet.Attribute;
import diet.Parser;

import std.array : array, join, split;
import std.algorithm.searching : find, any;
import std.algorithm.iteration : filter, map;

import std.conv : text;
import std.range : repeat;

/**
 * Represents a Diet node element.
 */
public class Node
{
    /// The pug node name
    public string name;
    /// The node value
    public string value;
    /// List of node attributes
    public Attribute[] attributes;
    /// Indent level
    public int indentLevel;
    /// Option to comma-separate attributes
    public bool commas;
    /// Indent style
    public bool tabs;

    @safe this(string name, string value = "", int indentLevel = 0,
            bool tabs = false, bool commas = false)
    {
        import std.stdio;
        this.name = name;
        this.value = value;
        this.indentLevel = indentLevel;
        this.tabs = tabs;
        this.commas = commas;
    }

    /**
   * Adds a new attribute to the attributes list.
   * Param:
   *    name
   *    value
   */
    @safe public void setAttribute(string name, string value, bool doubleQuotes = false)
    {
        this.attributes ~= new Attribute(name, value, doubleQuotes);
    }

    @safe public override string toString() const
    {
        // Construct the string starting with the tag name.
        string str = this.tagName;

        // Add the element ID
        const id = (this.attributes.find!((attr) => attr.name == "id"));
        if (id.length > 0)
        {
            str ~= id[0].toString();
        }

        // Add the class names
        const className = (this.attributes.find!((attr) => attr.name == "class"));
        if (className.length > 0)
        {
            str ~= className[0].toString();
        }

        // Add the rest of the attributes
        auto attrs = this.attributes
            .filter!(attr => attr.name != "id" && attr.name != "class")
            .map!(attr => attr.toString())
            .array;
        if (attrs.length > 0)
        {
            str ~= "(" ~ attrs.join(this.commas ? ", " : " ") ~ ")";
        }

        // Append the node value inline or as multi-line block.
        if (this.value != "")
        {
            if (this.isMultiLine)
            {
                // TODO change block character
                // TODO add indent
                const childIndent = this.getIndent(this.indentLevel + 1);

                str ~= `.\n` ~ childIndent ~ this.value;
            }
            else
            {
                // The following leading space is not an indent, but the
                // standard single space between the node name and its value.
                // Text nodes don't have tag names, so no space needed there.
                str ~= str.length > 0 ? " " ~ this.value : this.value;
            }
        }

        const rootIndent = this.getIndent(this.indentLevel);
        return rootIndent ~ str;
    }

    @safe @property private string tagName() const
    {
        import std.stdio;
        switch (this.name)
        {
        case Nodes.Text:
            return "";
        case Nodes.Doctype:
            return "doctype";
        case Nodes.Comment:
            return "//";
        case Nodes.Div:
            {
                const hasClassOrId = this.attributes.any!(attr => attr.name == "id"
                        || attr.name == "class");
                return hasClassOrId ? "" : this.name;
            }
        default:
            return this.name;
        }
    }

    /**
   * Returns the indent based on indent level and indent style.
   *
   * @param level
   */
    @safe private string getIndent(int level) const
    {
        const indentStyle = this.tabs ? '\t'.text : "  ";
        return indentStyle.repeat(level).join();
    }

    /// Denotes whether the value is multi-line or not
    @safe private @property isMultiLine() const
    {
        if (this.value != "")
        {
            return false;
        }
        const lines = this.value.split("\n");
        return lines.length > 1;
    }
}

/// sets attributes
@safe unittest
{
    auto node = new Node("div");
    assert(node.attributes.length == 0);
    node.setAttribute("id", "foo");
    assert(node.attributes.length != 0);
}

/// stringifies div with standard form if no attributes
@safe unittest
{
    const node = new Node("div", "foo");
    assert(node.toString() == "div foo");
}

/// stringifies using div shorthand
@safe unittest
{
    auto node = new Node("div");
    node.setAttribute("id", "foo");
    node.setAttribute("class", "bar");
    assert(node.toString() == "#foo.bar");
}

/// stringifies text nodes with no tag name
@safe unittest
{
    auto node = new Node("#text", "foo");
    assert(node.toString() == "foo");
}

/// stringifies using comment shorthand
@safe unittest
{
    const node = new Node("#comment", "foo");
    assert(node.toString() == "// foo");
}

/// stringifies attributes without comma
@safe unittest
{
    auto node = new Node("input");
    node.setAttribute("type", "number");
    node.setAttribute("required", "required");
    assert(node.toString == "input(type='number' required='required')");
}

/// stringifies attributes with comma
@safe unittest
{
    auto node = new Node("input", "", 0, false, true);
    node.setAttribute("type", "number");
    node.setAttribute("required", "required");
    assert(node.toString == "input(type='number', required='required')");
}

/// stringifies all types of attributes
@safe unittest
{
    auto node = new Node("input");
    node.setAttribute("id", "foo");
    node.setAttribute("class", "bar");
    node.setAttribute("type", "text");
    node.setAttribute("required", "required");
    node.setAttribute("data-key", "r4nd0m-k3y");
    assert(node.toString() == "input#foo.bar(type='text' required='required' data-key='r4nd0m-k3y')");
}

/// stringifies an inline value
@safe unittest
{
    auto node = new Node("h1", "Hello, world!");
    node.setAttribute("class", "title");
    assert(node.toString() == "h1.title Hello, world!");
}

/// formats a multi-line value
@safe unittest
{
    const node = new Node("textarea", "Hello, world!\nThis is a new line");
    assert(node.toString(), "textarea.\n  Hello, world!\nThis is a new line");
}

/// sets the appropriate indent
@safe unittest
{
    import std.algorithm.searching : startsWith;
    auto node = new Node("h1", "Hello, world!", 2);
    assert(startsWith(node.toString(), "    "));
}

/// uses tabs as indent style
@safe unittest
{
    import std.algorithm.searching : startsWith;
    auto node = new Node("h1", "Hello, world!", 1, true);
    assert(node.toString().startsWith("\t"));
}

