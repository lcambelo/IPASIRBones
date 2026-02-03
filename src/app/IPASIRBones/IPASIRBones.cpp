/*
 * IPASIRBones
 * 
 * Author: Luis Cambelo 2025
 * 
 *    
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <vector>
#include <signal.h>
#include <unistd.h>
#include <iostream>

using namespace std;
#define SIG_CADICAL "cadical-2.1.3-461a8f4"
#define SAT 10
#define UNSAT 20

extern "C" {
	#include "ipasir.h"
}

bool loadFormula(void* solver, const char* filename, int& maxVar, int& numClauses ) {
	FILE* f = fopen(filename, "r");
	if (f == NULL) {
		return false;
	}
	maxVar = 0;
	int c = 0;
	bool neg = false;
	while (c != EOF) {
	  c = fgetc(f);
	  if (c == 'c' || c == 'p') {
	    // skip this line
	    while(c != '\n') {
	      c = fgetc(f);
	    }
	    continue;
	  }
	  // whitespace
	  if (isspace(c)) {
	    continue;
	  }
	  // negative
	  if (c == '-') {
	    neg = true;
	    continue;
	  }
	  
	  // number
	  if (isdigit(c)) {
	    int num = c - '0';
	    c = fgetc(f);
	    while (isdigit(c)) {
	      num = num*10 + (c-'0');
	      c = fgetc(f);
	    }
	    if (neg) {
	      num *= -1;
	    }
	    neg = false;
	    
	    if (abs(num) > maxVar) {
	      maxVar = abs(num);
	    }
	    // add to the solver
	    ipasir_add(solver, num);
	    if (num == 0) numClauses++;
	  }
	}
	fclose(f);
	return true;
}

bool get_options(int argc, char **argv, int& opt_s, int& opt_t, int& opt_i) {
  int c;
  while ((c = getopt(argc, argv, "sti")) != -1) {
    switch (c) {
    case 's':
      opt_s = 1;
      if (opt_s && opt_t) {
        printf("Cannot choose -s and -t at same time, exiting...\n");
        return false;
      }
      break;
    case 't':
      opt_t = 1;
      if (opt_s && opt_t) {
        printf("Cannot choose -s and -t at same time, exiting...\n");
        return false;
      }
      break;
    case 'i':
      opt_i = 1;
      break;
    default:
      return false;
    }
  }
  // defaulting to -t
  if (!(opt_s || opt_t)) {
    opt_t = 1;
  }
  return true;
}

void solve_naive(void* solver, vector<int>& backbone, int& maxVar, int inject) {
  printf("c Algorithm 1: Naive Iterative (FlamaPy)%s\n", inject ? " + unit clause injection" : "");
  for (int i = 1; i <= maxVar; i++) {
    // check positive case
    int candidate = -i; // checks if negative is SAT
    ipasir_assume(solver, candidate);
    int res = ipasir_solve(solver);
    if (res == UNSAT) {
      backbone[abs(candidate)] = -candidate;  // Fixed: if -i is UNSAT, then i is backbone
      if (inject) {
        ipasir_add(solver, -candidate);
        ipasir_add(solver, 0);
      }
      continue;
    }
  }
  
  for (int i = 1; i <= maxVar; i++) {
    // Skip if already found as backbone in first loop
    if (backbone[i] != 0) {
      continue;
    }
    // check negative case
    int candidate = i; // checks if positive is SAT
    ipasir_assume(solver, candidate);
    int res = ipasir_solve(solver);
    if (res == UNSAT) {
      backbone[abs(candidate)] = -candidate;
      if (inject) {
        ipasir_add(solver, -candidate);  // Fixed: add -i as unit clause, not i
        ipasir_add(solver, 0);
      }
      continue;
    }
  }
}

void solve_advanced(void* solver, vector<int>& backbone, int& maxVar, int inject) {
  printf("c Algorithm 2/3: Advanced Iterative with solution filtering (FeatureIDE)%s\n", inject ? " + unit clause injection" : "");
  int* candidates = new int[maxVar+1];	
  for (int lit = 1; lit <= maxVar; lit++) {
    candidates[lit] = ipasir_val(solver, lit);
  }
  
  for (int l = 1; l <= maxVar; l++) {
    int candidate = candidates[l];
    if (candidate == 0) {
      continue;
    }
    
    ipasir_assume(solver, -candidate);
    int res = ipasir_solve(solver);
    if (res == UNSAT) {
      backbone[abs(candidate)] = candidate;
      if (inject) {
        ipasir_add(solver, candidate);
        ipasir_add(solver, 0);
      }
    }  else {
      for (int lit = l+1; lit <= maxVar; lit++) {
        if ( candidates[lit] != ipasir_val(solver, lit ) ) {
          candidates[lit] = 0;
        }
      }
    }
  }
}

void print_backbone(vector<int>& backbone) {
  printf("v");
  int bb_count = 0;
  for (size_t i=1; i<=backbone.size()-1; i++) {
    if (backbone[i] != 0) {
      printf(" %d", backbone[i]);
      bb_count++;
    }
  }
  printf("\n");
  printf("c Backbone count: %d\n", bb_count);
}


int main(int argc, char **argv) {
  
  printf("      ___ ____   _    ____ ___ ____  ____                        \n");
  printf("     |_ _|  _ \\ / \\  / ___|_ _|  _ \\| __ )  ___  _ __   ___  ___ \n");
  printf("      | || |_) / _ \\ \\___ \\| || |_) |  _ \\ / _ \\| '_ \\ / _ \\/ __|\n");
  printf("      | ||  __/ ___ \\ ___) | ||  _ <| |_) | (_) | | | |  __/\\__ \\\n");
  printf("     |___|_| /_/   \\_\\____/___|_| \\_\\____/ \\___/|_| |_|\\___||___/\n");
  printf("\n");
  printf("AN IPASIR-BASED TOOL THAT EXTRACTS THE BACKBONE OF DIMACS FORMULAS, 2026\n");
  printf("\n");
  printf("Authors: Luis Cambelo, Ruben Heradio, Jose M. Horcas,\n");
  printf("         Dictino Chaos, and David Fernandez-Amoros\n");
  printf("\n");
  const char* sig = ipasir_signature();
  bool is_minisat = (strstr(sig, "minisat") != NULL);
  printf("c Using incremental SAT solver: %s\n", sig);
	if (argc < 2) {
		if (is_minisat) {
			printf("USAGE: ./IPASIRBones_MiniSat <file.dimacs> [options]\n");
			printf("Options:\n");
			printf("  -s  Algorithm 1: Naive Iterative (FlamaPy)\n");
			printf("  -t  Algorithm 2/3: Advanced Iterative with solution filtering (FeatureIDE) [default]\n");
			printf("  -i  Add backbone literals as unit clauses (works with -s or -t)\n");
		} else {
			printf("USAGE: ./IPASIRBones_CaDiCaL <file.dimacs> [options]\n");
			printf("Options:\n");
			printf("  -s  Algorithm 1: Naive Iterative (FlamaPy)\n");
			printf("  -t  Algorithm 2/3: Advanced Iterative with solution filtering (FeatureIDE) [default]\n");
		}
		return 1;
	}
	
	auto fname = argv[1];
	int option_s = 0; int option_t = 0; int option_i = 0;
	if ( !get_options(argc, argv, option_s, option_t, option_i) ) {
	  return 1;
	}
	
	// -i option is only available for MiniSat
	if (option_i && !is_minisat) {
		printf("Option -i is only available for MiniSat, exiting...\n");
		return 1;
	}
	
	void *solver = ipasir_init();
	int numVar = 0;
	int numclauses = 0;
	bool loaded = loadFormula(solver, fname, numVar, numclauses);
	if (!loaded) {
		printf("The input formula \"%s\" could not be loaded.\n", fname);
		return 2;
	}
	
	// First check if SAT, exiting otherwise
	if (ipasir_solve(solver) == UNSAT) {
	  printf("Formula unsatisfiable. Program ended.\n");
	  return UNSAT;
	}
	
	vector<int> Backbone(numVar+1, 0);
	if (option_s) {                                            
	  solve_naive(solver, Backbone, numVar, option_i);       
	} else if (option_t) {                                     
	  solve_advanced(solver, Backbone, numVar, option_i);      
	}  

  print_backbone(Backbone);
	
	return SAT;
}
