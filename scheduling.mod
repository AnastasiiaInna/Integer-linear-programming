/*********************************************
 * OPL 12.5.1.0 Model
 * Author
 * Creation Date: 20/04/2015 at 16:37:27
 *********************************************/
 
 int D = ...; // the number of days per month
 int H = ...; // the number of hours per day
 int nOpenHours = ...; // the number of open hours per month 
 /* it will be computed in the pre-processing clock
    because it depends on the number of days per month and hours per day */  
 int nEmloyees = ...; // the number of possible employees
  
 range T = 1..nOpenHours; // set of opening hours
 range E = 1..nEmloyees; // set of  possible employees
 
 int ct[T] = ...; // number of customers per hour t
 int pt = ...; // average time - customer at checkout station
 int nCustomersCS; // numbers of customers per hour at checkout station
 /* will be computed in the pre-processing clock */
 
 float nCS[t in T]; // number of checkout stations in time t
  /* it will be computed in the pre-processing clock, because it depends on opening hours in month
     and average tome each customers spends at checkout station */ 
     
 int I[E, E] = ...; // 1 - if employees are incpompatible; 0 - otherwise
 
 /* ----- Decision variable ----- */
 dvar boolean hire[e in E]; // 1 - if employee "e" is hired, 0 - otherwise
 dvar boolean x_et[e in E][t in T]; // 1 - if emplyee "e" works at time "t", 0 - otherwise
 
 /* ----- Pre-processing block ----- */
 execute INITIALIZE
 {
   //nOpenHours = D * H;
   nCustomersCS = 60 / pt;
   
   for(var t = 1; t < nOpenHours + 1; t++)
   		nCS[t] = ct[t] / nCustomersCS; // number of checkout stations
 }
 
 /* ----- Objective function ----- */
 minimize sum(e in E) hire[e];
 
 subject to 
 {
	/* ---- Constraint 1 ----- */
	/* no employee can be assigned to a task for more than 2 consecutive hours */
	forall(e in E, d in 0..(D - 1), h in 1..(H-2))
	  x_et[e][h + d * H] + x_et[e][h + d * H + 1] + x_et[e][h + d * H + 2] <= 2;
		  
	/* ---- Constraint 2 ------*/
	/* every hour the number of employees must be equal the number of checkout station */
	forall(t in T)
	  sum(e in E) x_et[e][t] == ceil(nCS[t]);
	  	  
	/* ---- Constraint 3 ----- */
	/* the employee can be assigned to a task only if he (she) is hired */
	forall(e in E, t in T) 
		hire[e] >= x_et[e][t] ;
				
	/* ---- Constraint 4 ----- */
	/* if I[e1][e2] == 1 employees e1 and e2 can not work simultaneously */
	forall(e1 in E, e2 in E, t in T) 
		x_et[e1][t] + x_et[e2][t] + I[e1][e2] <= 2;
		
	/* ---- Constraint 5 ----- */
	forall(e in E)
	  	hire[e] <= sum(t in T)x_et[e][t];
 }
 
 /* ----- Post-processing block ----- */  
 execute 
 {
   writeln("Checkout station planning:");
   for (var e in E)
  	if (hire[e] == 1) {
  		write("The employee " + e + " is assigned to checkout stations in time t = ");
  		for (var t in T) {
    		if (x_et[e][t] == 1) write(t + ", "); 
    	}
    writeln();  		  
   }  
   for (var t in T){
 	write("Time t = " + t + ": \n	Employees: ");
  		for (var e in E)
    		if (x_et[e][t] == 1) write(e + ", ");     		
    	writeln();   		
    }
    writeln(); 	
};	
  
 main
{
	var src = new IloOplModelSource("scheduling.mod");
	var def = new IloOplModelDefinition(src);
	var cplex = new IloCplex();
	var model = new IloOplModel(def,cplex);
	var data = new IloOplDataSource("data.dat");

	model.addDataSource(data);
	model.generate();
	
	cplex.epgap=0.01;
	
	if (cplex.solve()) 
	{
		writeln("The number of hired employees is " + cplex.getObjValue());
   		
   		writeln("Checkout station planning:");   		
   		for (var e in model.E)
  			if (model.hire[e] == 1) {
  				write("The employee " + e + " is assigned to checkout stations in time t = ");
  				for (var t in model.T) {
    				if (model.x_et[e][t] == 1) write(t + ", "); 
    			}
    		writeln();  		  
   			}  
   		
   		for (var t in model.T){
 			write("Time t = " + t + ": \n	Employees: ");
  			for (var e in model.E)
    			if (model.x_et[e][t] == 1) write(e + ", ");     		
    		writeln();   		
   	 	}
    	writeln(); 
	}	
	else { writeln("No solution found!"); }
	
	model.end();
	data.end();
	def.end();
	cplex.end();
	src.end();		
}	   
	  	  	 