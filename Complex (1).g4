//Djemaoui ahmed
//seifeddine khemira
grammar Complex;

// ------------------------------------------- 
//SECTION 1: CONFIGURATION GLOBALE
// -------------------------------------------

@header {
    import java.util.HashMap; // Utilisation d'une HashMap pour stocker les variables
}

@parser::members {
    // Classe TDress : Stocke le type et l'adresse mémoire des variables.
    class TDress {
        String type;    // Type de la variable (complexe ou bool)
        int address;    // Adresse mémoire associée

        public TDress(String type, int address) {
            this.type = type;
            this.address = address;
        }

        public String getType() {
            return type;
        }

        public int getAddress() {
            return address;
        }
    }

    // Table des symboles : Associe chaque IDENTIFIANT à un objet TDress.
    HashMap<String, TDress> tablesSymboles = new HashMap<>();

    // Adresse mémoire pour les variables déclarées.
    int addressVar = 0;

    // Compteur pour générer des étiquettes uniques dans les conditions.
    int IFcount = 0;

    // Compteur pour générer des étiquettes uniques dans les boucles itératives.
    int WHILEcount = 0;

 
}

// -------------------------------------------
// SECTION 2: POINT D'ENTRÉE DU PROGRAMME
// -------------------------------------------

start
	returns[String code]
	@init {
    $code = new String(); // Initialisation du code généré
}
	@after {
    $code += "HALT\n"; // Ajoute l'instruction finale pour arrêter le programme
    System.out.println($code); // Affiche le code généré
}:
	(declaration { $code += $declaration.code; })* // Gestion des déclarations de variables
	(
		instructions { $code += $instructions.code; }
	) ; // Gestion des instructions

// ------------------------------------------- SECTION 3: DÉCLARATION DES VARIABLES
// -------------------------------------------

declaration
	returns[String code]:
	TYPE IDENTIFIANT FININST {   if (tablesSymboles.containsKey($IDENTIFIANT.text)) {
            System.err.println("Erreur: Variable " + $IDENTIFIANT.text +
                               " déjà déclarée, à la ligne " + $IDENTIFIANT.getLine() +
                               ", colonne " + $IDENTIFIANT.getCharPositionInLine());
            throw new RuntimeException("Variable déjà déclarée");
        }
        if ($TYPE.text.equals("complexe")) {
            // Déclaration d'une variable complexe (4 adresses pour la partie réelle et imaginaire).

            tablesSymboles.put($IDENTIFIANT.text, new TDress($TYPE.text, addressVar));

            addressVar += 4; // Alloue 4 cases mémoire

            $code = "PUSHF 0.0\nPUSHF 0.0\n"; // Initialisation des deux parties à 0.0

        } else if ($TYPE.text.equals("bool")) {
            // Déclaration d'une variable booléenne (1 adresse).

            tablesSymboles.put($IDENTIFIANT.text, new TDress($TYPE.text, addressVar));

            addressVar += 1; // Alloue 1 case mémoire

            $code = "PUSHI 0\n"; // Initialisation à FALSE (0)
        }
    };

// ------------------------------------------- 
//SECTION 4: INSTRUCTIONS
// -------------------------------------------

instructions
	returns[String code]
	@init {
    $code = new String(); // Initialisation des instructions
}:
	(instruction { $code += $instruction.code; })* ; // Accumule les codes des instructions

// ------------------------------------------- SECTION 5: GESTION DES INSTRUCTIONS
// -------------------------------------------

instruction
	returns[String code]:
	affectation FININST { $code = $affectation.code; } // Gestion des affectations
	| iterative { $code = $iterative.code; } // Gestion des boucles itératives
	| conditionnelle { $code = $conditionnelle.code; } // Gestion des conditions
	| affichage FININST { $code = $affichage.code; } // Gestion des affichages
	| lecture {$code= $lecture.code;};// Gestion des lectures

// ------------------------------------------- 
//SECTION 6: AFFECTATION DES VALEURS
// -------------------------------------------

