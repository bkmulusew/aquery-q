import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import scala.collection.JavaConverters;
import scala.util.parsing.combinator.Parsers;

import edu.nyu.aquery.analysis.JoinAnalysis$;
import edu.nyu.aquery.analysis.OrderAnalysis;
import edu.nyu.aquery.analysis.OrderAnalysis$;
import edu.nyu.aquery.ast.ColumnAccess;
import edu.nyu.aquery.ast.Create;
import edu.nyu.aquery.ast.Expr;
import edu.nyu.aquery.ast.Filter;
import edu.nyu.aquery.ast.Join;
import edu.nyu.aquery.ast.Table;
import edu.nyu.aquery.ast.Id;
import edu.nyu.aquery.ast.OrderDirection;
import edu.nyu.aquery.ast.Query;
import edu.nyu.aquery.ast.RelAlg;
import edu.nyu.aquery.ast.RowId$;
import edu.nyu.aquery.ast.SortBy;
import edu.nyu.aquery.ast.WildCard$;
import edu.nyu.aquery.ast.TopLevel;
import edu.nyu.aquery.ast.UDF;
import edu.nyu.aquery.parse.AqueryParser$;

/**
 * OrderDump: call the original Scala order analysis (inside aquery.jar)
 * and print what it returns, so tests/analysis can compare the q version
 * (src/analysis/order.q) with it.
 *
 *   java -cp tools/aquery.jar:<dir> OrderDump funs <file.a> ...
 *   java -cp tools/aquery.jar:<dir> OrderDump cases <cases.txt>
 *   java -cp tools/aquery.jar:<dir> OrderDump cols <cases.txt>
 *   java -cp tools/aquery.jar:<dir> OrderDump plans <file.a> ...
 *   java -cp tools/aquery.jar:<dir> OrderDump joincases <cases.txt>
 *   java -cp tools/aquery.jar:<dir> OrderDump joinplans <file.a> ...
 *
 * Test tooling only (like TypeDump.java). Modes funs and cases are
 * version 7 milestone 1, cols and plans milestone 2, joincases and
 * joinplans milestone 3 (the join analysis, JoinAnalysis.scala).
 *
 * Mode "funs": for each file that parses and defines at least one UDF, a
 * block
 *   === <the file's path, as given>
 *   FUN<TAB>f<TAB>orderDependent=1 remOrderDependence=1 usesAggregate=1
 * with one FUN line per UDF, in program order. Scala judges each UDF with
 * only the UDFs defined before it (OrderAnalysis.apply folds over the
 * program), so the flags are those of OrderAnalysis(<the program up to and
 * including this UDF>) for the UDF's name.
 *
 * Mode "cases": a case file has one case per line,
 *   <context><TAB><rule><TAB><AQuery text>
 * where <context> is "-" (only the built-in functions are known) or the
 * path of a program whose UDFs are known, and <rule> is expr, predicate
 * or udf. Blank lines and lines starting with "#" are skipped. For each
 * case a block
 *   === <the case line>
 * then, for expr and predicate:
 *   OD<TAB>1        hasOrderDependence(e)
 *   AGG<TAB>0       usesAggregate(e)
 * and for udf (the UDF is analysed, not added to the context):
 *   OD<TAB>1        hasOrderDependence(udf)
 *   REM<TAB>1       removesOrderDependence(udf)
 *   AGG<TAB>1       usesAggregate(udf)
 * Text that does not parse prints one line: PARSE-FAILURE.
 *
 * Sets of columns. Scala returns columns as a Set of expressions, in a
 * hash order that means nothing. Here each column is printed as its Scala
 * toString (Id(c1), ColumnAccess(t,c1), WildCard, RowId), and a set as
 * those strings sorted and joined with a space. Anything else (only a sort
 * expression can be one) prints as <its class name>, e.g. <BinExpr>.
 *
 * Mode "cols": the same kind of case file, with rule expr, predicate or
 * exprs (several expressions separated by ";"). For expr and predicate:
 *   DIRECT<TAB><set>       directOrderDependentCols(e, collect = false)
 *   DIRECTROOT<TAB><set>   directOrderDependentCols(e, collect = true)
 *   GROUP<TAB><set>        one line per set of collectInteractions(e),
 *                          the lines sorted
 *   SORT<TAB><set>         colsToSort(List(e), collectAtRoot = false)
 *   SORTROOT<TAB><set>     colsToSort(List(e), collectAtRoot = true)
 *   ALLCOLS<TAB><set>      allCols(e)
 * and for exprs only SORT, SORTROOT and ALLCOLS, over all the expressions.
 *
 * Mode "plans": for each file that parses and has at least one query, a
 * block "=== <path>", then for every query plan, in program order (for
 * each query, or CREATE TABLE ... AS query: its WITH tables in order,
 * then the main query):
 *   PLAN<TAB><statement number, from 1> main         (or: local <name>)
 *   HASSORT<TAB>1                  hasSortBy(plan)
 * and when there is a sort (ASSUMING):
 *   SORT<TAB>Asc Id(c1), Desc ColumnAccess(t,c2)      getSort(plan)
 *   ABOVE<TAB><set>    colsToSort(e, collectAtRoot = true), where e is
 *                      the expressions of every node above the sort
 *   ABOVEALL<TAB><set> allCols(e), same e
 * (These are what the optimizer's sortToSortCols asks.) The analysis
 * knows the program's UDFs (OrderAnalysis(program)).
 *
 * Plan trees (join modes). One line per node, children indented by two
 * spaces more than their parent (a join's left side first):
 *   <node><TAB>avail=<tables>
 * where <node> is
 *   Table <name>  or  Table <name> AS <alias>
 *   Join <join type>                     e.g. Join Cross
 *   Filter <conditions>                  e.g. Filter #2  or  Filter -,-
 *   any other node: its class name       e.g. Project
 * and <tables> is the node's TABLES_AVAIL attribute (the table names
 * available there), sorted, joined with a space (empty if not set). In a
 * Filter, a condition that was placed by placeFilter prints as #k (its
 * position, from 1, in the list of conditions placed); one that was
 * already in the plan prints as -.
 *
 * Mode "joincases": one case per line, <rule><TAB><text>, blank and "#"
 * lines skipped. Each case prints "=== <the line>", then:
 *   expr or predicate <text>:
 *     USED<TAB><tables> | USED<TAB>unknown   tableNamesUsed(e)
 *     EQSEL<TAB>1                           isEqualitySelection(e)
 *   from <text> (a FROM clause):
 *     HASJOIN<TAB>1                        hasJoin(from)
 *     AVAIL<TAB><tables>                   tablesAvailable(from), names
 *     then the tree of annotateWithAvailTableNames(from)
 *   place <from text><TAB><condition> ; <condition> ; ...
 *     the tree after placeFilter(acc, c) for each condition c in order
 *     (a fold from the left, as JoinAnalysisTestSuite does), or
 *     ERROR<TAB><the exception's message> (there must be a join)
 *   Text that does not parse prints PARSE-FAILURE.
 *
 * Mode "joinplans": for each file that parses and has at least one query
 * plan with a join, a block "=== <path>", then for every plan with a join
 * (same order and labels as mode plans):
 *   PLAN<TAB><label>
 *   AVAIL<TAB><tables>                     tablesAvailable(plan)
 *   then the tree of annotateWithAvailTableNames(plan)
 * and for every Filter node in the plan whose source has a join, in
 * walk order (parent first, then children left to right):
 *   PLACE<TAB><k>   (k counts these Filters from 1)
 *   then the tree after placing that Filter's conditions on its source,
 *   last condition first (a fold from the right, as the optimizer's
 *   pushFiltersJoin does)
 */
