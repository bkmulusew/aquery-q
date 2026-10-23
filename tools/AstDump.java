import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

import scala.Option;
import scala.Product;
import scala.util.Either;
import scala.util.Left;
import scala.util.parsing.combinator.Parsers;
import scala.util.parsing.input.Position;
import scala.util.parsing.input.Positional;

import edu.nyu.aquery.parse.AqueryParser$;

/**
 * AstDump: runs the original Scala AQuery parser (inside aquery.jar) on one
 * .a file and prints the tree it builds, one value per line.
 *
 * This is test tooling only. Its output is the "golden" (expected) parse
 * tree that the new q parser must reproduce exactly.
 *
 * Usage:
 *   java -cp tools/aquery.jar:<dir with AstDump.class> AstDump file.a
 *
 * OUTPUT FORMAT (also described in tests/parser/README.md)
 *
 * If the program does not parse, there is one line:
 *
 *   FAILURE <TAB> line:column <TAB> message
 *
 * Otherwise the output is an indented tree. Every line is
 *
 *   <indent><label><value>
 *
 *   indent  2 spaces per level
 *   label   "name: " for a field of a node, "- " for an item of a list
 *   value   one of
 *     "text"            a string, in double quotes (escaped like TokenDump)
 *     42  1.5  true     a number or boolean (doubles use Java's
 *                       Double.toString, e.g. 100.0)
 *     Plus              a constant with no fields (operators, Asc, TypeInt, ...)
 *     []                an empty list
 *     None              an empty Option
 *     Name @line:col    a node; its fields follow, one level deeper.
 *                       "@line:col" is where the Scala parser says the node
 *                       starts; it is left out when the node has no position.
 *     Name              a node without a position, same layout
 *     (a list, a Some, a Left/Right or a tuple is printed as a node named
 *      List, Some, Left, Right or Tuple, with its parts one level deeper:
 *      "- " items for List, "value: " for Some/Left/Right, "_1: ", "_2: "...
 *      for Tuple)
 *
 * The top level is the list of top-level constructs:
 *
 *   List
 *     - Query @1:1
 *       local: []
 *       main: Project @1:1
 *         t: Table @1:15
 *           n: "t"
 *           alias: None
 *         ps: List
 *           - Tuple
 *             _1: IntLit @1:8
 *               v: 1
 *             _2: None
 *
 * Fields named "attr" (analysis results, always empty after parsing) are
 * not printed.
 *
 * INTENTIONAL DIVERGENCE (same as TokenDump): the Scala lexer turns a
 * timestamp literal '01/02/2020D10:11:12' into a string, so the parser
 * makes it StringLit. The q parser makes it TimestampLit. A StringLit whose
 * source text starts with a single quote can only be a timestamp, so it is
 * printed as TimestampLit.
 */
