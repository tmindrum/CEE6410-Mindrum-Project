$ontext
CEE 6410 - Water Resources Systems Analysis
Semester Project

THE PROBLEM:

Optimize a pipeline between a reservoir and a water treatment plant to have the lowest construction cost.

A simple schematic of the problem can be found below:         
                   Reservoir
                   /   |   \
                  A    B    C
                   \  /    /
                    D     /
                      \  /
                      WTP

For this problem a cost per each unit length of pipe was created. This accounted for slope, pipe diameter, and pipe length.
Pipe segments with a higher slope, pipe diameter, and pipe length had larger costs. These values can be changed to match
needs of other pipeline routing problems.

THE SOLUTION: uses General Algebraic Modeling System with mixed integer programming (MIP)

Tyler Mindrum
a02355861@usu.edu
December 10, 2025

$offText


* 1. Define the SETS
Set n  "nodes" / RES, A, B, C, D, WTP /;
Alias (n,nn);

* pipeline segments defined as a set of ordered pairs
Set seg(n,nn) "possible pipeline segments"
      /RES.A,
       RES.B,
       RES.C,
         A.D,
         A.WTP,
         B.D,
         C.WTP,
         D.WTP/;

* Intermediate nodes (excluding RES and WTP)
Set interNodes(n) / A, B, C, D /;


* 2. DEFINE input data (change based on problem needs)
Scalar demand "required flow to WTP (vol/time)"  / 100 /;
Scalar Mflow "maximum flow to WTP (vol/time)"   / 1e5 /;
Scalar Mdiam "maximum diameter of pipe segments (length)"   / 100 /;
Scalar minDiam "minimum diameter of pipe segments (length)" / 5   /;


* Capacity of each segment
Parameter cap(n,nn); 
cap(seg)  = 500;

* Cost per unit lenght of each pipe segment, takes into account cost per slope and diameter.
Parameter cost(n,nn);
cost('RES','A') = 10;
cost('RES','B') = 8;
cost('RES','C') =  9;
cost('A','D')   =  7;
cost('A','WTP') =  15;
cost('B','D')   =  8;
cost('C','WTP') = 20;
cost('D','WTP') =  5;


* 3. DEFINE the variables
Positive Variables
    flow(n,nn)   "flow through each pipe segment (vol/time)"
    diam(n,nn)   "diameter of each pipe segment (length)";

Binary Variables
    usepipe(n,nn) "1 if the segment is used"
    nodeUsed(n)   "1 if the node A,B,C or D is used";

Variable z "total cost, we are looking to minimize ($)";


* 4. COMBINE variables and data in equations
Equation
    capCons(n,nn) flow capacity constraint
    diamMin(n,nn) minimum diameter
    diamMax(n,nn) maximum diameter
    flowLink(n,nn) links flow to binary
    flowBalance(n) flow conservation at nodes
    demandCons demand at WTP
    nodeDef1(n) detects if pipe segments entering a node are used
    nodeDef2(n) detects if pipe segments exiting a node are used
    atLeastOneNode makes sure that nodes are used
    obj minimizes the cost of construction of pipeline;

capCons(n,nn)$seg(n,nn)..       flow(n,nn) =l= cap(n,nn);
diamMin(n,nn)$seg(n,nn)..       diam(n,nn) =g= minDiam * usepipe(n,nn);
diamMax(n,nn)$seg(n,nn)..       diam(n,nn) =l= Mdiam * usepipe(n,nn);
flowLink(n,nn)$seg(n,nn)..      flow(n,nn) =l= Mflow * usepipe(n,nn);
flowBalance(n)$interNodes(n)..  sum(nn$seg(nn,n), flow(nn,n)) =e= sum(nn$seg(n,nn), flow(n,nn));
demandCons..                    sum(nn$seg(nn,'WTP'), flow(nn,'WTP')) =g= demand;
nodeDef1(n)$interNodes(n)..     sum(nn$seg(nn,n), usepipe(nn,n)) =g= nodeUsed(n);
nodeDef2(n)$interNodes(n)..     sum(nn$seg(n,nn), usepipe(n,nn)) =g= nodeUsed(n);
atLeastOneNode..                sum(n$interNodes(n), nodeUsed(n)) =g= 1;
obj..                           z =e= sum((n,nn)$seg(n,nn), cost(n,nn) * diam(n,nn));

* 5. DEFINE the MODEL from the EQUATIONS
Model pipelineRoute /all/;


* 6. SOLVE the MODEL
Solve pipelineRoute using mip minimizing z;
