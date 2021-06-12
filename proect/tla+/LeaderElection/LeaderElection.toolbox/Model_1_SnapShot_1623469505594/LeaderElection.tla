--------------------------- MODULE LeaderElection ---------------------------
EXTENDS TLC, Integers

CONSTANT Leader, Candidate, Follower

CONSTANT Server

CONSTANT Majority

CONSTANT Nil

CONSTANT RequestVoteReqType, RequestVoteRepType, AppendEntryType

CONSTANT TotalTerm

ASSUME 
    /\ Majority \subseteq SUBSET Server
    /\ \A MS1, MS2 \in Majority : MS1 \cap MS2 # {}

VARIABLE messages

VARIABLE votedFor, currentTerm

VARIABLE state, votesGranted

-----------------------------------------------------------------------------
Min(s) == CHOOSE x \in s : \A y \in s : x <= y
Max(s) == CHOOSE x \in s : \A y \in s : x >= y

WithMessage(m, msgs) ==
    msgs \cup {m}
    (*IF m \in DOMAIN msgs THEN
        [msgs EXCEPT ![m] = 2]
    ELSE
        msgs @@ (m :> 1)*)

WithoutMessage(m, msgs) ==
    msgs \ {m}
    (*IF m \in DOMAIN msgs THEN
        [msgs EXCEPT ![m] = Max({msgs[m] - 1, 0})]
    ELSE
        msgs*)

Send(m) == messages' = WithMessage(m, messages)
Discard(m) == messages' = WithoutMessage(m, messages)
Reply(response, request) == messages' = WithoutMessage(request, WithMessage(response, messages))

-----------------------------------------------------------------------------
Fail(s) ==
    /\ state' = [state EXCEPT ![s] = Follower]
    \*/\ currentTerm' = [currentTerm EXCEPT ![s] = 1]
    \*/\ votedFor' = [votedFor EXCEPT ![s] = Nil]
    /\ votesGranted' = [votesGranted EXCEPT ![s] = {}]
    /\ votedFor = [votedFor EXCEPT ![s] = Nil]
    /\ UNCHANGED << currentTerm, messages >>

\* Timeout(s) ==
\*     /\ state[s] \in {Follower, Candidate}
\*     /\ state' = [state EXCEPT ![s] = Candidate]
\*     /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[s] + 1]
\*     /\ votedFor' = [votedFor EXCEPT ![s] = Nil]
\*     /\ votesGranted'   = [votesGranted EXCEPT ![s] = {}]
\*     \*/\ voterLog'       = [voterLog EXCEPT ![s] = [j \in {} |-> <<>>]]
   
(*RequestVote(s) ==
    /\ state[s] \in {Follower, Candidate}
    /\ state' = [state EXCEPT ![s] = Candidate]
    /\ (currentTerm[s] + 1) \in TotalTerm
    /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[s] + 1]
    /\ votedFor' = [votedFor EXCEPT ![s] = s]
    /\ UNCHANGED << votesGranted, messages >>*)

RequestVote(s) ==
    /\ state[s] \in {Follower, Candidate}
    /\ state' = [state EXCEPT ![s] = Candidate]
    /\ (currentTerm[s] + 1) \in TotalTerm
    /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[s] + 1]
    /\ votedFor' = [votedFor EXCEPT ![s] = s]
    /\ messages' = messages \cup {[type |-> RequestVoteReqType,
                                   term |-> currentTerm[s] + 1,
                                   src |-> s,
                                   dst |-> ss] : ss \in Server}
    (*/\ \A ss \in Server : Send([type |-> RequestVoteReqType,
                                term |-> currentTerm[s],
                                src |-> s,
                                dst |-> ss])*)
    /\ UNCHANGED << votesGranted >>

BecomeLeader(s) ==
    /\ state[s] = Candidate
    /\ votesGranted[s] \in Majority
    /\ state' = [state EXCEPT ![s] = Leader]
    /\ UNCHANGED << messages, votedFor, currentTerm, votesGranted >>

AppendEntry(s) ==
    /\ state[s] = Leader
    /\ \A ss \in Server : Send([type |-> AppendEntryType,
                                term |-> currentTerm[s],
                                src |-> s,
                                dst |-> ss])
    /\ UNCHANGED << messages, votedFor, votesGranted >>

