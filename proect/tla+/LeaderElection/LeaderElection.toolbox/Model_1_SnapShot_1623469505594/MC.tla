---- MODULE MC ----
EXTENDS LeaderElection, TLC

\* MV CONSTANT declarations@modelParameterConstants
CONSTANTS
s1, s2, s3
----

\* MV CONSTANT definitions Server
const_1623469503572119000 == 
{s1, s2, s3}
----

\* CONSTANT definitions @modelParameterConstants:4Majority
const_1623469503572120000 == 
{{s1, s2}, {s1, s3}, {s2, s3}, {s1, s2, s3}}
----

\* CONSTANT definitions @modelParameterConstants:5TotalTerm
const_1623469503573121000 == 
{1, 2}
----

=============================================================================
\* Modification History
\* Created Sat Jun 12 11:45:03 CST 2021 by kanghongbo
