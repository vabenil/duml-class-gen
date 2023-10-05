/+
Single file library to create a UML class diagram in dot from a list of D classes

**Optional Dependencies**:
- [graphviz](https://graphviz.org/) - For converting a dot file into an image

**Usage**:
store the result of `create_uml_diagram` in a .dot file:

Using graphviz convert dot file to png with:
```sh
dot -Tpng -o diagram.png
```

TODO:
- Add ability to set style
- Add unitests
+/
module duml_class_gen;

import std.stdio;
import std.traits;

import std.format;

@safe:

private enum default_style =
`    fontname = "Bitstream Vera Sans"
    fontsize = 8

    node [
        fontname = "Bitstream Vera Sans"
        fontsize = 8
        shape = "record"
    ]
`;

string create_uml_class(Class)()
{
    string class_name = Class.stringof;
    string fields = "";
    string methods = "";

    alias members = __traits(derivedMembers, Class);
    // this can be done at compile time
    foreach (member_name; members) {
        alias member = __traits(getMember, Class, member_name);
        // TODO: Consider more visibilities
        string visibility = 
            (__traits(getVisibility, member) == "public") ? "+" : "-";

        static if (isCallable!member)
            methods ~= format!`%s %s\l`(visibility, member_name);
        else // TODO: get argument types
            fields ~= format!`%s %s : %s\l`(visibility, member_name, typeof(member).stringof);
    }
    return
        `"%1$s" [label = "{%1$s | %2$s | %3$s}"]`.format(class_name, fields, methods);
}

string create_uml_diagram(Classes...)()
{
    string uml =
        "digraph Classdiagram {\n" ~
        default_style;

    static foreach (i, ClassT; Classes) {
        uml ~= `    %s`.format(create_uml_class!ClassT());
        uml ~= "\n";

    }
    uml ~= "}\n";
    return uml;
}

// NOTE: This doesn't check if the Class diagram from and to actually exist
/+
possible arrows are:
- `---` - for association
- `-->` - for direct association
- `--o - for aggregation
- `--*` - for composition
+/
// uml_class_diagram must be a value generated by create_uml_diagram
string append_relations(string uml_class_diagram, string[] relations...)
in(relations.length % 3 == 0)
{
    string new_diagram = uml_class_diagram[0..$-2].idup;

    for(int i = 0; i < relations.length; i += 3) {
        string from_ = relations[i];
        string arrow_str = relations[i+1];
        string to_ = relations[i+2];

        string arrow_type;
        switch (arrow_str) {
            case "---":
                arrow_type = "none";
                break;
            case "-->":
                arrow_type = "normal";
                break;
            case "--o":
                arrow_type = "ediamond";
                break;
            case "--*":
                arrow_type = "diamond";
                break;
            default:
                arrow_type = "none";
                break;
        }

        new_diagram ~= format!`    "%s" -> "%s" [arrowhead="%s"]`(from_, to_, arrow_type);
        new_diagram ~= "\n";
    }
    new_diagram ~= "}\n";

    return new_diagram;
}

unittest
{
    class Voxel
    {
    }

    class World
    {
        Voxel[] blocks;
        private bool a;

        abstract void set_block(int x, int y, int z, Voxel block);
        abstract Voxel get_block(int x, int y, int z);
    }

    struct A(T)
    {
    }

    static immutable string res =
        create_uml_diagram!(World, Voxel, A!int)
        .append_relations("World", "---", "Voxel")
        .append_relations("A!int", "--*", "Voxel");
    writeln(res);
    /* writeln(__traits(derivedMembers, World).stringof); */ 
}
