import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import scala.util.parsing.combinator.lexical.Scanners;
import scala.util.parsing.combinator.token.Tokens;
import scala.util.parsing.input.Position;

import edu.nyu.aquery.parse.AqueryParser$;

/**
 * TokenDump: runs the original Scala AQuery lexer (inside aquery.jar) on one
 * .a file and prints every token it produces, one per line.
 *
 * This is test tooling only. Its output is the "golden" (expected) token
 * stream that the new q lexer must reproduce exactly.
 *
 * Usage:
 *   java -cp tools/aquery.jar:<dir with TokenDump.class> TokenDump file.a
 *
 * Output format, one token per line, fields separated by a TAB:
 *
 *   kind <TAB> text <TAB> line:column
 *
 *   kind   one of: Keyword, Identifier, NumericLit, StringLit, Date,
 *          Verbatim, ErrorToken, EOF
 *   text   the token's characters. For ErrorToken it is the error message
 *          as the Scala lexer reports it (e.g. "*** error: illegal character").
 *          For EOF it is empty. Backslash, TAB, newline and carriage return
 *          are written as \\  \t  \n  \r so every token stays on one line.
 *   line:column   where the token starts, both counted from 1.
 *
 * The last line is always EOF, at the position where the input ends
 * (after trailing whitespace and comments). The Scala lexer has no real
 * EOF token object at that point; TokenDump writes this line itself so
 * the end position is part of the golden output too.
 */
public class TokenDump {

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("usage: TokenDump <file.a>");
            System.exit(2);
        }
        String source = new String(Files.readAllBytes(Path.of(args[0])), StandardCharsets.UTF_8);

        // AqueryParser is a Scala "object" (a singleton). From Java, the
        // single instance lives in the static field AqueryParser$.MODULE$.
        // Its "lexical" member is the lexer (class AqueryLexical).
        Scanners lexer = AqueryParser$.MODULE$.lexical();

        // A Scanner is the lexer's token stream: first() is the current
        // token, rest() is a new Scanner positioned at the next token.
        Scanners.Scanner scanner = newScanner(lexer, source);

        StringBuilder out = new StringBuilder();

        // atEnd() becomes true once only whitespace/comments are left.
        // The Scala parser stops there and never looks at first() again
        // (at that point first() is a meaningless placeholder token), so we
        // stop too, and print our own EOF line at the end position.
        while (!scanner.atEnd()) {
            Tokens.Token token = (Tokens.Token) scanner.first();
            printLine(out, kindOf(token), token.chars(), scanner.pos());
            scanner = scanner.rest();
        }
        printLine(out, "EOF", "", scanner.pos());

        System.out.print(out);
    }

    /** Append one "kind TAB text TAB line:column" line. */
    private static void printLine(StringBuilder out, String kind, String text, Position pos) {
        out.append(kind).append('\t')
           .append(escape(text)).append('\t')
           .append(pos.line()).append(':').append(pos.column())
           .append('\n');
    }

    /**
     * Create a Scanner for the given source text.
     *
     * Scanner is a class nested inside the Scala trait Scanners. In the
     * bytecode its constructor is Scanner(Scanners outer, String source),
     * but javac refuses to call it directly (it treats the class as
     * "static nested" and "inner" at the same time). Calling the
     * constructor through reflection avoids that javac limitation.
     */
    private static Scanners.Scanner newScanner(Scanners lexer, String source) throws Exception {
        return Scanners.Scanner.class
                .getConstructor(Scanners.class, String.class)
                .newInstance(lexer, source);
    }

    /**
     * Name of the token's kind. The token classes are Scala case classes
     * whose simple Java class name is already what we want ("Keyword",
     * "Identifier", "ErrorToken", ...). A Scala case object would compile
     * to a name ending in '$', so strip that just in case.
     */
    private static String kindOf(Object token) {
        String name = token.getClass().getSimpleName();
        if (name.endsWith("$")) {
            name = name.substring(0, name.length() - 1);
        }
        return name;
    }

    /** Make text safe to print on one line inside a TAB-separated field. */
    private static String escape(String text) {
        StringBuilder sb = new StringBuilder();
        for (char c : text.toCharArray()) {
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\t': sb.append("\\t");  break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }
}
