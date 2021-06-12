-------------------------------- MODULE Raft --------------------------------
EXTENDS TLC

CONSTANT Leader, Candidate, Follower

CONSTANT Server

CONSTANT Majority

CONSTANT Nil

CONSTANT RequestVoteReq, RequestVoteRep

ASSUME 
    Majority \subseteq SUBSET Server
    \A MS1, MS2 \in Majority : MS1 \cap MS2 # {}

VARIABLE messages

VARIABLE votedFor, votesGranted

-----------------------------------------------------------------------------
WithMessage(m, msgs) ==
    IF m \in DOMAIN msgs THEN
        [msgs EXCEPT ![m] = msgs[m] + 1]
    ELSE
        msgs @@ (m :> 1)

WithoutMessage(m, msgs) ==
    IF m \in DOMAIN msgs THEN
        [msgs EXCEPT ![m] = msgs[m] - 1]
    ELSE
        msgs

Send(m) == messages' = WithMessage(m, messages)
Discard(m) == messages' = WithoutMessage(m, messages)
Reply(response, request) == messages' = WithoutMessage(request, WithMessage(response, messages))

Min(s) == CHOOSE x \in s : \A y \in s : x <= y
Max(s) == CHOOSE x \in s : \A y \in s : x >= y

-----------------------------------------------------------------------------
Fail(s) ==
    /\ state' = [state EXCEPT ![s] = Follower]
    /\ currentTerm' = [currentTerm EXCEPT ![s] = 1]
    /\ votedFor' = [votedFor EXCEPT ![s] = Nil]
    /\ votesGranted' = [votesGranted EXCEPT ![s] = {}]

Timeout(s) ==
    /\ state[s] \in {Follower, Candidate}
    /\ state' = [state EXCEPT ![s] = Candidate]
    /\ currentTerm' = [currentTerm EXCEPT ![s] = currentTerm[s] + 1]
    /\ votedFor' = [votedFor EXCEPT ![s] = Nil]
    /\ votesGranted'   = [votesGranted EXCEPT ![s] = {}]
    \*/\ voterLog'       = [voterLog EXCEPT ![s] = [j \in {} |-> <<>>]]
    
RequestVote(s) ==
    /\ state[s] = Candidate
    /\ (votedFor[s] \notin (Server \ {s}))
    /\ \A ss \in Server : Send([Type |-> RequestVoteReq,
                                term |-> currentTerm[s],
                                src |-> s,
                                dst |-> ss])

AppendEntry(s) ==
    /\ state[s] == Leader
    /\ \A ss \in Server : Send([Type |-> AppendEntry,
                                term |-> currentTerm[s],
                                src |-> s,
                                dst |-> ss])

-----------------------------------------------------------------------------
HandleRequestVote(s, t, m) ==
    /\ m.Type == RequestVoteReq
    /\ LET grant == /\ (m.term > currentTerm[s] \/ (m.term = currentTerm[s] /\ votedFor[s] \in {t, Nil}))
       IN /\ \/ (grant /\ votedFor' = [votedFor EXCEPT ![s] = t])
             \/ (~grant /\ UNCHANGED votedFor')
          /\ Reply([Type |-> RequestVoteRep,
                    term |-> currentTerm[s],
                    granted |-> grant,
                    src |-> s,
                    dst |-> t],
                    m)
    

Receive(m) ==
    \/ HandleRequestVote(m)
    
    

-----------------------------------------------------------------------------
Init == 
    \A s \in Server : /\ state = [state EXCEPT ![s] = Follower]
                      /\ currentTerm = [currentTerm EXCEPT ![s] = 1]
                      /\ votedFor = [votedFor EXCEPT ![s] = Nil]
                      /\ votesGranted = [votesGranted EXCEPT ![s] = {}]

Next ==
    \/ \E s \in Server : \/ Fail(s)
                         \/ Timeout(s)
                         \/ RequestVote(s)
                         \/ AppendEntry(s)
    \/ \E m \in messages : Receive(m)


=============================================================================
\* Modification History
\* Created Sat Jun 12 00:47:04 CST 2021 by kanghongbo