affectation
	returns[String code]:
	IDENTIFIANT '=' (expression | predicat) {
        TDress td = tablesSymboles.get($IDENTIFIANT.text);

    // Vérifier si la variable existe
    if (td == null) {
        System.err.println("Erreur: Variable " + $IDENTIFIANT.text +
                           " non déclarée, à la ligne " + $IDENTIFIANT.getLine() +
                           ", colonne " + $IDENTIFIANT.getCharPositionInLine());
        throw new RuntimeException("Variable non déclarée"); // Optionnel, selon le comportement souhaité
    }
    
    // Vérifier le type de la variable pour générer le code d'affectation
    if (td.getType().equals("complexe")) {
        // Affectation à une variable complexe
        $code = $expression.code + "STOREG " + (td.getAddress() + 3) + "\n" +
                "STOREG " + (td.getAddress() + 2) + "\n" +
                "STOREG " + (td.getAddress() + 1) + "\n" +
                "STOREG " + td.getAddress() + "\n";
    } else if (td.getType().equals("bool")) {
        // Affectation à une variable booléenne
        $code = $predicat.code + "STOREG " + td.getAddress() + "\n";
    } else {
        // Gérer les types non supportés
        System.err.println("Erreur: Type non supporté pour la variable " + $IDENTIFIANT.text +
                           ", à la ligne " + $IDENTIFIANT.getLine() +
                           ", colonne " + $IDENTIFIANT.getCharPositionInLine());
        throw new RuntimeException("Type non supporté");
    }
};

// --------------------------------------------
// SECTION 7: ITERATIVE
// --------------------------------------------
iterative
	returns[String code]
	@init {
    WHILEcount+=1;
    String labelwhile ="while"+WHILEcount;
    String  endwhile = "fwhile"+WHILEcount;
    String sinonwhile  ="snwhile"+WHILEcount;
    String INST = new String();
}:
	'repeter' (
		c = instruction {
        INST +=$c.code;
}
		| d = iterativeInstuction {

        if($d.val == 0){
           INST+=$d.code+sinonwhile+"\n";       
        }else{
            INST+=$d.code+labelwhile+"\n";   
        }
    }
	)+ 'jusque' predicat 'sinon' b = instruction {
   

    $code= "LABEL "+labelwhile+"\n"+INST+$predicat.code+"JUMPF "+labelwhile
           +"\nJUMP "+endwhile+"\nLABEL "+sinonwhile+"\n"+$b.code+"LABEL "+endwhile+"\n";           
                        
};
iterativeInstuction
	returns[String code, int val]
	@inti {
    String code = new String();

}:
	'lorsque' predicat 'faire' ('break') FININST FININST {   $val= 0;
    $code =$predicat.code+"PUSHI 0\nEQUAL\nJUMPF ";
}
	| 'lorsque' predicat 'faire' ('continue') FININST FININST {   $val =1;
    $code =$predicat.code+"PUSHI 0\nEQUAL\nJUMPF ";
};

// ------------------------------------------- SECTION 7: affichage
// -------------------------------------------

affichage
	returns[String code]:
	'afficher' '(' expression ')' {
        // Generate code to display real and partie imaginaires.
        $code = $expression.code + "WRITEF\nFREE 2\nWRITEF\nFREE 2\n";
    };

// ------------------------------------------- 
//SECTION 8: CONDITIONALS
// -------------------------------------------

conditionnelle
	returns[String code]:
	'lorsque' predicat 'faire' a = instructions {
        IFcount++;
        String fsi = "end" + String.valueOf(IFcount);
        $code = $predicat.code + "JUMPF " + fsi + "\n" + $a.code + "LABEL " + fsi + "\n";
    } (
		'autrement' b = instructions {
        String sinon = "else" + String.valueOf(IFcount);
        $code = $predicat.code + "JUMPF " + sinon + "\n" +
                $a.code + "JUMP " + fsi + "\n" +
                "LABEL " + sinon + "\n" + $b.code + "LABEL " + fsi + "\n";
    }
	)? FININST;
// ------------------------------------------- SECTION 9: lecture
// -------------------------------------------
lecture
	returns[String code]:
	'lire(' IDENTIFIANT ')' FININST {
        TDress td = tablesSymboles.get($IDENTIFIANT.text);
         // Vérifier si la variable existe
    if (td == null) {
        System.err.println("Erreur: Variable " + $IDENTIFIANT.text +
                           " non déclarée, à la ligne " + $IDENTIFIANT.getLine() +
                           ", colonne " + $IDENTIFIANT.getCharPositionInLine());
        throw new RuntimeException("Variable non déclarée"); // Optionnel, selon le comportement souhaité
    }
        
        if (td.getType().equals("complexe")) {
            // Affectation à une variable complexe.
            $code ="READF\nSTOREG " + (td.getAddress() + 3) + "\n" +
                    "STOREG " + (td.getAddress() + 2) + "\nREADF\n" +
                    "STOREG " + (td.getAddress() + 1) + "\n" +
                    "STOREG " + td.getAddress() + "\n";
        } else if (td.getType().equals("bool")) {
            // Affectation à une variable booléenne.
            $code ="READ\nSTOREG " + td.getAddress() + "\n";
        }
    };

