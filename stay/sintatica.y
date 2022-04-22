%{
#include <iostream>
#include <string>
#include <sstream>
#include <stdlib.h>
#include <vector>

#define YYSTYPE atributos

using namespace std;

int var_lace_qnt;
int var_cond_qnt;
int var_linha_qnt = 1;
int var_lace_name_qnt = 0;

string error = "";
string warning = "";
string contLinha = "";
string declaracoes = "";



struct atributos
{
	string label;
	string traducao;
	string tipo;
	string conteudo;
};

typedef struct
{
	string nomeVariavel;
	string tipoVariavel;
	string tempVariavel;
	string strSize;
	string conteudo;
} TIPO_SIMBOLO;

typedef struct
{
	string nomeLaco;
	string tipoLaco;
	string fimLaco;
	string contexto;
}	TIPO_LOOP;

typedef struct
{
	int indice;
	string caracter;
} TABELA_ASCII;


vector<TIPO_LOOP> tabelaLoop;
vector<vector<TIPO_SIMBOLO>> mapa;
int contextoGlobal;


string strGeralSize = "500";
int var_temp_qnt;
int num_jump;
vector<TIPO_SIMBOLO> global_escopo;
vector<TABELA_ASCII> table_ascii; 

string label_jump();
string gentempcode();

string genLacecode();
string genCondcode();
string genLaceNameCode();


void print_table();
bool buscaVariavel(string variavel);
void addSimbolo(string nome, string tipo, string temp);
void addStr(string nome, string tipo, string temp, string conteudo);
TIPO_SIMBOLO getSimbolo(string variavel);
string cast(string tipo1, string tipo2);
bool comparaTipo(string tipo1, string tipo2);
void inicializaAscii();
void print_var(TIPO_SIMBOLO);
void relacionalInvalida(string tipo1, string tipo2);
int getLength(string str);


void atualizarContexto(int num);
void contadorDeLinha();
void pushContexto();
void popContexto();
void pushLoop(string tipo);
TIPO_LOOP getLace(string nome);
TIPO_LOOP getLaceBreak();


int yylex(void);
void yyerror(string);
%}

%token TK_NUM TK_REAL TK_CHAR TK_STRING
%token TK_MAIN TK_ID TK_VAR TK_TIPO_INT TK_TIPO_FLOAT TK_TIPO_BOOL TK_TIPO_CHAR TK_TIPO_STRING
%token TK_MAIOR_IGUAL TK_MENOR_IGUAL TK_IGUAL_IGUAL TK_DIFERENTE TK_MAIS_MAIS TK_MENOS_MENOS TK_OU TK_E
%token TK_FUNC
%token TK_INCREMENT
%token TK_FIM TK_ERROR
%token TK_TRUE TK_FALSE
%token TK_PRINTLN TK_PRINT TK_SCAN
%token TK_IF TK_ELSE TK_ELSE_IF TK_WHILE TK_FOR TK_DO TK_BREAK TK_CONTINUE

%start S

%left '+'

%%

S 			: TK_FUNC TK_MAIN '(' ')' BLOCO
			{
				

				cout << "\n\n/*Compilador STAY*/\n" << "#include <iostream>\n#include<string.h>\n#include<stdio.h>\n\n";
				
				cout << "\nint main(void)\n{\n" <<endl;
				
				cout << declaracoes;

				cout << "\n" + $5.traducao << "\treturn 0;\n}" << endl;

				cout << "\n*******************\nTamanho mapa " + std::to_string(mapa.size()) << endl; 

				// vector<TIPO_SIMBOLO> aux = mapa[1];
				// cout << "MAPA ###\n";
				// for (int i = 0; i <= aux.size() -1; i++){
				// 	cout << aux[i].tipoVariavel + " " + aux[i].tempVariavel << endl;
				// }
				// for (int i = 0; i < global_escopo.size(); i++){
					
				// 	cout << std::to_string(i) + " = " + global_escopo[i].nomeVariavel + " / " +global_escopo[i].tempVariavel + "\t" + global_escopo[i].tipoVariavel + "\t" + global_escopo[i].conteudo << endl;
				// }

			}
			;

BLOCO		: '{' COMANDOS '}'
			{
				// string escopo = print_var();
				// cout << "Escopo " + escopo <<endl;
				$$.traducao = $2.traducao;

				cout << "Teste " + $2.traducao << endl;
			}
			;

