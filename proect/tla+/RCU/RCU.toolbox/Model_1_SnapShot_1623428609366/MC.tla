---- MODULE MC ----
EXTENDS RCU, TLC

\* MV CONSTANT declarations@modelParameterConstants
CONSTANTS
c1, c2, c3
----

\* MV CONSTANT declarations@modelParameterConstants
CONSTANTS
v1, v2, v3
----

\* MV CONSTANT definitions Cores
const_1623428607239204000 == 
{c1, c2, c3}
----

\* MV CONSTANT definitions TotalVersions
const_1623428607239205000 == 
{v1, v2, v3}
----

\* SYMMETRY definition
symm_1623428607239206000 == 
Permutations(const_1623428607239204000) \union Permutations(const_1623428607239205000)
----

=============================================================================
\* Modification History
\* Created Sat Jun 12 00:23:27 CST 2021 by kanghongbo