public class AstDump {

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("usage: AstDump <file.a>");
            System.exit(2);
        }
        String source = new String(Files.readAllBytes(Path.of(args[0])), StandardCharsets.UTF_8);

        // AqueryParser is a Scala "object" (a singleton): from Java its one
        // instance is the static field AqueryParser$.MODULE$. apply(source)
        // lexes and parses a whole program.
        Parsers.ParseResult<?> result = AqueryParser$.MODULE$.apply(source);

        StringBuilder out = new StringBuilder();
        if (result.successful()) {
            printValue(out, 0, "", result.get());
        } else {
            // Failure and Error both have a message and the position of the
            // token where parsing gave up.
            Parsers.NoSuccess failure = (Parsers.NoSuccess) result;
            Position pos = failure.next().pos();
            out.append("FAILURE\t").append(pos.line()).append(':').append(pos.column())
               .append('\t').append(escape(failure.msg())).append('\n');
        }
        System.out.print(out);
    }

    /** Print one value as "<indent><label><value>", plus its parts below it. */
    static void printValue(StringBuilder out, int depth, String label, Object value)
            throws Exception {
        String indent = "  ".repeat(depth);
        out.append(indent).append(label);

        // Strings, numbers and booleans: one line.
        if (value instanceof String) {
            out.append('"').append(escape((String) value)).append("\"\n");
            return;
        }
        if (value instanceof Number || value instanceof Boolean) {
            out.append(value).append('\n');
            return;
        }

        // Scala lists (all AST lists are scala.collection.immutable.List).
        if (value instanceof scala.collection.immutable.List) {
            scala.collection.immutable.List<?> list = (scala.collection.immutable.List<?>) value;
            if (list.isEmpty()) {
                out.append("[]\n");
                return;
            }
            out.append("List\n");
            scala.collection.Iterator<?> it = list.iterator();
            while (it.hasNext()) {
                printValue(out, depth + 1, "- ", it.next());
            }
            return;
        }

        // Option: None, or Some with its value one level deeper.
        if (value instanceof Option) {
            Option<?> option = (Option<?>) value;
            if (option.isEmpty()) {
                out.append("None\n");
                return;
            }
            out.append("Some\n");
            printValue(out, depth + 1, "value: ", option.get());
            return;
        }

        // Either: Left or Right with its value one level deeper.
        if (value instanceof Either) {
            Either<?, ?> either = (Either<?, ?>) value;
            boolean isLeft = either instanceof Left;
            out.append(isLeft ? "Left\n" : "Right\n");
            Object inner = isLeft ? either.left().get() : either.right().get();
            printValue(out, depth + 1, "value: ", inner);
            return;
        }

        // Tuples: Tuple, then _1, _2, ...
        if (value instanceof Product && value.getClass().getName().startsWith("scala.Tuple")) {
            Product tuple = (Product) value;
            out.append("Tuple\n");
            for (int i = 0; i < tuple.productArity(); i++) {
                printValue(out, depth + 1, "_" + (i + 1) + ": ", tuple.productElement(i));
            }
            return;
        }

        // AST nodes: Scala case classes and case objects are Products.
        if (value instanceof Product) {
            Product node = (Product) value;

            // A case object (Plus, Asc, TypeInt, ...) has no fields. It is a
            // single shared instance, so a position stored on it means
            // nothing; print the bare name.
            if (node.productArity() == 0) {
                out.append(node.productPrefix()).append('\n');
                return;
            }

            out.append(nodeName(node));
            if (node instanceof Positional) {
                Position pos = ((Positional) node).pos();
                if (pos.line() > 0) {
                    out.append(" @").append(pos.line()).append(':').append(pos.column());
                }
            }
            out.append('\n');

            List<String> names = fieldNames(node);
            for (int i = 0; i < node.productArity(); i++) {
                if (names.get(i).equals("attr")) {
                    continue;
                }
                printValue(out, depth + 1, names.get(i) + ": ", node.productElement(i));
            }
            return;
        }

        throw new IllegalStateException("AstDump: unexpected value " + value.getClass());
    }

    /** The node's name, with the timestamp divergence applied (see top). */
    private static String nodeName(Product node) {
        String name = node.productPrefix();
        if (name.equals("StringLit") && node instanceof Positional) {
            Position pos = ((Positional) node).pos();
            if (pos.line() > 0 && pos.lineContents().charAt(pos.column() - 1) == '\'') {
                return "TimestampLit";
            }
        }
        return name;
    }

    /**
     * Names of a case class's constructor parameters, in order.
     *
     * Scala 2.11 (the version inside the jar) has no API for these names.
     * The compiler stores each parameter as a private field, declared
     * before any other field of the class, so the first productArity
     * non-static fields are the parameters.
     */
    private static List<String> fieldNames(Product node) {
        List<String> names = new ArrayList<>();
        for (Field f : node.getClass().getDeclaredFields()) {
            if (!Modifier.isStatic(f.getModifiers()) && names.size() < node.productArity()) {
                names.add(f.getName());
            }
        }
        return names;
    }

    /** Make text safe to print on one line (same rules as TokenDump). */
    private static String escape(String text) {
        StringBuilder sb = new StringBuilder();
        for (char c : text.toCharArray()) {
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '"':  sb.append("\\\""); break;
                case '\t': sb.append("\\t");  break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }
}