// ------------------------------------------- 
//SECTION 10: EXPRESSIONS
// -------------------------------------------

expression
	returns[String code, String reel, String imag]:
	'-(' a = expression ')' {
        // Unary minus for complex expressions.
        $reel = "PUSHF 0.0\n" + $a.reel + "FSUB\n";
        $imag = "PUSHF 0.0\n" + $a.imag + "FSUB\n";
        $code = $reel + $imag;
    }
	| sosub {
        $reel = $sosub.reel;
        $imag = $sosub.imag;
        $code = $reel + $imag;
    };

sosub
	returns[String code, String reel, String imag]:
	mudiv '+' a = sosub {
        // addition des expressions complexes.
        // partie reel: a + c
        // partie imaginaire: b + d
        $reel = $mudiv.reel + $a.reel + "FADD\n";
        $imag = $mudiv.imag + $a.imag + "FADD\n";
        $code = $reel + $imag;
    }
	| mudiv '-' a = sosub {
	    // Subtraction des expressions complexes.
	    // partie reel: a - c
	    // partie imaginaire: b - d
        $reel = $mudiv.reel + $a.reel + "FSUB\n";
        $imag = $mudiv.imag + $a.imag + "FSUB\n";
        $code = $reel + $imag;
    }
	| mudiv {
        $reel = $mudiv.reel;
        $imag = $mudiv.imag;
        $code = $reel + $imag;
    };

mudiv
	returns[String code, String reel, String imag]:
	paren '/' a = mudiv {
	   // Division des expressions complexes.
        // Denominator: c² + d²
        String denom = $paren.reel + $paren.reel + "FMUL\n" +
                       $paren.imag + $paren.imag + "FMUL\nFADD\n";

        // partie reel: (a*c + b*d) / (c² + d²)
        $reel = $paren.reel + $a.reel + "FMUL\n" +
                $paren.imag + $a.imag + "FMUL\nFADD\n" +
                denom + "FDIV\n";

        // partie imaginaire: (b*c - a*d) / (c² + d²)
        $imag = $paren.imag + $a.reel + "FMUL\n" +
                $paren.reel + $a.imag + "FMUL\nFSUB\n" +
                denom + "FDIV\n";

        $code = $reel + $imag;
    }
	| paren '*' a = mudiv {
	   // Multiplication des expressions complexes.
        // partie reel: a*c - b*d
        // partie imaginaire: a*d + b*c
        $reel = $paren.reel + $a.reel + "FMUL\n" +
                $paren.imag + $a.imag + "FMUL\nFSUB\n";
        $imag = $paren.reel + $a.imag + "FMUL\n" +
                $paren.imag + $a.reel + "FMUL\nFADD\n";
        $code = $reel + $imag;
    }
	| paren {
        $reel = $paren.reel;
        $imag = $paren.imag;
        $code = $reel + $imag;
    };

// ----------------------
// calcul de puissance 
//-----------------------
puissance
	returns[String code, String reel, String imag]:
	'(' expression ')' '**' ENTIER {
        int n = Integer.parseInt($ENTIER.text);
        // For n == 0, result is 1+0i
        if (n == 0) {
            $reel = "PUSHF 1.0\n";
            $imag = "PUSHF 0.0\n";
            $code = $reel + $imag;
        }
        // For n == 1, lui-même
        else if (n == 1) {
            $reel = $expression.reel;
            $imag = $expression.imag;
            $code = $reel + $imag;
        }
        // For n > 1,multiplication répétée
        else {
            String baseReel = $expression.reel;
            String baseImag = $expression.imag;

            // Initialization (n = 1)
            $reel = baseReel;
            $imag = baseImag;

            // Mutiplication repetee (n - 1 times)
            for (int i = 1; i < n; i++) {
                String tempReel = $reel;
                String tempImag = $imag;

                // partie reel: (a * c) - (b * d)
                $reel = tempReel + baseReel + "FMUL\n" + tempImag + baseImag + "FMUL\nFSUB\n";

                // partie imaginaire: (a * d) + (b * c)
                $imag = tempReel + baseImag + "FMUL\n" + tempImag + baseReel + "FMUL\nFADD\n";
            }

            $code = $reel + $imag;
        }
    };