public class OrderDump {
    public static void main(String[] args) throws Exception {
        if (args.length >= 1 && args[0].equals("funs")) {
            for (int i = 1; i < args.length; i++) dumpFuns(args[i]);
        } else if (args.length == 2 && args[0].equals("cases")) {
            dumpCases(args[1]);
        } else if (args.length == 2 && args[0].equals("cols")) {
            dumpCols(args[1]);
        } else if (args.length == 2 && args[0].equals("joincases")) {
            dumpJoinCases(args[1]);
        } else if (args.length >= 1 && args[0].equals("joinplans")) {
            for (int i = 1; i < args.length; i++) dumpJoinPlans(args[i]);
        } else if (args.length >= 1 && args[0].equals("plans")) {
            for (int i = 1; i < args.length; i++) dumpPlans(args[i]);
        } else {
            System.err.println("usage: OrderDump funs <file.a> ... | cases <cases.txt> | cols <cases.txt> | plans <file.a> ... | joincases <cases.txt> | joinplans <file.a> ...");
            System.exit(2);
        }
    }

    static int bit(boolean b) { return b ? 1 : 0; }

    // the file as the jar reads it: lines joined with "\n", no final
    // newline, "\r\n" read as "\n" (same as TypeDump.java)
    static String readProgramText(String path) throws Exception {
        String text = new String(Files.readAllBytes(Paths.get(path)), "UTF-8");
        String[] lines = text.split("\r?\n", -1);
        int n = lines.length;
        if (n > 0 && lines[n - 1].isEmpty()) n--;
        return String.join("\n", Arrays.copyOf(lines, n));
    }

