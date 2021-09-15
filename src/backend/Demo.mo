import Types "Types";

/// Demo script types
module {
  public type UserId = Types.UserId;
  public type SongId = Types.SongId;

  public type Command = {
    #reset : Types.TimeMode ;
    #putRewardTransfer : { sender : UserId ; receiver : UserId ; amount : Nat };
    #createTestData : { users : [UserId] ; songs : [(UserId, SongId)] };
    #putSuperLike : { userId : UserId ; songId : SongId ; superLikes : Bool };
    #putProfileFollow : { userId : UserId ; toFollow : UserId ; follows : Bool }; 
    #assertSongVirality : { songId : SongId ; isViral : Bool };
    #assertSongFeed : { userId : UserId ; limit : ?Nat ; songsPred : SongsPred };
 };
  
  public type SongsPred = {
    #containsAll : [SongId] ; // order independent check.
    #equals : [SongId] ; // order dependent check.
  };

  public type Result = {
    #ok ;
    #err : Text
  };

  public type TraceCommand = {
    command : Command ;
    result : Result ;
  };

  public type Trace = {
    status : {#ok ; #err } ;
    trace : [TraceCommand]
  };

}
