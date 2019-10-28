package distribution;

import java.util.Random;

import org.nlogo.api.*;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;
import org.nlogo.core.LogoList;

public class V2G implements Reporter {
	//Recebe uma lista (coalizão) e um número (constante); retorna um número (valor da coalizão)
	public Syntax getSyntax() {
		return SyntaxJ.reporterSyntax(new int[] {Syntax.ListType(), Syntax.NumberType(), Syntax.NumberType(), Syntax.NumberType(), Syntax.NumberType(), Syntax.NumberType()}, Syntax.ListType());
	}
	
	public Object report(Argument args[], Context context) throws ExtensionException {
		
		//Parâmetros recebidos
		LogoList coalizao;
		double p=0.5; //preço da unidade de energia
		double gamma=7; //tamanho máximo da coalizão
		double delta=15; //quantidade máxima de energia na coalizão
		double epsilon=0.9; //incentivo máximo dado pelo grid
		int constante;
		
		//Soma da quantidade de energia
    	double Ec=0;
		
		//Lê os parâmetros
		try {
			coalizao = args[0].getList();
			p = args[1].getDoubleValue();
			gamma = args[2].getDoubleValue();
			delta = args[3].getDoubleValue();
			epsilon = args[4].getDoubleValue();
			constante = args[5].getIntValue();
			
		}
		catch(LogoException e) {
			throw new ExtensionException( e.getMessage() ) ;
		}
		
		//Se a coalizão é menor que 2 e maior que gamma, retorna 0 
    	if (coalizao.size() < 2 || coalizao.size() > gamma) return 0;//new Double(0);
		
    	//Não precisa verificar restrições entre os agentes, pois na versão do NetLogo 
    	//os agentes só testarão coalizões válidas, i.e., apenas com quem é seu vizinho
    	
    	//Quantidade de energia da coalizão
    	for (int i = 0; i < coalizao.size(); i++) {
    		int agente = (int)((Double)coalizao.get(i)).doubleValue();
    		Random r = new Random(agente*constante);//O número é sempre o mesmo para o agente e a constante em questão
    		Ec += r.nextDouble() * 2 + 1;//De 1 a 3 kWh
    	}
    	
    	return Math.min(Math.pow(Ec/delta,2)*epsilon, epsilon) * p;
	}
	
}