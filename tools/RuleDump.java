import java.lang.reflect.Method;

import scala.util.parsing.combinator.Parsers;
import scala.util.parsing.input.Position;

import edu.nyu.aquery.parse.AqueryParser$;

/**
 * RuleDump: parse a piece of AQuery text with ONE grammar rule of the
 * original Scala parser (inside aquery.jar) and print the result the way
 * Scala prints it (its toString), e.g.
 *
 *   java -cp tools/aquery.jar:<dir> RuleDump expr "1 + x"
 *   BinExpr(Plus,IntLit(1),Id(x))
 *
 * or, if the text does not parse as that rule (the whole text must be used):
 *
 *   FAILURE <TAB> line:column <TAB> message
 *
 * Test tooling only: the expected values in tests/parser/test_parser.q
 * were produced with it, so they are what Scala really does.
 *
 * With -tree first, a successful parse is printed as an indented tree in
 * the golden-file format instead (see AstDump.java):
 *
 *   java -cp tools/aquery.jar:<dir> RuleDump -tree expr "1 + x"
 *
 * rule is the name of a rule in AqueryParser.scala: expr, query, from,
 * where, predicate, udf, create, ... (any method returning a Parser).
 */
public class RuleDump {

    public static void main(String[] args) throws Exception {
        boolean tree = args.length == 3 && args[0].equals("-tree");
        if (tree) {
            args = new String[] { args[1], args[2] };
        }
        if (args.length != 2) {
            System.err.println("usage: RuleDump [-tree] <rule> <text>");
            System.exit(2);
        }
        AqueryParser$ parser = AqueryParser$.MODULE$;

        // Each grammar rule is a no-argument method (or lazy val) returning
        // a Parser, so it can be looked up by name.
        Method rule = parser.getClass().getMethod(args[0]);
        Parsers.Parser<?> production = (Parsers.Parser<?>) rule.invoke(parser);

        // parse(prod, s) lexes s and requires prod to use all of it.
        Parsers.ParseResult<?> result = parser.parse(production, args[1]);
        if (result.successful() && tree) {
            StringBuilder out = new StringBuilder();
            AstDump.printValue(out, 0, "", result.get());
            System.out.print(out);
        } else if (result.successful()) {
            System.out.println(result.get());
        } else {
            Parsers.NoSuccess failure = (Parsers.NoSuccess) result;
            Position pos = failure.next().pos();
            System.out.println("FAILURE\t" + pos.line() + ":" + pos.column() + "\t" + failure.msg());
        }
    }
}
