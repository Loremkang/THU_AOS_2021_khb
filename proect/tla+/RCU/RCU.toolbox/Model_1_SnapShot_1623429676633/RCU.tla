-------------------------------- MODULE RCU --------------------------------
EXTENDS Integers


CONSTANT TotalVersions,
         Cores


VARIABLES   UnfinishedVersions,
            FocusingVersion,
            CurrentVersion,
            DeletionState
            

StartReading(r) ==
    /\ FocusingVersion[r] = "empty"
    /\ FocusingVersion' = [FocusingVersion EXCEPT ![r] = CurrentVersion]
    /\ UNCHANGED <<UnfinishedVersions, CurrentVersion, DeletionState>>


FinishReading(r) == 
    /\ FocusingVersion' = [FocusingVersion EXCEPT ![r] = "empty"]
    /\ UNCHANGED <<UnfinishedVersions, CurrentVersion, DeletionState>>
    

Update(r, ver) == 
    \*/\ FocusingVersion[r] = "empty"
    /\ UnfinishedVersions' = UnfinishedVersions \ {ver}
    /\ CurrentVersion' = ver
    /\ DeletionState[CurrentVersion].state = "uninit"
    /\ DeletionState' = [DeletionState EXCEPT ![CurrentVersion] = [state |-> "init", scheduled |-> [core \in Cores |-> "unfinished"]]]
    /\ UNCHANGED <<FocusingVersion>>

ScheduleDelete(r, ver) == 
    /\ FocusingVersion[r] = "empty"
    /\ DeletionState[ver].state = "init"
    /\ DeletionState[ver]["scheduled"][r] = "unfinished"
    /\ DeletionState' = [DeletionState EXCEPT ![ver]["scheduled"][r] = "finished"]
    /\ UNCHANGED <<UnfinishedVersions, FocusingVersion, CurrentVersion>>

FinishDelete(r, ver) ==
    /\ FocusingVersion[r] = "empty"
    /\ DeletionState[ver].state = "init"
    /\ \A core \in Cores : DeletionState[ver]["scheduled"][core] = "finished"
    /\ DeletionState' = [DeletionState EXCEPT ![ver]["state"] = "deleted"]
    /\ UNCHANGED <<UnfinishedVersions, FocusingVersion, CurrentVersion>>

RCUInit == 
    /\ CurrentVersion = (CHOOSE v \in TotalVersions : TRUE)
    /\ UnfinishedVersions = TotalVersions \ {CurrentVersion}
    /\ FocusingVersion = [c \in Cores |-> "empty"]
    /\ DeletionState = [v \in TotalVersions |-> [state |-> "uninit"]]


RCUNext == 
    \/ \E c \in Cores : \/ StartReading(c)
                        \/ FinishReading(c)
                        \/ \E v \in UnfinishedVersions : Update(c, v)
                        \/ \E v \in TotalVersions : ScheduleDelete(c, v)
                        \/ \E v \in TotalVersions : FinishDelete(c, v)

RCUNoBadPointer == 
    (*~ \E ver \in TotalVersions :
        /\ DeletionState[ver].state = "deleted"
        /\ \A c \in Cores : DeletionState[ver].scheduled[c] = "finished"*)
    /\ \A c \in Cores : \/ FocusingVersion[c] = "empty"
                        \/ DeletionState[FocusingVersion[c]].state /= "deleted"

=============================================================================
\* Modification History
\* Last modified Sat Jun 12 00:41:14 CST 2021 by kanghongbo
\* Created Fri Jun 11 22:40:19 CST 2021 by kanghongbo
