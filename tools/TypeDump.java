import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import scala.Option;
import scala.collection.JavaConverters;

import edu.nyu.aquery.analysis.AnalysisError;
import edu.nyu.aquery.analysis.AnalysisTypes;
import edu.nyu.aquery.analysis.TypeChecker;
import edu.nyu.aquery.analysis.TypeChecker$;
import edu.nyu.aquery.ast.Expr;
import edu.nyu.aquery.parse.AqueryParser$;
import edu.nyu.aquery.analysis.FunctionInfo$;
import edu.nyu.aquery.analysis.BuiltInSummary;

/**
 * TypeDump: call the original Scala type checker (inside aquery.jar) and
 * print what it returns, so tests/analysis can compare the q checker with it.
 *
 *   java -cp tools/aquery.jar:<dir> TypeDump sigs
 *   java -cp tools/aquery.jar:<dir> TypeDump expr "1 + x"
 *   java -cp tools/aquery.jar:<dir> TypeDump predicate "x IN (1, 2)"
 *   java -cp tools/aquery.jar:<dir> TypeDump program file.a
 *
 * Test tooling only (like GenDump.java). Later milestones add more modes.
 *
 * Mode "sigs": every built-in function in Scala's FunctionInfo, in name
 * order. For each one, first a line with its three order flags:
 *   FLAGS<TAB>SUMS<TAB>orderDependent=1 remOrderDependence=0 usesAggregate=1
 * then one line per list of argument types (0 to 3 arguments, every
 * combination of the 6 type tags, 259 lists), with what the function's
 * signature returns for it, or "bad" when the call does not fit:
 *   SIG<TAB>SUMS<TAB>numeric,boolean<TAB>numeric
 * An empty argument list prints as "-".
 *
 * Mode "expr" (or "predicate"): parse the text with Scala's expr rule (or
 * predicate rule: IN, BETWEEN, LIKE, IS NULL) and check it with a type
 * checker that knows only the built-ins (Scala: TypeChecker()).
 *   TYPE<TAB><the expression's type>
 *   ERROR<TAB><one line per error from checkExpr, in Scala's order>
 *   PROHIBITED<TAB><one line per error from checkProhibitedExpr>
 * Text that does not parse prints one line: PARSE-FAILURE.
 * If the Scala checker crashes (it throws scala.MatchError on a CASE with
 * two or more WHEN branches), the output is one line instead:
 *   CRASH<TAB><the exception's class name>
 *
 * Mode "program": parse a whole file and type check it the way
 * "aquery.jar -tc" does: a checker that knows the file's UDFs, then every
 * statement, then all errors sorted by line and column. Two differences
 * from the jar, so that one bad statement does not hide the rest:
 * - statements are checked one at a time, and a statement the Scala
 *   checker crashes on (LOAD, SAVE, CREATE TRIGGER, DROP TRIGGER: it has
 *   no case for them) prints CRASH<TAB><statement class> and is skipped
 * - the error lines are printed with nothing else (no compiled code)
 * Output: the CRASH lines in statement order, then
 *   ERROR<TAB><message>      one per error, sorted by position
 * A file that does not parse prints one line: PARSE-FAILURE.
 */
public class TypeDump {
    // the 6 tags, in the order AnalysisTypes.scala declares them
    static final AnalysisTypes.TypeTag[] TAGS = {
        AnalysisTypes.TNumeric$.MODULE$,
        AnalysisTypes.TBoolean$.MODULE$,
        AnalysisTypes.TString$.MODULE$,
        AnalysisTypes.TUnit$.MODULE$,
        AnalysisTypes.TTable$.MODULE$,
        AnalysisTypes.TUnknown$.MODULE$,
    };

    public static void main(String[] args) throws Exception {
        if (args.length == 1 && args[0].equals("sigs")) {
            dumpSigs();
        } else if (args.length == 2 && (args[0].equals("expr") || args[0].equals("predicate"))) {
            dumpExpr(args[0], args[1]);
        } else if (args.length == 2 && args[0].equals("program")) {
            dumpProgram(args[1]);
        } else {
            System.err.println("usage: TypeDump sigs | expr <text> | predicate <text> | program <file>");
            System.exit(2);
        }
    }

    // every list of 0 to 3 tags: (), (numeric), ..., (unknown,unknown,unknown)
    static List<List<AnalysisTypes.TypeTag>> argLists() {
        List<List<AnalysisTypes.TypeTag>> out = new ArrayList<>();
        out.add(new ArrayList<>());
        int start = 0;
        for (int len = 1; len <= 3; len++) {
            int end = out.size();
            for (int i = start; i < end; i++) {
                for (AnalysisTypes.TypeTag t : TAGS) {
                    List<AnalysisTypes.TypeTag> l = new ArrayList<>(out.get(i));
                    l.add(t);
                    out.add(l);
                }
            }
            start = end;
        }
        return out;
    }