// ------------------------------------------- SECTION 10: PARENTHESIZED EXPRESSIONS
// -------------------------------------------

paren
	returns[String code, String reel, String imag]:
	'(' expression ')' {
        $reel = $expression.reel;
        $imag = $expression.imag;
        $code=$reel+$imag;
    }
	| comp {
        $reel = $comp.reel;
        $imag = $comp.imag;
        $code=$reel+$imag;
    }
	| IDENTIFIANT {
        TDress td = tablesSymboles.get($IDENTIFIANT.text);
         // Vérifier si la variable existe
    if (td == null) {
        System.err.println("Erreur: Variable " + $IDENTIFIANT.text +
                           " non déclarée, à la ligne " + $IDENTIFIANT.getLine() +
                           ", colonne " + $IDENTIFIANT.getCharPositionInLine());
        throw new RuntimeException("Variable non déclarée"); // Optionnel, selon le comportement souhaité
    }
        if(td.getType().equals("complexe")){  
            $code = "PUSHG " + td.getAddress() + "\n" +
                    "PUSHG " + (td.getAddress() + 1) + "\n" +
                    "PUSHG " + (td.getAddress() + 2) + "\n" +
                    "PUSHG " + (td.getAddress() + 3) + "\n";
            $reel = "PUSHG " + td.getAddress() + "\n" +
                    "PUSHG " + (td.getAddress() + 1) + "\n";
            $imag = "PUSHG " + (td.getAddress() + 2) + "\n" +
                    "PUSHG " + (td.getAddress() + 3) + "\n";
                    }else{
                            // gerer les error de type
                            System.err.println("Erreur:Variable Boolean dans une expression Complex " + $IDENTIFIANT.text +
                                               ", à la ligne " + $IDENTIFIANT.getLine() +
                                               ", colonne " + $IDENTIFIANT.getCharPositionInLine());
                            throw new RuntimeException("Error de type");
                        }
    }
	| 'reel(' expression ')' {
        $reel = $expression.reel;
        $imag = "PUSHF 0.0\n";
        $code = $reel + $imag;
    }
	| 'im(' expression ')' {
        $imag = $expression.imag;
        $reel = "PUSHF 0.0\n";
        $code = $reel + $imag;
    }
    // (condition) ? a : b expresion conditionnelle
	| predicat '?' a = expression ':' b = expression {
        IFcount++;
        $reel=$predicat.code +"JUMPF else"+IFcount+"\n"+$a.reel+"\nJUMP end"+IFcount+"\nLABEL else"+IFcount
              +"\n"+$b.reel+"LABEL end"+IFcount+"\n";
        IFcount++;
        $imag=$predicat.code +"JUMPF else"+IFcount+"\n"+$a.imag+"\nJUMP end"+IFcount+"\nLABEL else"+IFcount
              +"\n"+$b.imag+"LABEL end"+IFcount+"\n";
        $code=$reel+$imag;      
    }
    //puissance (a)**n
	| puissance {
        $reel =$puissance.reel;
        $imag =$puissance.imag;
        $code=$reel+$imag;
    };

// ------------------------------------------- SECTION 11: BOOLEAN EXPRESSIONS
// -------------------------------------------

predicat
	returns[String code]:
	a = predicat 'or' inter {
        // Logical OR operation.
        $code = $a.code + $inter.code + "ADD\n";
    }
	| inter {
        $code = $inter.code;
    };

inter
	returns[String code]:
	a = inter 'and' b = expressionBool {
        // Logical AND operation.
        $code = $a.code + $b.code + "MUL\n";
    }
	| b = expressionBool {
        $code = $b.code;
    };

