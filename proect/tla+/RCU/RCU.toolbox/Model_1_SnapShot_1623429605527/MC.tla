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
const_1623429603507228000 == 
{c1, c2, c3}
----

\* MV CONSTANT definitions TotalVersions
const_1623429603507229000 == 
{v1, v2, v3}
----

\* SYMMETRY definition
symm_1623429603507230000 == 
Permutations(const_1623429603507228000) \union Permutations(const_1623429603507229000)
----

=============================================================================
\* Modification History
\* Created Sat Jun 12 00:40:03 CST 2021 by kanghongbo
