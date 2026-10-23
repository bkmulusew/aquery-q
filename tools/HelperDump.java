import java.lang.reflect.Method;

import scala.Option;
import scala.collection.immutable.Map;
import scala.runtime.AbstractFunction1;
import scala.runtime.AbstractPartialFunction;
import scala.util.parsing.combinator.Parsers;

import edu.nyu.aquery.ast.Expr;
import edu.nyu.aquery.ast.Join;
import edu.nyu.aquery.ast.RelAlg;
import edu.nyu.aquery.ast.SortBy;
import edu.nyu.aquery.ast.Table;
import edu.nyu.aquery.parse.AqueryParser$;

/**
 * HelperDump: parse one piece of AQuery text with the original Scala parser
 * (inside aquery.jar), call the Scala AST helpers on the result, and print
 * what they return in the golden-file format (see AstDump.java).
 *
 *   java -cp tools/aquery.jar:<dir> HelperDump expr "1 + x"
 *   java -cp tools/aquery.jar:<dir> HelperDump predicate "x IN (1, 2)"
 *   java -cp tools/aquery.jar:<dir> HelperDump query "SELECT a FROM t"
 *
 * Test tooling only: tests/ast/test_nodes.q checks src/ast/nodes.q against
 * this output (tools/gen_helper_golden.sh makes tests/ast/helper_golden.txt).
 *
 * Each result starts with a line "--- <name>", then the value as a tree.
 *
 * For an expression (rule expr or predicate, Scala ast/expr.scala):
 *   --- children            e.children
 *   --- allSubExpressions   e.allSubExpressions
 *
 * For a plan (rule query, Scala ast/query.scala, trait RelAlg):
 *   --- children            r.children
 *   --- expr                r.expr
 *   --- find Table          r.find(_.isInstanceOf[Table])
 *   --- find SortBy         r.find(_.isInstanceOf[SortBy])
 *   --- find Join           r.find(_.isInstanceOf[Join])
 *   --- takeWhile notSortBy r.takeWhile(!_.isInstanceOf[SortBy], identity)
 *   --- transform renameTables
 *         r.transform { case Table(n, a, attr) => Table(n + "_t", a, attr) }
 *   --- transform dropSort
 *         r.transform { case SortBy(t, _, _) => t }
 *
 * If the text does not parse, one line: FAILURE <TAB> message.
 */
public class HelperDump {

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("usage: HelperDump expr|predicate|query <text>");
            System.exit(2);
        }
        AqueryParser$ parser = AqueryParser$.MODULE$;
        Method rule = parser.getClass().getMethod(args[0]);
        Parsers.Parser<?> production = (Parsers.Parser<?>) rule.invoke(parser);
        Parsers.ParseResult<?> result = parser.parse(production, args[1]);
        if (!result.successful()) {
            System.out.println("FAILURE\t" + ((Parsers.NoSuccess) result).msg());
            return;
        }

        StringBuilder out = new StringBuilder();
        if (!args[0].equals("query")) {
            Expr e = (Expr) result.get();
            show(out, "children", e.children());
            show(out, "allSubExpressions", e.allSubExpressions());
        } else {
            RelAlg r = (RelAlg) result.get();
            show(out, "children", r.children());
            show(out, "expr", r.expr());
            show(out, "find Table", r.find(isA(Table.class)));
            show(out, "find SortBy", r.find(isA(SortBy.class)));
            show(out, "find Join", r.find(isA(Join.class)));
            show(out, "takeWhile notSortBy", r.takeWhile(isNotA(SortBy.class), identity()));
            show(out, "transform renameTables", r.transform(renameTables()));
            show(out, "transform dropSort", r.transform(dropSort()));
        }
        System.out.print(out);
    }

    static void show(StringBuilder out, String name, Object value) throws Exception {
        out.append("--- ").append(name).append('\n');
        AstDump.printValue(out, 0, "", value);
    }

    // Scala 2.11 functions are not Java lambdas, so each one is a small class.

    /** x => x.isInstanceOf[c] */
    static AbstractFunction1<RelAlg, Object> isA(Class<?> c) {
        return new AbstractFunction1<RelAlg, Object>() {
            public Object apply(RelAlg x) { return c.isInstance(x); }
        };
    }

    /** x => !x.isInstanceOf[c] */
    static AbstractFunction1<RelAlg, Object> isNotA(Class<?> c) {
        return new AbstractFunction1<RelAlg, Object>() {
            public Object apply(RelAlg x) { return !c.isInstance(x); }
        };
    }

    /** x => x */
    static AbstractFunction1<RelAlg, Object> identity() {
        return new AbstractFunction1<RelAlg, Object>() {
            public Object apply(RelAlg x) { return x; }
        };
    }

    /** { case Table(n, a, attr) => Table(n + "_t", a, attr) } */
    static AbstractPartialFunction<RelAlg, RelAlg> renameTables() {
        return new AbstractPartialFunction<RelAlg, RelAlg>() {
            public boolean isDefinedAt(RelAlg x) { return x instanceof Table; }
            @SuppressWarnings("unchecked")
            public <A1 extends RelAlg, B1> B1 applyOrElse(A1 x, scala.Function1<A1, B1> other) {
                if (!(x instanceof Table)) return other.apply(x);
                Table t = (Table) x;
                return (B1) new Table(t.n() + "_t", t.alias(), (Map<Object, Object>) t.attr());
            }
        };
    }

    /** { case SortBy(t, _, _) => t } */
    static AbstractPartialFunction<RelAlg, RelAlg> dropSort() {
        return new AbstractPartialFunction<RelAlg, RelAlg>() {
            public boolean isDefinedAt(RelAlg x) { return x instanceof SortBy; }
            @SuppressWarnings("unchecked")
            public <A1 extends RelAlg, B1> B1 applyOrElse(A1 x, scala.Function1<A1, B1> other) {
                if (!(x instanceof SortBy)) return other.apply(x);
                return (B1) ((SortBy) x).t();
            }
        };
    }
}
