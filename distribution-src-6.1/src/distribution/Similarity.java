package distribution;

import java.util.Random;

import org.nlogo.api.*;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;
import org.nlogo.core.LogoList;

public class Similarity implements Reporter {

	public Syntax getSyntax() {
		return SyntaxJ.reporterSyntax(new int[] {
				Syntax.ListType(), 
				Syntax.ListType(), 
				Syntax.NumberType(), 
				Syntax.NumberType(), 
				Syntax.NumberType(), 
				Syntax.NumberType(),
				Syntax.BooleanType()
			}, Syntax.ListType());
	}
	
	public Object report(Argument args[], Context context) throws ExtensionException {
		
		//Parâmetros recebidos
		LogoList C;          //elementos da coalizão (ordenado)
		LogoList T;          //tempo de partida de cada elemento da coalizão (desordenado)
		double epsilon=0.9;  //incentivo máximo dado pelo grid
		double p=0.5;        //preço da unidade de energia
		double c0=1000.0;    //constante normalizadora
		int c1=12345;        //constante para definir potência do agente
		boolean diffW=false; //se deve considerar potências diferentes para os veículos (true) ou se todos devem ter a mesma (false)
		
		//Parâmetros a serem calculados
		double Tc=Double.MAX_VALUE; //duração da coalizão
		double Wc=0.0;              //potência da coalizão
		
		//Lê os parâmetros
		try {
			C       = args[0].getList();
			T       = args[1].getList();
			epsilon = args[2].getDoubleValue();
			p       = args[3].getDoubleValue();
			c0      = args[4].getDoubleValue();
			c1      = args[5].getIntValue();
			diffW   = args[6].getBooleanValue();
		}
		catch(LogoException e) {
			throw new ExtensionException( e.getMessage() ) ;
		}
		
		//Se a coalizão é menor que 2, retorna 0 
    	if (C.size() < 2) 
    		return 0;//new Double(0);
		
    	//Calcula a duração da coalizão (menor tempo)
    	for (int i = 0; i < T.size(); i++) {
    		if ((Double)T.get(i) < Tc)
    			Tc = (Double)T.get(i);
    	}
    	
		//Calcula a potência da coalizão
    	for (int i = 0; i < C.size(); i++) {
    		int agente = (int)((Double)C.get(i)).doubleValue();
    		Random r = new Random(agente*c1); //O número é sempre o mesmo para o agente e a constante em questão
    		if (diffW)
    			Wc += r.nextDouble() * 2 + 1; //De 1 a 3 kWh
    		else
    			Wc += 3.3;//todos iguais
    	}
		
		return Math.min((Tc * Wc / c0) * epsilon, epsilon) * p;
	}

}