-----------------------------------------------------------------------------
HandleRequestVote(s, t, m) ==
    /\ m.type = RequestVoteReqType
    /\ IF (m.term > currentTerm[s])
        THEN (currentTerm' = [currentTerm EXCEPT ![s] = m.term]
              /\ state' = [state EXCEPT ![s] = Follower]
              /\ votedFor' = [votedFor EXCEPT ![s] = t]
              /\ votesGranted' = [votesGranted EXCEPT ![s] = {}]
              /\ Reply([type |-> RequestVoteRepType,
                    term |-> m.term,
                    granted |-> TRUE,
                    src |-> s,
                    dst |-> t], m))
        ELSE IF (m.term = currentTerm[s] /\ votedFor[s] \in {t, Nil})
            THEN (votedFor' = [votedFor EXCEPT ![s] = t]
                  /\ UNCHANGED << currentTerm, state, votesGranted >>
                  /\ Reply([type |-> RequestVoteRepType,
                    term |-> m.term,
                    granted |-> TRUE,
                    src |-> s,
                    dst |-> t], m))
            ELSE (Discard(m) /\ UNCHANGED << currentTerm, state, votesGranted, votedFor >>)

HandleRequestVoteReply(s, t, m) ==
    /\ m.type = RequestVoteRepType
    /\ IF (m.term > currentTerm[s])
        THEN (currentTerm' = [currentTerm EXCEPT ![s] = m.term]
              /\ state' = [state EXCEPT ![s] = Follower]
              /\ votedFor' = [votedFor EXCEPT ![s] = Nil]
              /\ votesGranted' = [votesGranted EXCEPT ![s] = {}])
        ELSE IF ( m.term = currentTerm[s] /\ m.granted = TRUE)
            THEN (votesGranted' = [votesGranted EXCEPT ![s] = votesGranted[s] \cup {t}]
                  /\ UNCHANGED << currentTerm, state, votedFor >>)
            ELSE UNCHANGED << currentTerm, state, votedFor, votesGranted >>
    /\ Discard(m)


HandleAppendEntry(s, t, m) ==
    /\ m.type = AppendEntryType
    /\ IF m.term > currentTerm[s]
        THEN (currentTerm' = [currentTerm EXCEPT ![s] = m.term]
              /\ state' = [state EXCEPT ![s] = Follower]
              /\ votedFor' = [votedFor EXCEPT ![s] = Nil]
              /\ votesGranted' = [votesGranted EXCEPT ![s] = {}])
        ELSE UNCHANGED << currentTerm, state, votedFor, votesGranted >>

Receive(m) ==
    \/ HandleRequestVote(m.dst, m.src, m)
    \/ HandleAppendEntry(m.dst, m.src, m)
    \/ HandleRequestVoteReply(m.dst, m.src, m)

-----------------------------------------------------------------------------
Init == 
    /\ state = [s \in Server |-> Follower]
    /\ currentTerm = [s \in Server |-> 1]
    /\ votedFor = [s \in Server |-> Nil]
    /\ votesGranted = [s \in Server |-> {}]
    /\ messages = {}
    
Next ==
    \/ \E s \in Server : \/ Fail(s)
                         \/ RequestVote(s)
                         \/ BecomeLeader(s)
                         \*\/ AppendEntry(s)
    \/ \E m \in messages : Receive(m)

-----------------------------------------------------------------------------

Test == 
    \A s \in Server : currentTerm[s] = 1

(*NoMessage == 
    messages = {}*)
    
 
NoGrantedMessage ==
    TRUE
    \*~ \E m \in messages : m.type = RequestVoteRepType
    \*~ \E s \in Server : votesGranted[s] # {}
    
NoLeader == 
    TRUE
    \*~ \E s1 \in Server : state[s1] = Leader
    
OnlyOneLeaderEachTerm == 
    ~ (\E s1, s2 \in Server : /\ s1 # s2
                              /\ currentTerm[s1] = currentTerm[s2]
                              /\ state[s1] = Leader
                              /\ state[s2] = Leader)

=============================================================================
\* Modification History
\* Last modified Sat Jun 12 11:45:01 CST 2021 by kanghongbo
\* Created Sat Jun 12 09:36:48 CST 2021 by kanghongbo