    // the parsed program, or null if it does not parse
    static List<TopLevel> parseProgram(String text) {
        AqueryParser$ p = AqueryParser$.MODULE$;
        Parsers.ParseResult<scala.collection.Seq<TopLevel>> r = p.apply(text);
        if (!r.successful()) return null;
        return JavaConverters.seqAsJavaListConverter(r.get()).asJava();
    }

    static scala.collection.Seq<TopLevel> toScala(List<TopLevel> l) {
        return JavaConverters.asScalaBufferConverter(l).asScala().toList();
    }

    static void dumpFuns(String path) throws Exception {
        List<TopLevel> prog = parseProgram(readProgramText(path));
        if (prog == null) return;
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < prog.size(); i++) {
            if (!(prog.get(i) instanceof UDF)) continue;
            String name = ((UDF) prog.get(i)).n();
            OrderAnalysis oa = OrderAnalysis$.MODULE$.apply(toScala(prog.subList(0, i + 1)));
            out.append("FUN\t").append(name)
               .append("\torderDependent=").append(bit(oa.hasOrderDependence(name)))
               .append(" remOrderDependence=").append(bit(oa.removesOrderDependence(name)))
               .append(" usesAggregate=").append(bit(oa.usesAggregate(name)))
               .append("\n");
        }
        if (out.length() == 0) return;
        System.out.println("=== " + path);
        System.out.print(out);
    }

    static void dumpCases(String path) throws Exception {
        AqueryParser$ p = AqueryParser$.MODULE$;
        for (String line : Files.readAllLines(Paths.get(path))) {
            if (line.isEmpty() || line.startsWith("#")) continue;
            String[] parts = line.split("\t", 3);
            String context = parts[0], rule = parts[1], text = parts[2];
            System.out.println("=== " + line);
            OrderAnalysis oa = context.equals("-")
                ? OrderAnalysis$.MODULE$.apply()
                : OrderAnalysis$.MODULE$.apply(toScala(parseProgram(readProgramText(context))));
            if (rule.equals("udf")) {
                Parsers.ParseResult<UDF> r = p.parse(p.udf(), text);
                if (!r.successful()) { System.out.println("PARSE-FAILURE"); continue; }
                UDF u = r.get();
                System.out.println("OD\t" + bit(oa.hasOrderDependence(u)));
                System.out.println("REM\t" + bit(oa.removesOrderDependence(u)));
                System.out.println("AGG\t" + bit(oa.usesAggregate(u)));
            } else {
                Parsers.Parser<Expr> parser = rule.equals("expr") ? p.expr() : p.predicate();
                Parsers.ParseResult<Expr> r = p.parse(parser, text);
                if (!r.successful()) { System.out.println("PARSE-FAILURE"); continue; }
                Expr e = r.get();
                System.out.println("OD\t" + bit(oa.hasOrderDependence(e)));
                System.out.println("AGG\t" + bit(oa.usesAggregate(e)));
            }
        }
    }

    // a column as Scala prints it, or <class> for any other expression
    static String key(Expr e) {
        if (e instanceof Id || e instanceof ColumnAccess
            || e == WildCard$.MODULE$ || e == RowId$.MODULE$) return e.toString();
        return "<" + e.getClass().getSimpleName() + ">";
    }

    // a set of columns: the keys, sorted, joined with a space
    static String set(scala.collection.Set<Expr> s) {
        List<String> keys = new ArrayList<>();
        for (Expr e : JavaConverters.setAsJavaSetConverter(s).asJava()) keys.add(key(e));
        Collections.sort(keys);
        return String.join(" ", keys);
    }

    static scala.collection.Seq<Expr> exprSeq(List<Expr> l) {
        return JavaConverters.asScalaBufferConverter(l).asScala().toList();
    }

    static void dumpCols(String path) throws Exception {
        AqueryParser$ p = AqueryParser$.MODULE$;
        for (String line : Files.readAllLines(Paths.get(path))) {
            if (line.isEmpty() || line.startsWith("#")) continue;
            String[] parts = line.split("\t", 3);
            String context = parts[0], rule = parts[1], text = parts[2];
            System.out.println("=== " + line);
            OrderAnalysis oa = context.equals("-")
                ? OrderAnalysis$.MODULE$.apply()
                : OrderAnalysis$.MODULE$.apply(toScala(parseProgram(readProgramText(context))));
            List<Expr> es = new ArrayList<>();
            boolean ok = true;
            for (String t : rule.equals("exprs") ? text.split(";") : new String[]{text}) {
                Parsers.Parser<Expr> parser = rule.equals("predicate") ? p.predicate() : p.expr();
                Parsers.ParseResult<Expr> r = p.parse(parser, t);
                if (!r.successful()) { ok = false; break; }
                es.add(r.get());
            }
            if (!ok) { System.out.println("PARSE-FAILURE"); continue; }
            if (!rule.equals("exprs")) {
                Expr e = es.get(0);
                System.out.println("DIRECT\t" + set(oa.directOrderDependentCols(e, false)));
                System.out.println("DIRECTROOT\t" + set(oa.directOrderDependentCols(e, true)));
                List<String> groups = new ArrayList<>();
                for (scala.collection.immutable.Set<Expr> g
                         : JavaConverters.setAsJavaSetConverter(oa.collectInteractions(e)).asJava()) {
                    groups.add("GROUP\t" + set(g));
                }
                Collections.sort(groups);
                for (String g : groups) System.out.println(g);
            }
            System.out.println("SORT\t" + set(oa.colsToSort(exprSeq(es), false)));
            System.out.println("SORTROOT\t" + set(oa.colsToSort(exprSeq(es), true)));
            System.out.println("ALLCOLS\t" + set(oa.allCols(exprSeq(es))));
        }
    }

    // Scala functions for takeWhile: "is not a SortBy" and "the node itself"
    static final scala.runtime.AbstractFunction1<RelAlg, Object> NOT_SORT =
        new scala.runtime.AbstractFunction1<RelAlg, Object>() {
            public Object apply(RelAlg r) { return !(r instanceof SortBy); }
        };
    static final scala.runtime.AbstractFunction1<RelAlg, RelAlg> SAME =
        new scala.runtime.AbstractFunction1<RelAlg, RelAlg>() {
            public RelAlg apply(RelAlg r) { return r; }
        };

    static void dumpPlan(StringBuilder out, OrderAnalysis oa, String label, RelAlg plan) {
        out.append("PLAN\t").append(label).append("\n");
        boolean has = oa.hasSortBy(plan);
        out.append("HASSORT\t").append(bit(has)).append("\n");
        if (!has) return;
        List<String> pairs = new ArrayList<>();
        for (scala.Tuple2<OrderDirection, Expr> o : JavaConverters.seqAsJavaListConverter(oa.getSort(plan)).asJava()) {
            pairs.add(o._1() + " " + key(o._2()));
        }
        out.append("SORT\t").append(String.join(", ", pairs)).append("\n");
        List<Expr> above = new ArrayList<>();
        for (RelAlg r : JavaConverters.seqAsJavaListConverter(plan.takeWhile(NOT_SORT, SAME)).asJava()) {
            above.addAll(JavaConverters.seqAsJavaListConverter(r.expr()).asJava());
        }
        out.append("ABOVE\t").append(set(oa.colsToSort(exprSeq(above), true))).append("\n");
        out.append("ABOVEALL\t").append(set(oa.allCols(exprSeq(above)))).append("\n");
    }

    static void dumpQuery(StringBuilder out, OrderAnalysis oa, int n, Query q) {
        for (scala.Tuple3<String, scala.collection.immutable.List<String>, RelAlg> l
                 : JavaConverters.seqAsJavaListConverter(q.local()).asJava()) {
            dumpPlan(out, oa, n + " local " + l._1(), l._3());
        }
        dumpPlan(out, oa, n + " main", q.main());
    }

    static void dumpPlans(String path) throws Exception {
        List<TopLevel> prog = parseProgram(readProgramText(path));
        if (prog == null) return;
        OrderAnalysis oa = OrderAnalysis$.MODULE$.apply(toScala(prog));
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < prog.size(); i++) {
            TopLevel s = prog.get(i);
            if (s instanceof Query) dumpQuery(out, oa, i + 1, (Query) s);
            if (s instanceof Create && ((Create) s).source().isRight()) {
                dumpQuery(out, oa, i + 1, ((Create) s).source().right().get());
            }
        }
        if (out.length() == 0) return;
        System.out.println("=== " + path);
        System.out.print(out);
    }

    // ---- join analysis (milestone 3) ----

    static final JoinAnalysis$ JA = JoinAnalysis$.MODULE$;

    static String names(scala.collection.Set<String> s) {
        List<String> l = new ArrayList<>(JavaConverters.setAsJavaSetConverter(s).asJava());
        Collections.sort(l);
        return String.join(" ", l);
    }

    // one line per node, see "Plan trees" above; placed: the conditions
    // given to placeFilter, in order (compared by identity)
    static void tree(StringBuilder out, RelAlg r, String indent, List<Expr> placed) {
        String desc;
        if (r instanceof Table) {
            Table t = (Table) r;
            desc = "Table " + t.n() + (t.alias().isDefined() ? " AS " + t.alias().get() : "");
        } else if (r instanceof Join) {
            desc = "Join " + ((Join) r).jt();
        } else if (r instanceof Filter) {
            List<String> labels = new ArrayList<>();
            for (Expr e : JavaConverters.seqAsJavaListConverter(((Filter) r).fs()).asJava()) {
                int k = -1;
                for (int i = 0; i < placed.size(); i++) if (placed.get(i) == e) { k = i; break; }
                labels.add(k < 0 ? "-" : "#" + (k + 1));
            }
            desc = "Filter " + String.join(",", labels);
        } else {
            desc = r.getClass().getSimpleName();
        }
        out.append(indent).append(desc).append("\tavail=").append(names(JA.getAvailTableNames(r))).append("\n");
        for (RelAlg c : JavaConverters.seqAsJavaListConverter(r.children()).asJava()) {
            tree(out, c, indent + "  ", placed);
        }
    }

    // a WHERE condition: the predicate rule first, then expr (as the
    // parser's condition rule does)
    static Expr parseCondition(String text) {
        AqueryParser$ p = AqueryParser$.MODULE$;
        Parsers.ParseResult<Expr> r = p.parse(p.predicate(), text);
        if (r.successful()) return r.get();
        r = p.parse(p.expr(), text);
        return r.successful() ? r.get() : null;
    }

    static void dumpJoinCases(String path) throws Exception {
        AqueryParser$ p = AqueryParser$.MODULE$;
        for (String line : Files.readAllLines(Paths.get(path))) {
            if (line.isEmpty() || line.startsWith("#")) continue;
            String[] parts = line.split("\t");
            String rule = parts[0];
            System.out.println("=== " + line);
            StringBuilder out = new StringBuilder();
            if (rule.equals("expr") || rule.equals("predicate")) {
                Parsers.Parser<Expr> parser = rule.equals("expr") ? p.expr() : p.predicate();
                Parsers.ParseResult<Expr> r = p.parse(parser, parts[1]);
                if (!r.successful()) { System.out.println("PARSE-FAILURE"); continue; }
                scala.Option<scala.collection.immutable.Set<String>> used = JA.tableNamesUsed(r.get());
                out.append("USED\t").append(used.isDefined() ? names(used.get()) : "unknown").append("\n");
                out.append("EQSEL\t").append(bit(JA.isEqualitySelection(r.get()))).append("\n");
            } else {
                Parsers.ParseResult<RelAlg> r = p.parse(p.from(), parts[1]);
                if (!r.successful()) { System.out.println("PARSE-FAILURE"); continue; }
                RelAlg from = r.get();
                if (rule.equals("from")) {
                    out.append("HASJOIN\t").append(bit(JA.hasJoin(from))).append("\n");
                    List<String> avail = new ArrayList<>();
                    for (Table t : JavaConverters.setAsJavaSetConverter(JA.tablesAvailable(from)).asJava()) {
                        avail.add(JA.tableName(t));
                    }
                    out.append("AVAIL\t").append(names(JavaConverters.asScalaSetConverter(new java.util.HashSet<>(avail)).asScala())).append("\n");
                    tree(out, JA.annotateWithAvailTableNames(from), "", new ArrayList<>());
                } else {
                    List<Expr> conds = new ArrayList<>();
                    boolean ok = true;
                    for (String c : parts[2].split(";")) {
                        Expr e = parseCondition(c);
                        if (e == null) { ok = false; break; }
                        conds.add(e);
                    }
                    if (!ok) { System.out.println("PARSE-FAILURE"); continue; }
                    try {
                        RelAlg acc = from;
                        for (Expr c : conds) acc = JA.placeFilter(acc, c);
                        tree(out, acc, "", conds);
                    } catch (Exception ex) {
                        out.append("ERROR\t").append(ex.getMessage()).append("\n");
                    }
                }
            }
            System.out.print(out);
        }
    }

    // every Filter node of plan r whose source has a join, parent first
    static void joinFilters(RelAlg r, List<Filter> found) {
        if (r instanceof Filter && JA.hasJoin(((Filter) r).t())) found.add((Filter) r);
        for (RelAlg c : JavaConverters.seqAsJavaListConverter(r.children()).asJava()) joinFilters(c, found);
    }

    static void dumpJoinPlan(StringBuilder out, String label, RelAlg plan) {
        if (!JA.hasJoin(plan)) return;
        out.append("PLAN\t").append(label).append("\n");
        List<String> avail = new ArrayList<>();
        for (Table t : JavaConverters.setAsJavaSetConverter(JA.tablesAvailable(plan)).asJava()) avail.add(JA.tableName(t));
        out.append("AVAIL\t").append(names(JavaConverters.asScalaSetConverter(new java.util.HashSet<>(avail)).asScala())).append("\n");
        tree(out, JA.annotateWithAvailTableNames(plan), "", new ArrayList<>());
        List<Filter> filters = new ArrayList<>();
        joinFilters(plan, filters);
        for (int k = 0; k < filters.size(); k++) {
            Filter f = filters.get(k);
            List<Expr> conds = JavaConverters.seqAsJavaListConverter(f.fs()).asJava();
            RelAlg acc = f.t();
            for (int i = conds.size() - 1; i >= 0; i--) acc = JA.placeFilter(acc, conds.get(i));
            out.append("PLACE\t").append(k + 1).append("\n");
            tree(out, acc, "", conds);
        }
    }

    static void dumpJoinQuery(StringBuilder out, int n, Query q) {
        for (scala.Tuple3<String, scala.collection.immutable.List<String>, RelAlg> l
                 : JavaConverters.seqAsJavaListConverter(q.local()).asJava()) {
            dumpJoinPlan(out, n + " local " + l._1(), l._3());
        }
        dumpJoinPlan(out, n + " main", q.main());
    }

    static void dumpJoinPlans(String path) throws Exception {
        List<TopLevel> prog = parseProgram(readProgramText(path));
        if (prog == null) return;
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < prog.size(); i++) {
            TopLevel s = prog.get(i);
            if (s instanceof Query) dumpJoinQuery(out, i + 1, (Query) s);
            if (s instanceof Create && ((Create) s).source().isRight()) {
                dumpJoinQuery(out, i + 1, ((Create) s).source().right().get());
            }
        }
        if (out.length() == 0) return;
        System.out.println("=== " + path);
        System.out.print(out);
    }
}