expressionBool
	returns[String code]:
	'(' predicat ')' {
        $code = $predicat.code;
    }
	| 'not(' predicat ')' {
        // Logical NOT operation.
        $code = $predicat.code + "PUSHI 0\nEQUAL\n";
    }
	| BOOL {
        // Boolean constants.
        if ($BOOL.text.equals("TRUE")) {
            $code = "PUSHI 1\n";
        } else {
            $code = "PUSHI 0\n";
        }
    }
	| '|' a = expression '|' '==' '|' b = expression '|' {
        // Egalite.
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFEQUAL\n";
    }
	| '|' a = expression '|' '<>' '|' b = expression '|' {
        // Inegalitie .
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFNEQ\n";
    }
	| '|' a = expression '|' '<' '|' b = expression '|' {
        // Less than comparison of magnitudes.
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFINF\n";
    }
	| '|' a = expression '|' '>' '|' b = expression '|' {
        // Greater than comparison of magnitudes.
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFSUP\n";
    }
	| '|' a = expression '|' '<=' '|' b = expression '|' {
        // Less than or equal comparison of magnitudes.
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFINFEQ\n";
    }
	| '|' a = expression '|' '>=' '|' b = expression '|' {
        // Greater than or equal comparison of magnitudes.
        $code = $a.reel + $a.reel + "FMUL\n" +
                $a.imag + $a.imag + "FMUL\nFADD\n" +
                $b.reel + $b.reel + "FMUL\n" +
                $b.imag + $b.imag + "FMUL\nFADD\nFSUPEQ\n";
    }
	| IDENTIFIANT {
        // Boolean variable.
        TDress td = tablesSymboles.get($IDENTIFIANT.text);
         // Vérifier si la variable existe
        if (td == null) {
        System.err.println("Erreur: Variable " + $IDENTIFIANT.text +
                           " non déclarée, à la ligne " + $IDENTIFIANT.getLine() +
                           ", colonne " + $IDENTIFIANT.getCharPositionInLine());
        throw new RuntimeException("Variable non déclarée"); // Optionnel, selon le comportement souhaité
        }
        if (td.getType().equals("bool")) {  
            $code = "PUSHG " + td.getAddress() + "\n";
        } else {
           System.err.println("Erreur:Variable Complex dans une expression Boolean " + $IDENTIFIANT.text +
                                               ", à la ligne " + $IDENTIFIANT.getLine() +
                                               ", colonne " + $IDENTIFIANT.getCharPositionInLine());
                            throw new RuntimeException("Error de type");
        }
    };

// -------------------------------------------
// SECTION 12: COMPLEX NUMBER REPRESENTATION
// -------------------------------------------

comp
	returns[String code, String reel, String imag]:
	a = flotant PI b = flotant {
        //form algerbrique a + ib.
        $reel = $a.code;
        $imag = $b.code;
        $code = $reel + $imag;
    }
	| a = flotant {
        // Real number as complex with partie imaginaire 0.
        $reel = $a.code;
        $imag = "PUSHF 0.0\n";
        $code = $reel + $imag;
    }
	| I f = flotant {
        // Purely imaginary number.
        $reel = "PUSHF 0.0\n";
        $imag = $f.code;
        $code = $reel + $imag;
    }
	| a = flotant ':' b = flotant {   
          // forme polaire r :0.
        double radians = Math.toRadians(Float.valueOf($b.value0));
        double cos0 = Math.cos(radians);
        double sin0 = Math.sin(radians);
        $reel = $a.code + "PUSHF " + cos0 + "\nFMUL\n";
        $imag = $a.code + "PUSHF " + sin0 + "\nFMUL\n";
        $code = $reel + $imag;
    }
	| a = flotant 'e^i' b = flotant {
        // form  exponentialr e^i0.
        double radians = Math.toRadians(Float.valueOf($b.value0));
        double cos0 = Math.cos(radians);
        double sin0 = Math.sin(radians);
        $reel = $a.code + "PUSHF " + cos0 + "\nFMUL\n";
        $imag = $a.code + "PUSHF " + sin0 + "\nFMUL\n";
        $code = $reel + $imag;
    };

// ------------------------------------------- 
//SECTION 13: FLOATING-POINT NUMBERS
// -------------------------------------------

