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
const_1623429517697216000 == 
{c1, c2, c3}
----

\* MV CONSTANT definitions TotalVersions
const_1623429517697217000 == 
{v1, v2, v3}
----

\* SYMMETRY definition
symm_1623429517697218000 == 
Permutations(const_1623429517697216000) \union Permutations(const_1623429517697217000)
----

=============================================================================
\* Modification History
\* Created Sat Jun 12 00:38:37 CST 2021 by kanghongbo
