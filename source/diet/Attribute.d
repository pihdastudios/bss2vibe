module diet.Attribute;

import std.ascii;
import std.array : splitArr = split, join;
import std.conv;
import std.regex;

public class Attribute
{
    /// Attribute name
    public string name;
    /// Attribute value
    public string value;
    /// Quote style for values
    public bool doubleQuotes;

    @safe this(string name, string value, bool doubleQuotes = false)
    {
        this.name = name;
        this.value = value;
        this.doubleQuotes = doubleQuotes;
    }

    /**
    * Returns a quote character based on quote style.
    */
    @property @safe private string quote() const
    {
        return this.doubleQuotes ? text('"') : text('\'');
    }

    /**
    * Creates a string representation of the attribute.
    * e.g. key="value"
    */
    @safe public override string toString() const
    {
        switch (this.name)
        {
        case "id":
            {
                return "#" ~ this.value;
            }
        case "class":
            {
                return "." ~ (this.value.splitArr!isWhite).join('.');
            }
        default:
            {
                // If value is blank, return just the name (shorthand)
                if (!this.value)
                {
                    return this.name;
                }
                // Add escaped single quotes (\') to attribute values
                // to allow for surrounding single quotes.
                const string safeValue = this.value.replaceAll(regex("'", "g"), "\\\'");
                return this.name ~ "=" ~ this.quote ~ safeValue ~ this.quote;
            }
        }
    }
}

/// stringifies an ID
@safe unittest
{
    auto attr = new Attribute("id", "foo");
    assert(attr.toString() == "#foo");
}

/// stringifies a single class selector
@safe unittest
{
    auto attr = new Attribute("class", "foo");
    assert(attr.toString() == ".foo");
}

/// stringifies multiple class selectors
@safe unittest
{
    auto attr = new Attribute("class", "foo bar baz qux");
    assert(attr.toString() == ".foo.bar.baz.qux");
}

/// stringifies a generic attribute
@safe unittest
{
    auto attr = new Attribute("type", "number");
    assert(attr.toString() == "type='number'");
}

/// changes quote style
@safe unittest
{
    auto attr = new Attribute("quote-style", "double", true);
    assert(attr.toString() == `quote-style="double"`);
}

/// escapes single quotes from values
@safe unittest
{
    auto attr = new Attribute("style", "background-image: url('/path/to/nowhere')");
    assert(attr.toString() == "style='background-image: url(\\'/path/to/nowhere\\')'");
}

/// omits value if blank
@safe unittest
{
    auto attr = new Attribute("required", null);
    assert(attr.toString() == "required");
}