flotant
	returns[String code, float value0]:
	a = ENTIER '.' b = ENTIER {
        // Floating-point number with integer and fractional parts.
        $code = "PUSHF " + $a.text + "." + $b.text + "\n";
        $value0 = Float.valueOf($a.text + "." + $b.text);
    }
	| '.' b = ENTIER {
        // Floating-point number with fractional part only.
        $code = "PUSHF 0." + $b.text + "\n";
        $value0 = Float.valueOf("0." + $b.text);
    }
	| ENTIER {
        // Integer as floating-point number.
        $code = "PUSHF " + $ENTIER.text + ".0\n";
        $value0 = Float.valueOf($ENTIER.text + ".0");
	    }
	| '-' a = ENTIER '.' b = ENTIER {
        // Floating-point number with integer and fractional parts.
        $code = "PUSHF 0.0 \nPUSHF " + $a.text + "." + $b.text + "\nFSUB\n";
        $value0 = Float.valueOf($a.text + "." + $b.text);
    }
	| '-' '.' b = ENTIER {
        // Floating-point number with fractional part only.
        $code = "PUSHF 0.0 \nPUSHF 0." + $b.text + "\nFSUB\n";
        $value0 = Float.valueOf("0." + $b.text);
    }
	| '-' ENTIER {
        // Integer as floating-point number.
        $code = "PUSHF 0.0 \nPUSHF " + $ENTIER.text + ".0\nFSUB\n";
        $value0 = Float.valueOf($ENTIER.text + ".0");
    }
	;

// ------------------------------------------- LEXER RULES
// -------------------------------------------

TYPE: 'complexe' | 'bool'; // Variable types
BOOL: 'TRUE' | 'FALSE'; // Boolean constants
I: 'i'; // Imaginary unit
PI: '+i'; // Purely imaginary unit
IDENTIFIANT: [a-zA-Z]+ [0-9]*; // Identifiers
WS: (' ' | '\t' | '\n')+ -> skip; // Ignore whitespace
ENTIER: ('0' ..'9')+; // Integer literals
FININST: ';'; // Statement terminator
NEWLINE: ('\n')+; // Newline characters
UNMATCH: . -> skip; // Skip unmatched characters


//--------------------------Debut-------------------------------

//toutes fonctions demander a etait implimenter
// pour eviter des embiguites on'a ajouter des point vergule a la fin de certaine boucle
//voici les syntaxes des command:
//-------------------------------------
//1-declaration des variables:
//TYPE IDENTIFIANT;
//-------------------------------------
//2-affectation des variables:
//IDENTIFIANT = expression;
//-------------------------------------
//3-les boucles itératives:
//repeter bloc_inst jusque ExpConditionnelle
//sinon instruction

//pour les instruction iteratives:
//lorsque ExpConditionnelle faire break;
//lorsque ExpConditionnelle faire continue;

//remaque:si vous utiliser break ou continue pas d'autre instriuction dans cette Intruction conditionnelle

//-------------------------------------
//4-les conditions:
//lorsque ExpConditionnelle faire
// bloc_inst (Point-vergule pour signifier la fin du bloc)
//ou
//lorsque ExpConditionnelle faire
// bloc_inst autrement bloc_inst (Point-vergule pour signifier la fin du bloc)
//-------------------------------------
//5-les affichages:
//afficher(expression);
//-------------------------------------
//6-les lectures: 
//lire(IDENTIFIANT);
//-------------------------------------
//7-les expressions:
//expression : 
            //-expression
            //| expression + expression
            //| expression - expression
            //| expression * expression
            //| expression / expression
            //| (expression) ** ENTIER
            //| (expression)
            //| IDENTIFIANT
            //| reel(expression)
            //| im(expression)
            //| predicat ? expression : expression
 //remarqque: on ajouter desn parenthese pour la puissance pour eviter des ambiguites
//-------------------------------------
//8-les predicats:
//predicat :
          //predicat or predicat
          // predicat and predicat
          // not(predicat)
          // |expression| == |expression|
          // |expression| <> |expression|
          // |expression| < |expression|
          // |expression| > |expression|
          // |expression| <= |expression|
          // |expression| >= |expression|
          // IDENTIFIANT;

 //remarqque: on ajouter desn parenthese pour la negation pour eviter des ambiguites et || meme pour nombre complexe         
//-------------------------------------
//9-les nombres complexes:
                  //	flotant+ i flotant
                  //	flotant
                  //	i flotant
                  //	flotant: flotant 
                  //     flotant e ^i flotant
                  //     floatant:flotant
                  //    -flotant+ i -flotant
                  //    -flotant
                  //    i -flotant 
   //flotant 
    //ENTIER . ENTIER
    // . ENTIER
    //ENTIER;

//--------------------------FIN-------------------------------
