package tfg.fuzzy.primitives.creation;

import java.util.List;

import org.nlogo.api.Argument;
import org.nlogo.api.Context;
import org.nlogo.api.DefaultReporter;
import org.nlogo.api.ExtensionException;
import org.nlogo.api.LogoException;
import org.nlogo.api.Syntax;

import tfg.fuzzy.general.SupportFunctions;
import tfg.fuzzy.sets.points.PiecewiseLinearSet;

/**
 * This class creates a new piecewise linear set. Implements the primitive
 * "piecewise-linear-set".
 * 
 * @author Marcos Almendres.
 *
 */
public class PiecewiseLinear extends DefaultReporter {

	/**
	 * This method tells Netlogo the appropriate syntax of the primitive.
	 * Receives a list and returns a Wildcard.
	 */
	public Syntax getSyntax() {
		return Syntax.reporterSyntax(new int[] { Syntax.ListType() },
				Syntax.WildcardType());
	}

	/**
	 * This method respond to the call from Netlogo and returns the set.
	 * 
	 * @param arg0
	 *            Arguments from Netlogo call, in this case a list.
	 * @param arg1
	 *            Context of Netlogo when the call was done.
	 * @return A new PiecewiseLinearSet.
	 */
	@Override
	public Object report(Argument[] arg0, Context arg1)
			throws ExtensionException, LogoException {
		double[] universe = new double[] { Double.POSITIVE_INFINITY,
				Double.NEGATIVE_INFINITY };
		// Checks the list has at least 2 elements
		if (arg0[0].getList().size() < 2) {
			throw new ExtensionException("At least 2 points must be provided");
		}
		// Checks the format of the list and store the parameters in a list.
		List<double[]> ej = SupportFunctions.checkListFormat(arg0[0].getList());
		// Sets the universe
		universe[0] = ej.get(0)[0];
		universe[1] = ej.get(ej.size() - 1)[0];
		// Create and return the new set.
		return new PiecewiseLinearSet(ej, true, "piecewise", universe);
	}
}