    // a Java list as a Scala immutable List (the signatures match on ::)
    static scala.collection.immutable.List<AnalysisTypes.TypeTag> toScala(List<AnalysisTypes.TypeTag> l) {
        return JavaConverters.asScalaBufferConverter(l).asScala().toList();
    }

    static String join(List<AnalysisTypes.TypeTag> l) {
        if (l.isEmpty()) return "-";
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < l.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(l.get(i).toString());
        }
        return sb.toString();
    }

    static int bit(boolean b) { return b ? 1 : 0; }

    static void dumpSigs() {
        Map<String, BuiltInSummary> info =
            JavaConverters.mapAsJavaMapConverter(FunctionInfo$.MODULE$.defaultInfo()).asJava();
        List<String> names = new ArrayList<>(info.keySet());
        Collections.sort(names);
        List<List<AnalysisTypes.TypeTag>> lists = argLists();
        for (String name : names) {
            BuiltInSummary s = info.get(name);
            System.out.println("FLAGS\t" + name
                + "\torderDependent=" + bit(s.orderDependent())
                + " remOrderDependence=" + bit(s.remOrderDependence())
                + " usesAggregate=" + bit(s.usesAggregate()));
            for (List<AnalysisTypes.TypeTag> l : lists) {
                Option<AnalysisTypes.TypeTag> r = s.signature().lift().apply(toScala(l));
                String result = r.isDefined() ? r.get().toString() : "bad";
                System.out.println("SIG\t" + name + "\t" + join(l) + "\t" + result);
            }
        }
    }

    static void dumpExpr(String rule, String text) {
        AqueryParser$ p = AqueryParser$.MODULE$;
        scala.util.parsing.combinator.Parsers.Parser<Expr> parser =
            rule.equals("expr") ? p.expr() : p.predicate();
        scala.util.parsing.combinator.Parsers.ParseResult<Expr> r = p.parse(parser, text);
        if (!r.successful()) {
            System.out.println("PARSE-FAILURE");
            return;
        }
        Expr e = r.get();
        TypeChecker checker = TypeChecker$.MODULE$.apply();
        scala.Tuple2<AnalysisTypes.TypeTag, scala.collection.Seq<AnalysisError>> res;
        try {
            res = checker.checkExpr(e);
        } catch (scala.MatchError crash) {
            System.out.println("CRASH\t" + crash.getClass().getName());
            return;
        }
        System.out.println("TYPE\t" + res._1());
        for (AnalysisError err : JavaConverters.seqAsJavaListConverter(res._2()).asJava()) {
            System.out.println("ERROR\t" + err);
        }
        for (AnalysisError err : JavaConverters.seqAsJavaListConverter(checker.checkProhibitedExpr(e)).asJava()) {
            System.out.println("PROHIBITED\t" + err);
        }
    }

    static void dumpProgram(String path) throws Exception {
        String text = new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(path)), "UTF-8");
        // the jar reads the file line by line and joins the lines with "\n"
        // (Aquery.scala: getLines().mkString("\n")), which drops a final
        // newline and turns "\r\n" into "\n"
        String[] lines = text.split("\r?\n", -1);
        int n = lines.length;
        if (n > 0 && lines[n - 1].isEmpty()) n--;
        text = String.join("\n", java.util.Arrays.copyOf(lines, n));
        AqueryParser$ p = AqueryParser$.MODULE$;
        scala.util.parsing.combinator.Parsers.ParseResult<scala.collection.Seq<edu.nyu.aquery.ast.TopLevel>> r = p.apply(text);
        if (!r.successful()) {
            System.out.println("PARSE-FAILURE");
            return;
        }
        scala.collection.Seq<edu.nyu.aquery.ast.TopLevel> prog = r.get();
        TypeChecker checker = TypeChecker$.MODULE$.apply(prog);
        List<AnalysisError> errors = new ArrayList<>();
        for (edu.nyu.aquery.ast.TopLevel stmt : JavaConverters.seqAsJavaListConverter(prog).asJava()) {
            try {
                errors.addAll(JavaConverters.seqAsJavaListConverter(checker.checkTopLevel(stmt)).asJava());
            } catch (scala.MatchError crash) {
                System.out.println("CRASH\t" + stmt.getClass().getSimpleName());
            }
        }
        // stable sort by (line, column), like Aquery.scala's sortBy
        errors.sort((a, b) -> a.pos().line() != b.pos().line()
            ? Integer.compare(a.pos().line(), b.pos().line())
            : Integer.compare(a.pos().column(), b.pos().column()));
        for (AnalysisError err : errors) {
            System.out.println("ERROR\t" + err);
        }
    }
}
