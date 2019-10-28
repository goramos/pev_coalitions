package distribution;

import org.nlogo.api.*;

public class DistributionManager extends DefaultClassManager {
	public void load(PrimitiveManager primitiveManager) {
		primitiveManager.addPrimitive("V2G", new V2G());
		primitiveManager.addPrimitive("Similarity", new Similarity());
	}
}
