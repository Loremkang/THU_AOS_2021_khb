-------------------------------- MODULE RCU --------------------------------
EXTENDS Integers


CONSTANT TotalVersions,
         Cores


VARIABLES   UnfinishedVersions,
            FocusingVersion,
            CurrentVersion,
            VersionState
            

StartReading(r) ==
    /\ FocusingVersion[r] = "empty"
    /\ FocusingVersion' = [FocusingVersion EXCEPT ![r] = CurrentVersion]
    /\ UNCHANGED <<UnfinishedVersions, CurrentVersion, VersionState>>


FinishReading(r) == 
    /\ FocusingVersion' = [FocusingVersion EXCEPT ![r] = "empty"]
    /\ UNCHANGED <<UnfinishedVersions, CurrentVersion, VersionState>>
    


StartWrite(r, ver) ==
    /\ FocusingVersion[r] = "empty"
    /\ UnfinishedVersions' = UnfinishedVersions \ {ver}
    /\ CurrentVersion' = ver
    /\ VersionState[ver].state = "uninit"
    /\ VersionState' = [VersionState EXCEPT ![ver] = [state |-> "init", scheduled |-> [core \in Cores |-> "unfinished"]]]
    /\ UNCHANGED <<FocusingVersion>>

ScheduleWrite(r, ver) == 
    \*/\ FocusingVersion[r] = "empty"
    /\ VersionState[ver].state = "init"
    /\ VersionState[ver]["scheduled"][r] = "unfinished"
    /\ VersionState' = [VersionState EXCEPT ![ver]["scheduled"][r] = "finished"]
    /\ UNCHANGED <<UnfinishedVersions, FocusingVersion, CurrentVersion>>

FinishWrite(r, ver) ==
    /\ FocusingVersion[r] = "empty"
    /\ VersionState[ver].state = "init"
    /\ \A core \in Cores : VersionState[ver]["scheduled"][core] = "finished"
    /\ VersionState' = [VersionState EXCEPT ![ver]["state"] = "deleted"]
    /\ UNCHANGED <<UnfinishedVersions, FocusingVersion, CurrentVersion>>

RCUInit == 
    /\ UnfinishedVersions = TotalVersions
    /\ CurrentVersion = "empty"
    /\ FocusingVersion = [c \in Cores |-> "empty"]
    /\ VersionState = [v \in TotalVersions |-> [state |-> "uninit"]]


RCUNext == 
    \/ \E c \in Cores : \/ StartReading(c)
                        \/ FinishReading(c)
                        \/ \E v \in UnfinishedVersions : StartWrite(c, v)
                        \/ \E v \in TotalVersions : ScheduleWrite(c, v)
                        \/ \E v \in TotalVersions : FinishWrite(c, v)

RCUNoBadPointer == 
    (*~ \E ver \in TotalVersions :
        /\ VersionState[ver].state = "deleted"
        /\ \A c \in Cores : VersionState[ver].scheduled[c] = "finished"*)
    /\ \A c \in Cores : \/ FocusingVersion[c] = "empty"
                        \/ VersionState[FocusingVersion[c]].state /= "deleted"

=============================================================================
\* Modification History
\* Last modified Sat Jun 12 00:23:16 CST 2021 by kanghongbo
\* Created Fri Jun 11 22:40:19 CST 2021 by kanghongbo
