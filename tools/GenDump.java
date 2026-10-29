import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import scala.Option;
import scala.Product;
import scala.util.Either;
import scala.util.Left;
import scala.util.parsing.combinator.Parsers;

import edu.nyu.aquery.ast.Expr;
import edu.nyu.aquery.ast.IfThen;
import edu.nyu.aquery.codegen.KdbGenerator;
import edu.nyu.aquery.parse.AqueryParser$;

/**
 * GenDump: parse one AQuery program with the original Scala parser (inside
 * aquery.jar) and print the q code that the Scala code generator
 * (KdbGenerator.genExpr) makes for every expression in it.
 *
 *   java -cp tools/aquery.jar:<dir> GenDump file.a
 *
 * Test tooling only: tests/codegen/test_expr.q checks src/codegen/expr.q
 * against this output (tools/gen_expr_golden.sh makes
 * tests/codegen/expr_golden/*.txt).
 *
 * The expressions are visited in the same order as tools/AstDump.java
 * prints the tree: fields in Scala's order, list items in order, and each
 * expression before the expressions inside it. IfThen (a WHEN ... THEN
 * pair) is not printed, because genExpr does not accept it on its own; the
 * expressions inside it are.
 *
 * For each expression, five lines:
 *
 *   --- <the expression as Scala's toString prints it>
 *   plain<TAB><genExpr output>       default state
 *   grouped<TAB><...>                after a GROUP BY (grouped = true)
 *   nameAsVar<TAB><...>              names are variables (nameAsVar = true)
 *   udf<TAB><...>                    inside a FUNCTION (inUDF and nameAsVar)
 *
 * In every state the current table is "aq__t0" (it only shows in the code
 * for *). The output is escaped like AstDump (\\ \" \t \n \r), and is
 * ERROR if genExpr throws. If the program does not parse, one line:
 * FAILURE.
 */
public class GenDump {

    // The Scala code generator, and the "identity" monad its State values
    // run in (scalaz's Id; Scala finds it implicitly, Java must pass it).
    static final KdbGenerator GEN = new KdbGenerator();
    @SuppressWarnings("unchecked")
    static final scalaz.Monad<Object> ID = (scalaz.Monad<Object>) scalaz.Scalaz$.MODULE$.id();

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("usage: GenDump <file.a>");
            System.exit(2);
        }
        String source = new String(Files.readAllBytes(Path.of(args[0])), StandardCharsets.UTF_8);
        Parsers.ParseResult<?> result = AqueryParser$.MODULE$.apply(source);
        StringBuilder out = new StringBuilder();
        if (result.successful()) {
            visit(out, result.get());
        } else {
            out.append("FAILURE\n");
        }
        System.out.print(out);
    }

    /** Print every expression inside value (see the top of this file). */
    static void visit(StringBuilder out, Object value) {
        if (value instanceof Expr && !(value instanceof IfThen)) {
            print(out, (Expr) value);
        }
        if (value instanceof scala.collection.immutable.List) {
            scala.collection.Iterator<?> it = ((scala.collection.immutable.List<?>) value).iterator();
            while (it.hasNext()) {
                visit(out, it.next());
            }
            return;
        }
        if (value instanceof Option) {
            Option<?> option = (Option<?>) value;
            if (option.nonEmpty()) {
                visit(out, option.get());
            }
            return;
        }
        if (value instanceof Either) {
            Either<?, ?> either = (Either<?, ?>) value;
            visit(out, either instanceof Left ? either.left().get() : either.right().get());
            return;
        }
        // AST nodes and tuples. Other values (strings, numbers, the attr
        // maps of plan nodes) hold no expressions.
        if (value instanceof Product && !(value instanceof scala.collection.Map)) {
            Product node = (Product) value;
            for (int i = 0; i < node.productArity(); i++) {
                visit(out, node.productElement(i));
            }
        }
    }

    /** The five lines for one expression. */
    static void print(StringBuilder out, Expr e) {
        out.append("--- ").append(escape(e.toString())).append('\n');
        out.append("plain\t").append(gen(e, false, false, false)).append('\n');
        out.append("grouped\t").append(gen(e, true, false, false)).append('\n');
        out.append("nameAsVar\t").append(gen(e, false, true, false)).append('\n');
        out.append("udf\t").append(gen(e, false, true, true)).append('\n');
    }

    /** genExpr(e) run from a state with these flags, escaped. */
    static String gen(Expr e, boolean grouped, boolean nameAsVar, boolean inUDF) {
        // CodeState(queryId, tableId, currTable, grouped, nameAsVar, inUDF, renameCols)
        KdbGenerator.CodeState state =
            GEN.new CodeState(0, 0, "aq__t0", grouped, nameAsVar, inUDF, false);
        try {
            return escape((String) GEN.genExpr(e).eval(state, ID));
        } catch (RuntimeException ex) {
            return "ERROR";
        }
    }

    /** Make text safe to print on one line (same rules as AstDump). */
    static String escape(String text) {
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