COMANDOS	: COMANDO COMANDOS
			{
				$$.traducao = $1.traducao + $2.traducao;
			}

			|
			{
				$$.traducao = "";
			}

			| BLOCO 
			{
				$$.traducao = $1.traducao;
			}

			| TK_IF E BLOCO COMANDOS
			{
				string jump = label_jump();

				string temp = gentempcode();
				
				addSimbolo(temp, "bool", temp);
				string condicao = temp + " = !" + $2.label;

				$$.traducao = $2.traducao + "\t" + condicao + ";\n" +
				"\n\tif (" + temp + ") goto FIM_IF_" + jump + ";" +
				"\n\t{\n" +
			 	$3.traducao +
				"\t}\n" +
				"\tFIM_IF_" + jump + ":\n\n" +
				$4.traducao;

			}
			| TK_IF E BLOCO TK_ELSE BLOCO COMANDOS
			{
				string temp = gentempcode();

				string jump1 = label_jump();
				string jump2 = label_jump();
				
				addSimbolo(temp, "bool", temp);
				string condicao = temp + " = !" + $2.label;

				$$.traducao = $2.traducao + "\t" + condicao + ";\n" +
				"\n\tif (" + temp + ") goto FIM_IF_" + jump1 + ";"
				"\n\t{\n" +
			 	$3.traducao +
				"\tgoto FIM_ELSE_" + jump2 + ";\n" +
				"\t}\n" +
				"FIM_IF_" + jump1 + ":\n" +
				"INICIO_ELSE_" + jump2 + ":\n" +
				$5.traducao +
				"FIM_ELSE_" + jump2 + ":\n\n" + $6.traducao;

			}

			| TK_IF E BLOCO TK_ELSE_IF E BLOCO COMANDOS
			{
				string temp = gentempcode();
				string jump1 = label_jump();
				string jump2 = label_jump();
				
				addSimbolo(temp, "bool", temp);
				string condicao = temp + " = !" + $2.label;

				string temp2 = gentempcode();
				addSimbolo(temp2, "bool", temp2);
				string condicao2 = temp2 + " = !" + $5.label;

				$$.traducao = $2.traducao + "\t" + condicao + ";\n" +
				"\n\tif (" + temp + ") goto FIM_IF_" + jump1 + ";"
				"\n\t{\n" +
			 	$3.traducao +
				"\t}\n" +
				"FIM_IF_" + jump1 + ":\n" +
				"INICIO_ELSE_IF_" + jump2 + ":\n" +
				$5.traducao + "\t" + condicao2 + ";\n" +
				"\n\tif (" + temp2 + ") goto FIM_ELSE_IF_" + jump2 + ";"
				"\n\t{\n" +
			 	$6.traducao +
				"\t}\n" +
				"FIM_ELSE_IF_" + jump2 + ":\n\n" + $7.traducao;
			}


			/* | TK_WHILE '(' P ')' BLOCO COMANDOS
			{
				$$.label = gentempcode();
				addTemp($$.label, $3.tipo);
				string lace = genLacecode();
				TIPO_LOOP loop = getLace($1.label);

				$$.traducao = lace + $3.traducao + "\t" + $$.label + " = !" +
				$3.label + ";\n" + "\tIF(" + $$.label + ") goto " + loop.fimLaco + "\n" +
				$5.traducao + "\tgoto " + lace + "\n\t" + loop.fimLaco + "\n" + $6.traducao;
			} */


			| TK_WHILE E BLOCO COMANDOS 
			{
				cout << $2.tipo << endl;
				if($2.tipo != "bool") yyerror("erro: o condicinal do loop deve ser um boolean");

				string temp = gentempcode();
				$$.label = temp;
				addSimbolo(temp, "bool", temp);
				string lace = genLacecode();
				TIPO_LOOP loop = getLace($1.label);	
				
				string condicao = temp + " = !" + $2.label;

				$$.traducao = lace + "\n" + $2.traducao + "\t" + condicao + ";\n" +
				"\n\tif (" + temp + ") goto " + loop.fimLaco + ";\n" +
				"\t{\n" +
			 	$3.traducao +
				"\t}\n" +
				"\tgoto " + lace + ";\n" +
				loop.fimLaco + ":\n\n" + $4.traducao;
			}

			| TK_DO BLOCO TK_WHILE E ';' COMANDOS
			{
				cout << "COMANDOS " + $6.traducao << endl;
				string temp = gentempcode();
				string jump = label_jump();
				
				addSimbolo(temp, "bool", temp);
				string condicao = temp + " = !" + $4.label;

				$$.traducao = "INICIO_DO_WHILE_" + jump + ":\n" +
				$2.traducao + $4.traducao + "\t" + condicao + ";\n"
				"\tif (" + temp + ") goto FIM_DO_WHILE_" + jump + ";\n"
				"\tgoto INICIO_DO_WHILE_" + jump + ";\n" +
				"FIM_DO_WHILE_" + jump + ":\n\n" + $6.traducao;

			}			

			| TK_FOR E ';' E ';' E BLOCO COMANDOS
			{
				string temp = gentempcode();
				string jump = label_jump();
				
				addSimbolo(temp, "bool", temp);
				string condicao = temp + " = !" + $4.label;

				$$.traducao = $2.traducao + "INICIO_FOR_" + jump + ":\n" +
				$4.traducao + "\t" + condicao + ";\n" +
				"\n\tif (" + temp + ") goto FIM_FOR_" + jump + ";\n" +
			 	$7.traducao + $6.traducao +
				"\tgoto INICIO_FOR_" + jump + ";\n" +
				"FIM_FOR_" + jump + ":\n\n" + $8.traducao;
			}
			;

