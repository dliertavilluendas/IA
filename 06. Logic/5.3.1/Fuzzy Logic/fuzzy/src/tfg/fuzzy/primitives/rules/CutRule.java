package tfg.fuzzy.primitives.rules;

import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.Syntax;

import tfg.fuzzy.primitives.implication.Cut;
import tfg.fuzzy.sets.general.EmptySet;
import tfg.fuzzy.sets.general.FuzzySet;

/**
 * This class implements the truncate-rule primitive.
 * 
 * @author Marcos Almendres.
 *
 */
public class CutRule extends DefaultReporter {

	/**
	 * This method tells Netlogo the appropriate syntax of the primitive.
	 * Receives a list and a wildcard, returns a wildcard.
	 */
	public Syntax getSyntax() {
		return Syntax.reporterSyntax(
				new int[] { Syntax.ListType(), Syntax.WildcardType() },
				Syntax.WildcardType());
	}

	/**
	 * This method respond to the call from Netlogo and returns the truncated
	 * fuzzy set after applying the rule given.
	 * 
	 * @param arg0
	 *            Arguments from Netlogo call, in this case a list.
	 * @param arg1
	 *            Context of Netlogo when the call was done.
	 * @return A fuzzy set.
	 */
	@Override
	public Object report(Argument[] arg0, Context arg1)
			throws ExtensionException, LogoException {
		double eval = 0;
		FuzzySet conseq = (FuzzySet) arg0[1].get();
		// Checks the format of the list and evaluate the rule inside.
		eval = SupportRules.simpleRulesChecks(arg0[0].getList());
		// If not a number is evaluated, return an Empty set.
		if (eval == Double.NaN) {
			return new EmptySet();
		} else {
			Cut c = new Cut();
			// Truncate the fuzzy set with evaluated value.
			return c.cutting(conseq, eval);
		}
	}

}