/* BREAK 		: TK_BREAK
			{
				TIPO_LOOP loop = getLaceBreak();
				$$.traducao = "\tgoto " + loop.fimLaco + "\n";
			} */

COMANDO 	: E ';'
			
			| TK_BREAK ';'
			{
				TIPO_LOOP loop = getLaceBreak();
				$$.traducao = "\tgoto " + loop.fimLaco + "\n";
			}

			| TK_VAR TK_ID TK_TIPO_INT ';'
			{
				bool encontrei = buscaVariavel($2.label);
				string temp = gentempcode();
			
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				addSimbolo($2.label, "int", temp);
		
				$$.traducao = "\t" + temp + " = 0" + ";\n";
				$$.label = "int " + $2.label;
			}

			| TK_VAR TK_ID TK_TIPO_FLOAT ';'
			{
				bool encontrei = buscaVariavel($2.label);
				string temp = gentempcode();

				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				addSimbolo($2.label, "float", temp);
		
				$$.traducao = "\t" + temp + " = 0.0" + ";\n";
				$$.label = "float " + $2.label;
			}

			| TK_VAR TK_ID TK_TIPO_BOOL ';' 
			{
				bool encontrei = buscaVariavel($2.label);
				
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				string temp = gentempcode();
				addSimbolo($2.label, "bool", temp);
		
				$$.traducao = $2.traducao + $3.traducao + "\t" + temp + " = 0" + ";\n";
				$$.label = temp;
			}

			| TK_VAR TK_ID TK_TIPO_CHAR ';' 
			{
				bool encontrei = buscaVariavel($2.label); 
				string temp = gentempcode();

				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");	
				
				addSimbolo($2.label, "char",  temp);
		
				$$.traducao = "\t" + temp + " = " + "'" + "\0" +"'" + ";\n";
				$$.label = "int " + $2.label;
			}

			| TK_VAR TK_ID TK_TIPO_STRING ';' 
			{
				bool encontrei = buscaVariavel($2.label); 
				string temp = gentempcode();

				cout << "var = " + $2.label << endl;
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");	
				
				addStr($2.label, "string",  temp, "\0");
				// $$.traducao = "\tstrcpy(" + temp + ", " + "\\0" + ");\n";
				$$.label = "\tstrcpy(" + temp + ", " + "\"\\0\"" + ");\n";
				//  $$.traducao = "\t" + temp + " = " + "'" + "\\0" + "'" + ";\n";
			}

			| TK_VAR TK_ID TK_TIPO_BOOL '=' TK_TRUE ';' 
			{
				bool encontrei = buscaVariavel($2.label); 
				string temp = gentempcode();

				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				// if($5.tipo != "int") 
				// 	yyerror("Erro: valor (" + $5.conteudo + ") inválido para o tipo int" );
					
				addSimbolo($2.label, "bool", temp);
		
				$$.traducao = "\t" + temp + " = 1" + ";\n";
				$$.label = "int " + $2.label + " = " + $5.label;
				
			}

			| TK_VAR TK_ID TK_TIPO_BOOL '=' TK_FALSE ';' 
			{
				bool encontrei = buscaVariavel($2.label); 
				string temp = gentempcode();

				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				addSimbolo($2.label, "bool", temp);
		
				$$.traducao = "\t" + temp + " = 0" + ";\n";
				$$.label = "int " + $2.label + " = " + $5.label;
			}

			| TK_VAR TK_ID TK_TIPO_INT '=' E ';' 
			{
				string temp = gentempcode();
				
				bool encontrei = buscaVariavel($2.label); 
				
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				if($5.tipo == "int"){ 

					addSimbolo($2.label, "int", temp);
			
					$$.traducao = $2.traducao + $5.traducao + "\t" + temp + " = " + $5.label + ";\n";
					$$.label = "int " + $2.label + " = " + $5.label;
				}

				else if ($5.tipo == "float"){
					addSimbolo($2.label, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $5.traducao + "\t" + $$.label + " = (int) " + $5.label + ";\n" + 
					"\t" + temp + " = " + $$.label + ";\n";
				}

				else if ($5.tipo == "char"){
					addSimbolo($2.label, "int", temp);
					// $$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $5.traducao + "\t" + $$.label + " = (int) " + $5.label + ";\n" + 
					"\t" + temp + " = " + $$.label + ";\n";
				}
			}

			| TK_VAR TK_ID TK_TIPO_FLOAT '=' E ';' 
			{
				string temp = gentempcode();
				
				bool encontrei = buscaVariavel($2.label); 
				
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				if($5.tipo == "float"){ 

					addSimbolo($2.label, "float", temp);
			
					$$.traducao = $2.traducao + $5.traducao + "\t" + temp + " = " + $5.label + ";\n";
					$$.label = "float " + $2.label + " = " + $5.label;
				}

				else if ($5.tipo == "int"){
					addSimbolo($2.label, "float", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "float", $$.label);
					$$.traducao = $5.traducao + "\t" + $$.label + " = (float) " + $5.label + ";\n" + 
					"\t" + temp + " = " + $$.label + ";\n";
				}
			}

			| TK_VAR TK_ID TK_TIPO_CHAR '=' E ';' 
			{	
				string temp = gentempcode();
				
				bool encontrei = buscaVariavel($2.label); 
				
				if(encontrei)
					yyerror("erro: a variavel '" + $2.label + "' já foi declarada");
				
				if($5.tipo == "char"){ 

					addSimbolo($2.label, "char", temp);
			
					$$.traducao = $2.traducao + $5.traducao + "\t" + temp + " = " + $5.label + ";\n";
					$$.label = "char " + $2.label + " = " + $5.label;
				}

				else if ($5.tipo == "int"){
					addSimbolo($2.label, "char", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "char", $$.label);
					$$.traducao = $5.traducao + "\t" + $$.label + " = (char) " + $5.label + ";\n" + 
					"\t" + temp + " = " + $$.label + ";\n";
				}

				else if ($5.tipo == "float"){
					addSimbolo($2.label, "char", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "char", $$.label);
					$$.traducao = $5.traducao + "\t" + $$.label + " = (char) " + $5.label + ";\n" + 
					"\t" + temp + " = " + $$.label + ";\n";
				}
			}
			
			| TK_VAR TK_ID TK_TIPO_STRING '=' E ';' 
			{
				if ($5.tipo == "string"){
					bool encontrei = buscaVariavel($2.label); 
					$$.label = gentempcode();

					if(encontrei)
						yyerror("erro: a variavel '" + $2.label + "' já foi declarada");	
					
					addStr($2.label, "string", $$.label, $5.conteudo);
					
					$$.traducao = $5.traducao + "\tstrcpy(" + $$.label + ", " + $5.label + ");\n"; 
					cout << "var string = algo \n" + $$.traducao << endl;
					// $$.label = "\tstrcpy(" + temp + ", " + $5.label + ");\n";
				}
				else yyerror("Atribuição inválida");
			}
			;


			
E 			
			// OPERADORES ARITMÉTICOS
			: E '+' E
			{
				$$.label = gentempcode();
				string tipoAux;
				string labelAux;
				string converter;

				if($1.tipo == $3.tipo){
					if ($1.tipo == "string"){
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + "\t" + 
						"strcat(" + $1.label + ", " + $3.label + ");\n";
						addSimbolo($$.label, $$.tipo, $$.label);
					}

					else{
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + "\t" + 
						$$.label + " = " + $1.label + " + " + $3.label + ";\n";
						addSimbolo($$.label, $$.tipo, $$.label);
					}
				}								
				else if($1.tipo == "int" & $3.tipo == "float"){
					$$.tipo = $3.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = "  + converter + $1.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + labelAux + " + " + $3.label + ";\n";
				}

				else if($1.tipo == "float" & $3.tipo == "int"){
					$$.tipo = $1.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + cast($1.tipo, $3.tipo) + $3.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + $1.label + " + " + labelAux + ";\n";
				}
				
				else yyerror("erro: Cast inválido");
				
			}

			| E '-' E
			{
				$$.label = gentempcode();
				string tipoAux;
				string labelAux;
				string converter;

				if($1.tipo == $3.tipo){
					$$.tipo = $1.tipo;
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " - " + $3.label + ";\n";
					addSimbolo($$.label, $$.tipo, $$.label);
				}								
				else if($1.tipo == "int" & $3.tipo == "float"){
					$$.tipo = $3.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = "  + converter + $1.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + labelAux + " - " + $3.label + ";\n";
				}

				else if($1.tipo == "float" & $3.tipo == "int"){
					$$.tipo = $1.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + cast($1.tipo, $3.tipo) + $3.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + $1.label + " - " + labelAux + ";\n";
				}
				
				else yyerror("erro: Cast inválido");
			}

			| E '*' E
			{
				$$.label = gentempcode();
				string tipoAux;
				string labelAux;
				string converter;

				if($1.tipo == $3.tipo){
					$$.tipo = $1.tipo;
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " * " + $3.label + ";\n";
					addSimbolo($$.label, $$.tipo, $$.label);
				}								
				else if($1.tipo == "int" & $3.tipo == "float"){
					$$.tipo = $3.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = "  + converter + $1.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + labelAux + " * " + $3.label + ";\n";
				}

				else if($1.tipo == "float" & $3.tipo == "int"){
					$$.tipo = $1.tipo;
					addSimbolo($$.label, $$.tipo, $$.label);
					converter = cast($1.tipo, $3.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + cast($1.tipo, $3.tipo) + $3.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, $$.tipo, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + $1.label + " * " + labelAux + ";\n";
				}
				
				else yyerror("erro: Cast inválido");
			}

			| E '/' E
			{
				$$.label = gentempcode();
				string tipoAux;
				string labelAux;
				string converter;
				
				string aux = $3.conteudo;
				int cont = 0;
				int ponto = 0;

				for(int i = 0; i < aux.size(); i++)
				{
					if(aux[i] == '.')
					{
						ponto = 1;
					}
					if(aux[i] == '0')
					{
						cont++;
					}
				}

				if(cont == aux.size() || (cont + ponto) == aux.size()){
					yyerror("Operação inválida, Divisão por 0");
				}

				if($1.tipo == $3.tipo){
					tipoAux = $1.tipo;
										
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " / " + $3.label + ";\n";
					addSimbolo($$.label, tipoAux, $$.label);
				}
				else if($1.tipo == "int" & $3.tipo == "float"){
					tipoAux = "float";
					addSimbolo($$.label, tipoAux, $$.label);
					converter = cast($1.tipo, $2.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + converter + $1.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, tipoAux, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + labelAux + " / " + $3.label + ";\n";
				}
				else if($1.tipo == "float" & $3.tipo == "int"){
					tipoAux = "float";
					addSimbolo($$.label, tipoAux, $$.label);
					converter = cast($1.tipo, $2.tipo);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + converter + $3.label + ";\n";

					labelAux = $$.label;
					$$.label = gentempcode();
					addSimbolo($$.label, tipoAux, labelAux);
					$$.traducao = $$.traducao + "\t"+
					$$.label + " = " + $1.label + " / " + labelAux + ";\n";
				}
				else{
					yyerror("Erro: Divisão inválida");
				}
			}

			| E '%' E
			{
				$$.label = gentempcode();

				if($1.tipo == "int" & $3.tipo == "int"){
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " % " + $3.label + ";\n";
					addSimbolo($$.label, $1.tipo, $$.label);
				}
				else{
					yyerror("Erro: Operação não permitida no tipo float");
				}
			}

			| TK_ID TK_MAIS_MAIS
			{
				if (!buscaVariavel($1.label)) yyerror("Erro: Variável não Declarada");

				TIPO_SIMBOLO var1 = getSimbolo($1.label);
				$$.traducao = $1.traducao + $2.traducao + "\t" + 
				var1.tempVariavel + " = " + var1.tempVariavel + " + 1" + ";\n";
			}

			| TK_ID TK_MENOS_MENOS
			{
				if (!buscaVariavel($1.label)) yyerror("Erro: Variável não Declarada");

				TIPO_SIMBOLO var1 = getSimbolo($1.label);
				$$.traducao = $1.traducao + $2.traducao + "\t" + 
				var1.tempVariavel + " = " + var1.tempVariavel + " - 1" + ";\n";
			}

			//OPERADORES RELACIONAIS

			| E '>' E
			{
				string temp = gentempcode();
				$$.label = temp;

				relacionalInvalida($1.tipo, $3.tipo);

				if ($1.tipo == $3.tipo && $1.tipo != "string"){				
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " > " + $3.label + ";\n";
				}

				else if ($1.tipo == "int" && $3.tipo == "float"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (int) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " > " + $$.label + ";\n";
				}

				else if ($1.tipo == "float" && $3.tipo == "int"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (float) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " > " + $$.label + ";\n";
				}
			}
			
			| E '<' E
			{
				string temp = gentempcode();
				$$.label = temp;

				relacionalInvalida($1.tipo, $3.tipo);

				if ($1.tipo == $3.tipo && $1.tipo != "string"){				
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " < " + $3.label + ";\n";
				}

				else if ($1.tipo == "int" && $3.tipo == "float"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (int) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " < " + $$.label + ";\n";
				}

				else if ($1.tipo == "float" && $3.tipo == "int"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (float) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " < " + $$.label + ";\n";
				}
			}

			| E TK_MAIOR_IGUAL E
			{
				string temp = gentempcode();
				$$.label = temp;

				relacionalInvalida($1.tipo, $3.tipo);

				if ($1.tipo == $3.tipo && $1.tipo != "string"){				
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " >= " + $3.label + ";\n";
				}

				else if ($1.tipo == "int" && $3.tipo == "float"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (int) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " >= " + $$.label + ";\n";
				}

				else if ($1.tipo == "float" && $3.tipo == "int"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (float) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " >= " + $$.label + ";\n";
				}
			}
			
			| E TK_MENOR_IGUAL E
			{
				string temp = gentempcode();
				$$.label = temp;

				relacionalInvalida($1.tipo, $3.tipo);

				if ($1.tipo == $3.tipo && $1.tipo != "string"){				
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " <= " + $3.label + ";\n";
				}

				else if ($1.tipo == "int" && $3.tipo == "float"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (int) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " <= " + $$.label + ";\n";
				}

				else if ($1.tipo == "float" && $3.tipo == "int"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (float) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " <= " + $$.label + ";\n";
				}
			}

			| E TK_IGUAL_IGUAL E
			{
				string temp = gentempcode();
				$$.label = temp;

				relacionalInvalida($1.tipo, $3.tipo);

				if ($1.tipo == $3.tipo && $1.tipo != "string"){				
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = " + $1.label + " == " + $3.label + ";\n";
				}

				else if ($1.tipo == "int" && $3.tipo == "float"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (int) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " == " + $$.label + ";\n";
				}

				else if ($1.tipo == "float" && $3.tipo == "int"){
					addSimbolo(temp, "int", temp);
					$$.traducao = "\t" + temp + " = 0" + ";\n"; 
					
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + $$.traducao + "\t" + $$.label + " = (float) " + $3.label + ";\n" + 
					"\t" + temp + " = " + $1.label + " == " + $$.label + ";\n";
				}
			}

			//OPERADORES LÓGICOS
			| E TK_DIFERENTE E
			{
				relacionalInvalida($1.tipo, $3.tipo);
				$$.label = gentempcode();
				addSimbolo($$.label, "int", $$.label);
				$$.traducao = $1.traducao + $3.traducao + "\t" + 
				$$.label + " = " + $1.label + " != " + $3.label + ";\n";
			}

			| E TK_OU E
			{
				$$.label = gentempcode();
				addSimbolo($$.label, "int", $$.label);
				$$.traducao = $1.traducao + $3.traducao + "\t" + 
				$$.label + " = " + $1.label + " || " + $3.label + ";\n";
			}

			| E TK_E E
			{
				cout << "Traduções -> " + $1.traducao + $3.traducao << endl;
				$$.label = gentempcode();
				addSimbolo($$.label, "int", $$.label);
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " && " + $3.label + ";\n";
			}

			| '!' E
			{
				$$.label = gentempcode();
				addSimbolo($$.label, "int", $$.label);
				$$.traducao = $2.traducao + "\t" + 
				$$.label + " = " + "!" + $2.label + ";\n";
			}

			//OPERADORES DE ATRIBUIÇÃO
			| TK_ID '=' E
			{
				if (!buscaVariavel($1.label)) yyerror("Erro: Variável não Declarada");

				TIPO_SIMBOLO var = getSimbolo($1.label);
				
				if(var.tipoVariavel == $3.tipo){
					if (var.tipoVariavel == "string"){
						cout << "$3.traducao no = " + $3.traducao << endl;
						$$.traducao = $3.traducao + "\tstrcpy(" + var.tempVariavel + ", " + $3.label + ");\n"; 
					}
	
					else{
						$$.traducao = $1.traducao + $3.traducao + "\t" + 
						var.tempVariavel + " = " + $3.label + ";\n";
					}
				}
				else if (var.tipoVariavel == "int" & $3.tipo == "float")
				{
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = (int) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else if (var.tipoVariavel == "float" & $3.tipo == "int")
				{
					$$.label = gentempcode();
					addSimbolo($$.label, "float", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" + 
					$$.label + " = (float) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else if (var.tipoVariavel == "char" & $3.tipo == "int"){
					$$.label = gentempcode();
					addSimbolo($$.label, "char", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" +
					$$.label + " = (char) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else if (var.tipoVariavel == "int" & $3.tipo == "char"){
					$$.label = gentempcode();
					addSimbolo($$.label, "int", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" +
					$$.label + " = (int) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else if (var.tipoVariavel == "float" & $3.tipo == "char"){
					$$.label = gentempcode();
					addSimbolo($$.label, "float", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" +
					$$.label + " = (float) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else if (var.tipoVariavel == "char" & $3.tipo == "float"){
					$$.label = gentempcode();
					addSimbolo($$.label, "char", $$.label);
					$$.traducao = $1.traducao + $3.traducao + "\t" +
					$$.label + " = (char) " + $3.label + ";\n" + "\t" + 
					var.tempVariavel + " = " + $$.label + ";\n";
				}
				else{ 
					yyerror("Erro: Atribuição inviavel");
				}
			}

			| TK_ID '=' TK_TRUE
			{
			    if (!buscaVariavel($1.label)) yyerror("Erro: Variável não Declarada");

				TIPO_SIMBOLO var1 = getSimbolo($1.label);
				$$.label = var1.tempVariavel;
				$$.traducao = $1.traducao + $3.traducao + "\t" + 
				var1.tempVariavel + " = 1"  + ";\n";
			}

			| TK_ID '=' TK_FALSE
			{
			    if (!buscaVariavel($1.label)) yyerror("Erro: Variável não Declarada");

				TIPO_SIMBOLO var1 = getSimbolo($1.label);
				$$.label = var1.tempVariavel;
				$$.traducao = $1.traducao + $2.traducao + "\t" + 
				var1.tempVariavel + " = 0"  + ";\n";
			}

			| TK_NUM
			{
				$$.tipo = "int";
				$$.conteudo = $1.label;
				$$.label = gentempcode();
				addSimbolo($$.label, $$.tipo, $$.label);
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}

			| TK_REAL
			{
				$$.tipo = "float";
				$$.conteudo = $1.label;
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				addSimbolo($$.label, $$.tipo, $$.label);
			}

			| TK_TRUE
			{
				$$.tipo = "bool";
				$$.conteudo = "1";
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $$.conteudo + ";\n";
				addSimbolo($$.label, $$.tipo, $$.label);
			}

			| TK_FALSE
			{
				$$.tipo = "bool";
				$$.conteudo = "0";
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $$.conteudo + ";\n";
				addSimbolo($$.label, $$.tipo, $$.label);
			}

			| TK_CHAR
			{
				$$.tipo = "char";
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				addSimbolo($$.label, $$.tipo, $$.label);
			}

			| TK_STRING
			{
				$$.tipo = "string";
				$$.conteudo = $$.label;
				$$.label = gentempcode();
				addStr($$.label, $$.tipo, $$.label, $$.conteudo);
				// $$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				$$.traducao = "\tstrcpy(" + $$.label + ", " + $1.label + ");\t//"+ $$.label +"\n";	
				// cout << "traducao 1 " + $$.traducao << endl;			
			}
	
			| TK_ID
			{
				TIPO_SIMBOLO variavel = getSimbolo($1.label);	
				$$.tipo = variavel.tipoVariavel;
				cout << "VER " + $$.tipo + " " + variavel.nomeVariavel << endl;
				// $$.conteudo = variavel.value;
				$$.label = gentempcode();
				addSimbolo(variavel.nomeVariavel, $$.tipo, $$.label);
				$$.traducao = "\t" + $$.label + " = " + variavel.tempVariavel + ";\n";
			}

			//CONVERSÃO EXPLÍCITA
			|TK_TIPO_FLOAT '(' E ')'
			{		
				$$.label = gentempcode();
				$$.tipo  = "float";

				addSimbolo($$.label, $$.tipo, $$.label);
				
				if($3.tipo == "int")
				{	
					$$.traducao = $3.traducao + "\t" + 
					$$.label + " = " + "(float) " + $3.label + ";\n";  
				}
				
				else
					yyerror("Erro Cast Inválido");
			}

			|TK_TIPO_INT '(' E ')'
			{	
				$$.label = gentempcode();
				$$.tipo  = "int";
				addSimbolo($$.label, $$.tipo, $$.label);

				if($3.tipo == "float")
				{
					$$.traducao = $3.traducao + "\t" + 
					$$.label + " = " + "(int) " + $3.label + ";\n";
				}
				
				else yyerror("operacao invalida");
			}

			// IO
			| TK_PRINTLN '(' E ')'
			{
				$$.traducao = $3.traducao + "\tcout << " + $3.label + " << endl;\n";
				cout << "tradução " + $3.traducao << endl;
			}
			
			| TK_PRINT '(' E ')'
			{
				// cout << "traducao no print -> \n"+ $3.traducao + "\n label -> " + $3.label << endl;
				// if ($3.tipo == "string")
				// 	$$.traducao = "\tcout << " + $3.label + ";\n";	
				
				// else
					$$.traducao = $3.traducao + "\tcout << " + $3.label + ";\n";
				
			}

			| TK_SCAN '(' '&' TK_ID ')'
			{
				$$.label = gentempcode();
				$$.tipo = $4.tipo;
				
				TIPO_SIMBOLO var = getSimbolo($4.label);

				$$.traducao = $4.traducao + "\tcin >> " + var.tempVariavel + ";\n" + $3.traducao; 
			} 
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode(){
	var_temp_qnt++;
	return "t" + std::to_string(var_temp_qnt);
}

string genLacecode(){
	var_lace_qnt++;
	return "_L" + std::to_string(var_lace_qnt) + ":";	
}

string genCondcode(){
	var_cond_qnt++;
	return "FIM_IF_" + std::to_string(var_cond_qnt);
}

string genLaceNameCode(){
	var_lace_name_qnt++;
	return "loop_" + std::to_string(var_lace_name_qnt);
}

string label_jump(){
	num_jump++;
	return "J" + std::to_string(num_jump);
}

void addSimbolo(string nome, string tipo, string temp){
	TIPO_SIMBOLO var;
	var.nomeVariavel = nome;
	var.tipoVariavel = tipo;
	var.tempVariavel = temp;

	int contexto = mapa.size() - 1;
	mapa[contexto].push_back(var);
	
	print_var(var);
	/* declaracoes += "\t" + tipo + " " + temp + " ;\n"; */
 	cout << "TRUE? " + var.nomeVariavel + " contexto =  " + std::to_string(contexto) << endl; 				
}

void addStr(string nome, string tipo, string temp, string conteudo){
	TIPO_SIMBOLO var;
	var.nomeVariavel = nome;
	var.tipoVariavel = tipo;
	var.tempVariavel = temp;
	var.conteudo = conteudo;

	int contexto = mapa.size() - 1;
	mapa[contexto].push_back(var);		
	print_var(var);		
}

void print_var(TIPO_SIMBOLO var){
	if (var.tipoVariavel == "bool") var.tipoVariavel = "int";

	if (var.tipoVariavel == "string"){
		var.tipoVariavel = "char";
		if (var.conteudo == "\0"){
			declaracoes += "\t" + var.tipoVariavel + " " + var.tempVariavel + "[" + strGeralSize + "];\t//" + var.nomeVariavel + "\n";
		}
		
		else{
			int size = getLength(var.conteudo) - 2; // O -2 remove as aspas que vem junto da string 
			declaracoes += "\t" + var.tipoVariavel + " " + var.tempVariavel + "[" + std::to_string(size) + "];\t//" + var.nomeVariavel + "\n";
		}
	}
	else{
		declaracoes += "\t" + var.tipoVariavel + " " + var.tempVariavel + ";\n";
	}			

}

bool buscaVariavel(string variavel){
	
	int contexto = mapa.size() - 1;
	vector<TIPO_SIMBOLO> tabelaSimbolos;
	tabelaSimbolos = mapa[contexto];

	for(int i = 0; i < tabelaSimbolos.size(); i++)
	{
		if(tabelaSimbolos[i].nomeVariavel == variavel)
		{
			return true;
		}
	}
	return false;
}

TIPO_SIMBOLO getSimbolo(string variavel){
	
	int contexto = mapa.size() - 1;
	vector<TIPO_SIMBOLO> tabelaSimbolos;
	tabelaSimbolos = mapa[contexto];

	while(contexto >= 0)
	{
		for (int i = tabelaSimbolos.size() - 1; i >= 0; i--)
		{
			if(tabelaSimbolos[i].nomeVariavel == variavel)
			{
				return tabelaSimbolos[i];
			}				
		}
		contexto--;
		tabelaSimbolos = mapa[contexto];
	}
	cout << "Variavel " + variavel + " não declarada";
	exit(0);
}

//Conversão implícita
string cast(string tipo1, string tipo2){
	
	if (tipo1 == "int" && tipo2 == "float" || tipo1 == "float" && tipo2 == "int")
		return "(float) ";
	
	yyerror("erro: Casting inválido");
	exit(0);
}

bool comparaTipo(string tipo1, string tipo2){
	if (tipo1 == tipo2) return true;

	return false;
}

void relacionalInvalida(string tipo1, string tipo2){
	if (tipo1 == "char" || tipo2 == "char" || tipo1 == "bool" || tipo2 == "bool") yyerror("Erro: Relacional Inválido");
}

void inicializaAscii(){
	TABELA_ASCII elemento;

	elemento.indice = 0;
	elemento.caracter = "\0";
	table_ascii.push_back(elemento);

	for ( char i = 1; i < 127; i++ ) {

		elemento.indice = i;
		elemento.caracter = i;
		
		table_ascii.push_back(elemento);
    }
}

int getLength(string str){
	int i = 0;
	while (str[i] != '\0') i++;

	return i+1;
}


int main( int argc, char* argv[] )
{	
	var_temp_qnt = 0;
	contextoGlobal = 0;
	vector<TIPO_SIMBOLO> tabelaSimbolos;
	mapa.push_back(tabelaSimbolos);
	
	cout << std::to_string(mapa.size()) << endl;

	yyparse();

	return 0;
}

void yyerror( string MSG )
{
	cout << MSG << endl;
	exit (0);
}				

void pushContexto(){
	vector<TIPO_SIMBOLO> tabelaSimbolos;
	mapa.push_back(tabelaSimbolos);
}

void popContexto(){
	mapa.pop_back();
}

void pushLoop(string tipo){

	TIPO_LOOP aux;
	aux.nomeLaco = "loop_" + std::to_string(var_lace_name_qnt);
	aux.tipoLaco = tipo;
	aux.fimLaco = genCondcode();
	aux.contexto = mapa.size();
	tabelaLoop.push_back(aux);
}

TIPO_LOOP getLace(string nome){

	for (int i = tabelaLoop.size() - 1; i >= 0; i--)
	{ 
		if(tabelaLoop[i].nomeLaco == nome){
			return tabelaLoop[i];
		}
	}
	exit(0);
}

TIPO_LOOP getLaceBreak(){
	int size = tabelaLoop.size();
	return tabelaLoop[size - 1];
}


void contadorDeLinha(){
	var_linha_qnt++;
	contLinha = std::to_string(var_linha_qnt);
}