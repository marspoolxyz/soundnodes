import Cycles "mo:base/ExperimentalCycles";
import Access "../backend/Access";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Base "../backend/Base";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Demo "../backend/Demo";
import DemoCan30 "Demo/Can30_SongRecommendations";
import DemoCan32 "Demo/Can32_ViralEvent";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import P "mo:base/Prelude";
import Param "../backend/Param";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Rel "../backend/Rel";
import RelObj "../backend/RelObj";
import State "../backend/State";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieMap "mo:base/TrieMap";
import Types "../backend/Types";

shared ({caller = initPrincipal}) actor class SoundNodes () /* : Types.Service */ {

  public type ProfileInfo = Types.ProfileInfo;
  public type ProfileInfoPlus = Types.ProfileInfoPlus;
  public type ProfilePic = Types.ProfilePic;
  public type Timestamp = Types.Timestamp;
  public type UserId = Types.UserId;
  public type SongId = Types.SongId;
  public type ChunkId = Types.ChunkId;
  public type ChunkData = Types.ChunkData;
  public type SongInfo = Types.SongInfo;
  public type SongInit = Types.SongInit;
  public type SongPic = Types.SongPic;
  public type SongResult = Types.SongResult;
  public type SongResults = Types.SongResults;

  var state = State.empty({ admin = initPrincipal });

  /*public query*/ func getState() : async State.StateShared {
    State.share(state)
  };

  /*public*/ func setState(st : State.StateShared) : async () {
    state := State.fromShared(st);
  };

  public query func checkUsernameAvailable(userName_ : Text): async Bool {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ false };
      case null { /* ok, not taken yet. */ true };
    }
  };

  /// null means that the principal is unrecognized,
  /// otherwise, returns a non-empty array of usernames.
  public shared(msg) func getUserNameByPrincipal(p:Principal) : async ?[Text] {
    if ( msg.caller == p ) {
      ?state.access.userPrincipal.get1(p)
    } else {
      // access control check fails; do not reveal username of p.
      null
    }
  };


  // responsible for adding metadata from the user to the state.
  // a null principal means that the username has no valid callers (yet), and the admin
  // must relate one or more principals to it.
  func createProfile_(userName_ : Text, p: ?Principal, pic_ : ?ProfilePic) : ?() {
    switch (state.profiles.get(userName_)) {
      case (?_) { /* error -- ID already taken. */ null };
      case null { /* ok, not taken yet. */
        let now = timeNow_();
        state.profiles.put(userName_, {
            userName = userName_ ;
            createdAt = now ;
        });
        // rewards init invariant: rewards is initialized to zero (is non-null).
        state.rewards.put(userName_, 0);
        state.access.userRole.put(userName_, #user);
        switch p {
          case null { }; // no related principals, yet.
          case (?p) { state.access.userPrincipal.put(userName_, p); }
        };
        // success
        ?()
      };
    }
  };



  func accessCheck(caller : Principal, action : Types.UserAction, target : Types.ActionTarget) : ?() {
    state.access.check(timeNow_(), caller, action, target)
  };

  public shared(msg) func createProfile(userName : Text, pic : ?ProfilePic) : async ?ProfileInfoPlus {
    do ? {
      createProfile_(userName, ?msg.caller, pic)!;
      // return the full profile info
      getProfilePlus_(?userName, userName)! // self-view
    }
  };

  public shared(msg) func createUserProfile(userName : Text) : async ?ProfileInfoPlus {
    do ? {
      createProfile_(userName, ?msg.caller, null)!;
      // return the full profile info
      getProfilePlus_(?userName, userName)! // self-view
    }
  };

  var timeMode : {#ic ; #script} =
    switch (Param.timeMode) {
     case (#ic) #ic;
     case (#script _) #script
    };

  var scriptTime : Int = 0;

  func timeNow_() : Int {
    switch timeMode {
      case (#ic) { Time.now() };
      case (#script) { scriptTime };
    }
  };

  public shared(msg) func scriptTimeTick() : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      assert (timeMode == #script);
      scriptTime := scriptTime + 1;
    }
  };

  func reset_( mode : { #ic ; #script : Int } ) {
    setTimeMode_(mode);
    state := State.empty({ admin = state.access.admin });
  };

  public shared(msg) func reset( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      reset_(mode)
    }
  };

  func setTimeMode_( mode : { #ic ; #script : Int } ) {
    switch mode {
      case (#ic) { timeMode := #ic };
      case (#script st) { timeMode := #script ; scriptTime := st };
    }
  };

  public shared(msg) func setTimeMode( mode : { #ic ; #script : Int } ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      setTimeMode_(mode)
    }
  };

  func getProfileInfo_(target : UserId) : ?ProfileInfo {
    do ? {
      let profile = state.profiles.get(target)!;
      let following_ = state.follows.get0(target);
      let followers_ = state.follows.get1(target);
      let likes_ = state.likes.get0(target);
      let superLikes_ = state.superLikes.get0(target);
      let uploaded_ = state.uploaded.get0(target);
      let rewards_ = state.rewards.get(target)!;
      let abuseFlagCount_ = state.abuseFlagSongs.get1Size(target);
      {
        userName = profile.userName ;
        followers = filterOutAbuseUsers(followers_)! ;
        following = filterOutAbuseUsers(following_)! ;
        likedSongs = filterOutAbuseSongs(likes_)! ;
        superLikedSongs = filterOutAbuseSongs(superLikes_)! ;
        uploadedSongs = filterOutAbuseSongs(uploaded_)! ;
        hasPic = false ;
        rewards = rewards_;
        abuseFlagCount = abuseFlagCount_ ;
      }
    }
  };

  public query(msg) func getProfileInfo(userId : UserId) : async ?ProfileInfo {
    do ? {
      accessCheck(msg.caller, #view, #user userId)!;
      getProfileInfo_(userId)!
    }
  };

  /// "Deeper" version of ProfileInfo.
  ///
  /// Gives Song- and ProfileInfos instead of merely Ids in the results.
  ///
  /// The optional "caller" UserId personalizes the resulting record for
  /// various cases:
  /// - When caller is not given, less information is non-null in result.
  /// - When calling user is viewing their own profile,
  ///   gives private and quasi-private info to them about their allowances.
  /// - When calling user is viewing profile of another user,
  ///   gives private info about super likes / abuse flags toward that use.
  public query(msg) func getProfilePlus(caller: ?UserId, target: UserId): async ?ProfileInfoPlus {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      switch caller {
        case null { getProfilePlus_(null, target)! };
        case (?callerUserName) {
               // has private access to our caller view?
               accessCheck(msg.caller, #update, #user callerUserName)!;
               getProfilePlus_(?callerUserName, target)!
             };
      }
    }
  };

  func filterOutAbuseSongs(songs: [SongId]) : ?[SongId] {
    do ? {
      let nonAbuse = Buffer.Buffer<SongId>(0);
      for (v in songs.vals()) {
        let flags = state.abuseFlagSongs.get1Size(v);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(v)
        }
      };
      nonAbuse.toArray()
    }
  };

  func filterOutAbuseUsers(users: [UserId]) : ?[UserId] {
    do ? {
      let nonAbuse = Buffer.Buffer<UserId>(0);
      for (u in users.vals()) {
        let flags = state.abuseFlagUsers.get1Size(u);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(u)
        }
      };
      nonAbuse.toArray()
    }
  };

  func getNonAbuseSongs(caller: ?UserId, songs: [SongId]) : ?[SongInfo] {
    do ? {
      let nonAbuse = Buffer.Buffer<SongInfo>(0);
      for (v in songs.vals()) {
        let flags = state.abuseFlagSongs.get1Size(v);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(getSongInfo_(caller, v)!)
        }
      };
      nonAbuse.toArray()
    }
  };

  func getNonAbuseProfiles(users: [UserId]) : ?[ProfileInfo] {
    do ? {
      let nonAbuse = Buffer.Buffer<ProfileInfo>(0);
      for (u in users.vals()) {
        let flags = state.abuseFlagUsers.get1Size(u);
        if (flags < Param.contentModerationThreshold) {
          nonAbuse.add(getProfileInfo_(u)!)
        }
      };
      nonAbuse.toArray()
    }
  };

  func computeAllowance_(limitPerRecentDuration : Nat,
                         collectEvent : State.Event.Event -> Bool,
  ) : Types.AllowanceBalance {
    if (limitPerRecentDuration == 0) {
      #zeroForever
    } else {
      let now = timeNow_();
      let matches = collectLogMatches(collectEvent);
      if (matches.size() < limitPerRecentDuration) {
        #nonZero (limitPerRecentDuration - matches.size()) // total remaining.
      } else {
        // assert invariant: we do not exceed the limit.
        assert matches.size() == limitPerRecentDuration;
        let leastRecentTime = matches[matches.size() - 1].time;
        #zeroUntil (leastRecentTime + Param.recentPastDuration) // total wait.
      }
    }
  };

  // targetId -- for hashing the targets of abuse flags
  func targetText(target : Types.ActionTarget) : Text {
    switch target {
    case (#song(i)) "#song=" # i;
    case (#user(i)) "#user=" # i;
    case _ { loop { assert false } };
    }
  };

  // targetHash -- for collecting sets of targets, and doing set operations.
  func targetHash(target : Types.ActionTarget) : Hash.Hash {
    Text.hash(targetText(target))
  };

  func targetEqual(targ1 : Types.ActionTarget, targ2 : Types.ActionTarget) : Bool {
    targ1 == targ2
  };

  func getUserAllowances_(user: UserId) : Types.UserAllowances {
    {
      abuseFlags = do {
        let targets = TrieMap.TrieMap<Types.ActionTarget, Bool>(targetEqual, targetHash);
        computeAllowance_(
          Param.maxRecentAbuseFlags,
          // true when we INCLUDE an event in the total
          func (ev: State.Event.Event) : Bool {
            switch (ev.kind) {
            case (#abuseFlag(af)) {
                   if (af.reporter != user) { return false };
                   switch (targets.get(af.target)) {
                     case null {
                            targets.put(af.target, af.flag);
                            af.flag
                          };
                     case (?b) { b }
                   }};
            case _ { false };
            }
          },
        )};

      superLikes = do {
        let targets = TrieMap.TrieMap<Types.ActionTarget, Bool>(targetEqual, targetHash);
        computeAllowance_(
          Param.maxRecentSuperLikes,
          func (ev: State.Event.Event) : Bool {
            switch (ev.kind) {
            case (#superLikeSong(slv)) {
                   if (slv.source != user) { return false };
                   switch (targets.get(#song(slv.target))) {
                     case null {
                            targets.put(#song(slv.target), slv.superLikes);
                            slv.superLikes
                          };
                     case (?b) { b }
                   }};
            case _ { false };
            }
            }
        )};
    }
  };

  func getProfilePlus_(caller: ?UserId, userId: UserId): ?ProfileInfoPlus {
    do ? {
      let profile = state.profiles.get(userId)!;
      {
        userName = profile.userName;
        following = getNonAbuseProfiles(state.follows.get0(userId))!;
        followers = getNonAbuseProfiles(state.follows.get1(userId))!;
        likedSongs = getNonAbuseSongs(caller, state.likes.get0(userId))!;
        uploadedSongs = getNonAbuseSongs(caller, state.uploaded.get0(userId))!;
        hasPic = false;
        rewards = state.rewards.get(userId)!;
        abuseFlagCount = state.abuseFlagUsers.get1Size(userId) ; // count total for userId.
        viewerHasFlagged = do ? { // if caller is non-null,
          state.abuseFlagUsers.isMember(caller!, userId) ; // check if we are there.
        };
        allowances = do ? { if (caller! == userId) {
          getUserAllowances_(caller!)
        } else { null! } };
      }
    }
  };

  public query(msg) func getProfiles() : async ?[ProfileInfo] {
    do ? {
      let b = Buffer.Buffer<ProfileInfo>(0);
      for ((p, _) in state.profiles.entries()) {
        b.add(getProfileInfo_(p)!)
      };
      b.toArray()
    }
  };

  public query(msg) func getSongs() : async ?[SongInfo] {
    do ? {
      let b = Buffer.Buffer<SongInfo>(0);
      for ((v, _) in state.songs.entries()) {
        b.add(getSongInfo_(null, v)!)
      };
      b.toArray()
    }
  };

  public query(msg) func getProfilePic(userId : UserId) : async ?ProfilePic {
    do ? {
      state.profilePics.get(userId)!
    }
  };

  public shared(msg) func putRewards(
    receiver : UserId,
    amount : Nat
  ) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #user receiver)!;
      let bal = state.rewards.get(receiver)!;
      state.rewards.put(receiver, bal + amount);
    }
  };

  public shared(msg) func putRewardTransfer(
    sender : UserId,
    receiver : UserId,
    amount : Nat
  ) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user sender)!;
      putRewardTransfer_(sender, receiver, amount)!
    }
  };

  func putRewardTransfer_(sender : UserId,
                          receiver : UserId, amount : Nat) : ?() {
    do ? {
      let balSrc = state.rewards.get(sender)!;
      let balTgt = state.rewards.get(receiver)!;
      if (balSrc >= amount) {
        state.rewards.put(sender, balSrc - amount);
        state.rewards.put(receiver, balTgt + amount);

        state.messages.put(receiver,
           { id = state.eventCount;
             time = timeNow_();
             event = #transferReward {
               rewards = amount;
             }
           });

      } else { return null }
    }
  };

  public shared(msg) func putProfilePic(userId : UserId, pic : ?ProfilePic) : async ?() {
    do ? {
      switch pic {
      case (?pic) { state.profilePics.put(userId, pic) };
      case null { ignore state.profilePics.remove(userId) };
      }
    }
  };

  func getSongResult(i : SongId) : ?SongResult {
    do ? {
      (getSongInfo_(null, i)!, state.songPics.get(i))
    }
  };

  func getUserUploaded(userId : UserId, limit : ?Nat) : ?SongResults {
    do ? {
      let buf = Buffer.Buffer<SongResult>(0);
      for (vid in state.uploaded.get0(userId).vals()) {
        buf.add((getSongResult vid)!)
      };
      buf.toArray()
    }
  };

  func getFeedSongs_(userId : UserId, limit : ?Nat) : ?SongResults {
    do ? {
      let vids = HashMap.HashMap<Text, ()>(0, Text.equal, Text.hash);
      let _ = state.profiles.get(userId)!; // assert userId exists
      let buf = Buffer.Buffer<SongResult>(0);
      let followIds = state.follows.get0(userId);
      label loopFollows
      for (i in followIds.vals()) {
        switch limit { case null { }; case (?l) { if (buf.size() == l) { break loopFollows } } };
        let vs = getUserUploaded(i, limit)!;
        for ((vi, vp) in vs.vals()) {
          if (vids.get(vi.songId) == null) {
            vids.put(vi.songId, ());
            buf.add((vi, vp));
          }
        }
      };
      label loopAll
      for ((vid, v) in state.songs.entries()) {
        switch limit { case null { }; case (?l) { if (buf.size() == l) { break loopAll } } };
        if (vids.get(vid) == null) {
            vids.put(vid, ());
            let vPic = state.songPics.get(vid);
            let vi = getSongInfo_(?userId, vid)!;
            buf.add((vi, vPic));
        }
      };
      buf.toArray()
    }
  };

  public query(msg) func getFeedSongs(userId : UserId, limit : ?Nat) : async ?SongResults {
    do ? {
      // privacy check: because we personalize the feed (example is abuse flag information).
      accessCheck(msg.caller, #update, #user userId)!;
      getFeedSongs_(userId, limit)!
    }
  };

  public func greet(name : Text) : async Text {
        return "Hello, " # name # "!";
  };

  public query(msg) func getProfileSongs(i : UserId, limit : ?Nat) : async ?SongResults {
    do ? {
      accessCheck(msg.caller, #view, #user i)!;
      let buf = Buffer.Buffer<SongResult>(0);
      let vs = getUserUploaded(i, limit)!;
      for (v in vs.vals()) {
        buf.add(v)
      };
      buf.toArray()
    }
  };

  public query(msg) func getSearchSongs(userId : UserId, terms : [Text], limit : ?Nat) : async ?SongResults {
    do ? {
      accessCheck(msg.caller, #view, #user userId)!;
      getFeedSongs_(userId, limit)!;
    }
  };

  // check if adding the source-target pair "now" in the log is valid.
  // needed here (backend logic) and by front-end logic, when rendering enabled/disabled button status for superLike controls.
  func getSuperLikeValidNow_(source : UserId, target : SongId) : Bool {
    let notRecent = timeNow_() - Param.recentPastDuration;
    let superLiked = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    superLiked.put(target, true);
    var count = 1;

     

    count <= Param.maxRecentSuperLikes;
  };

  func songIsViral(songId : SongId) : Bool {
    Option.isSome(do ? {
          let v = state.songs.get(songId)!;
          v.viralAt!
    })
  };

  /// Collect "recent events" that match from the log.
  ///
  /// Visits events and orders array as most-to-least recent matching events.
  /// (Most recent match is first visited and first in output, if any.
  /// Least recent match is last visited and last in output, if any.)
  ///
  /// Generalizes checkEmitSongViral_.
  ///
  /// This is "efficient enough" because we never check the full log,
  /// and we intend to accelerate this operation further with
  /// more pre-emptive caching of what we learn from doing this linear scan.
  /// (Util this linear scan is too slow, let's avoid the complexity of more caching.)
  func collectLogMatches(
    collectEvent : State.Event.Event -> Bool,
  ) : [State.Event.Event] {
    let now = timeNow_();
    let notRecent = now - Param.recentPastDuration;
    let matches = Buffer.Buffer<State.Event.Event>(0);
  
    matches.toArray()
  };

  // check if we need to emit viral song signal to CanCan logic.
  func checkEmitSongViral_(song : SongId) {
    let vinfo = Option.unwrap(state.songs.get(song));
    if (Option.isSome(vinfo.viralAt)) {
        return;
    };

    let now = timeNow_();
    let notRecent = now - Param.recentPastDuration;
    let superLiked = HashMap.HashMap<Text, Bool>(0, Text.equal, Text.hash);
    let superLikers = Buffer.Buffer<State.Event.ViralSongSuperLiker>(0);

    label hugeLog


    if(superLikers.size() >= Param.superLikeViralThreshold) {
        state.songs.put(song,
                         {
                             userId = vinfo.userId ;
                             uploadedAt = vinfo.uploadedAt ;
                             listenCount = vinfo.listenCount ;
                             createdAt = vinfo.createdAt ;
                             viralAt = ?now;
                             caption = vinfo.caption ;
                             tags = vinfo.tags ;
                             name = vinfo.name ;
                             chunkCount = vinfo.chunkCount ;
                         });
        /*
        state.eventLog.add({time=now;
                            kind=#emitSignal(
                              #viralSong{
                                  song=song;
                                  uploader=vinfo.userId;
                                  superLikers=superLikers.toArray()}
                            )});*/
        let score = Option.get(state.rewards.get(vinfo.userId), 0);
        state.rewards.put(vinfo.userId, score + Param.rewardsForUploader);
        state.eventCount += 1;
        state.messages.put(vinfo.userId,
                           { id = state.eventCount;
                             time = now;
                             event = #uploadReward {
                                 rewards = Param.rewardsForUploader;
                                 songId = song;
                             }
                           });
        for (id in superLikers.vals()) {
            let score = Option.get(state.rewards.get(id.user), 0);
            state.rewards.put(id.user, score + Param.rewardsForSuperliker);
            state.eventCount += 1;
            state.messages.put(id.user,
                               { id = state.eventCount;
                                 time = now;
                                 event = #superlikerReward {
                                     rewards = Param.rewardsForSuperliker;
                                     songId = song;
                                 }
                               });
        };
    }
  };

  public query(msg) func getMessages(user: UserId) : async ?[Types.Message] {
    do ? {
      accessCheck(msg.caller, #view, #user user)!;
      state.messages.get0(user)
    }
  };

  public query(msg) func isDropDay() : async ?Bool {
    do ? {
      let now = timeNow_();
      now % (Param.dropDayDuration + Param.dropDayNextDuration) < Param.dropDayDuration
    }
  };

  public query(msg) func getSuperLikeValidNow(source : UserId, target : SongId) : async ?Bool {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      getSuperLikeValidNow_(source, target)
    }
  };

  public query(msg) func getIsSuperLiker(source : UserId, target : SongId) : async ?Bool {
    do ? {
      accessCheck(msg.caller, #view, #user target)!;
      state.superLikes.isMember(source, target)
    }
  };

  func putSuperLike_(userId : UserId, songId : SongId, superLikes_ : Bool) : ?() {
    do ? {
      let _ = state.songs.get(songId)!; // assert that the songId is valid
      if superLikes_ {
        if (getSuperLikeValidNow_(userId, songId)) {
          state.superLikes.put(userId, songId);

          checkEmitSongViral_(songId);
        } else {

          return null // fail
        }
      } else {
        state.superLikes.delete(userId, songId);
       
      }
    }
  };

  public shared(msg) func putSuperLike
    (userId : UserId, songId : SongId, willSuperLike : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      putSuperLike_(userId, songId, willSuperLike)!
    }
  };

  public shared(msg) func putProfileSongLike
    (userId : UserId, songId : SongId, willLike_ : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      if willLike_ {
        state.likes.put(userId, songId);
      } else {
        state.likes.delete(userId, songId)
      };
      
    }
  };

  func putProfileFollow_
    (userId : UserId, followedBy : UserId, follows : Bool) : ?() {
    if (userId == followedBy) { return null };
    if follows {
      state.follows.put(userId, followedBy)
    } else {
      state.follows.delete(userId, followedBy)
    };
    ?()
  };

  public shared(msg) func putProfileFollow
    (userId : UserId, toFollow : UserId, follows : Bool) : async ?() {
    do ? {
      accessCheck(msg.caller, #update, #user userId)!;
      putProfileFollow_(userId, toFollow, follows)!
    }
  };

  // internal function for adding metadata
  func createSong_(i : SongInit) : ?SongId {
    let now = timeNow_();
    let songId = i.userId # "-" # i.name # "-" # (Int.toText(now));
    switch (state.songs.get(songId)) {
    case (?_) { /* error -- ID already taken. */ null };
    case null { /* ok, not taken yet. */
           state.songs.put(songId,
                            {
                              songId = songId;
                              userId = i.userId ;
                              name = i.name ;
                              createdAt = i.createdAt ;
                              uploadedAt = now ;
                              viralAt = null ;
                              caption =  i.caption ;
                              chunkCount = i.chunkCount ;
                              tags = i.tags ;
                              listenCount = 0 ;
                            });
           state.uploaded.put(i.userId, songId);
          
           ?songId
         };
    }
  };

  public shared(msg) func createSong(i : SongInit) : async ?SongId {
    do ? {
      createSong_(i)!
    }
  };

  func getSongInfo_ (caller : ?UserId, songId : SongId) : ?SongInfo {
    do ? {
      let v = state.songs.get(songId)!;
      {
        songId = songId;
        pic = state.songPics.get(songId);
        userId = v.userId ;
        createdAt = v.createdAt ;
        uploadedAt = v.uploadedAt ;
        viralAt = v.viralAt ;
        caption = v.caption ;
        tags = v.tags ;
        likes = state.likes.get1(songId);
        superLikes = state.superLikes.get1(songId);
        listenCount = v.listenCount ;
        name = v.name ;
        chunkCount = v.chunkCount ;
        // This implementation makes public all users who flagged every song,
        // but if that information should be kept private, get song info
        // could return just whether the calling user flagged it.
        viewerHasFlagged = do ? {
          state.abuseFlagSongs.isMember(caller!, songId) ;
        };
        abuseFlagCount = state.abuseFlagSongs.get1Size(songId);
      }
    }
  };

  public query(msg) func getSongInfo (caller : ?UserId, target : SongId) : async ?SongInfo {
    do ? {
      switch caller {
        case null { getSongInfo_(null, target)! };
        case (?callerUserName) {
               // has private access to our caller view?
               accessCheck(msg.caller, #update, #user callerUserName)!;
               getSongInfo_(?callerUserName, target)!
             };
      }
    }
  };

  public query(msg) func getSongPic(songId : SongId) : async ?SongPic {
    do ? {
      state.songPics.get(songId)!
    }
  };

  public shared(msg) func putSongInfo(songId : SongId, songInit : SongInit) : async ?() {
    do ? {
      let i = songInit ;
      let v = state.songs.get(songId)!;
      state.songs.put(songId,
                       {
                         // some fields are "immutable", regardless of caller data:
                         userId = v.userId ;
                         uploadedAt = v.uploadedAt ;
                         listenCount = v.listenCount ;
                         songId = songId ;
                         // -- above uses old data ; below is from caller --
                         createdAt = i.createdAt ;
                         viralAt = null;
                         caption = i.caption ;
                         tags = i.tags ;
                         name = i.name ;
                         chunkCount = i.chunkCount ;
                       })
    }
  };

  /// An abuse flag for a song occurs when a reporting user
  /// sets or clears the abuse toggle in their UI for the song.
  public shared (msg) func putAbuseFlagSong
    (reporter : UserId, target : SongId, abuseFlag : Bool) : async ?() {
    do ? {

      if abuseFlag {
        state.abuseFlagSongs.put(reporter, target)
      } else {
        state.abuseFlagSongs.delete(reporter, target)
      };
    }
  };

  /// An abuse flag for a user occurs when a reporting user
  /// sets or clears the abuse toggle in their UI for the target user.
  public shared(msg) func putAbuseFlagUser
    (reporter : UserId, target : UserId, abuseFlag : Bool) : async ?() {
    do ? {

      if abuseFlag {
        state.abuseFlagUsers.put(reporter, target)
      } else {
        state.abuseFlagUsers.delete(reporter, target)
      }
    }
  };

  public shared(msg) func putSongPic(songId : SongId, pic : ?SongPic) : async ?() {
    do ? {
      switch pic {
      case (?pic) { state.songPics.put(songId, pic) };
      case null {
             switch (state.songPics.remove(songId)) {
             case null { /* not found */ return null };
             case _ { /* found and removed. */ };
             }
           };
      }
    }
  };

  func chunkId(songId : SongId, chunkNum : Nat) : ChunkId {
    songId # (Nat.toText(chunkNum))
  };

  public shared(msg) func putSongChunk
    (songId : SongId, chunkNum : Nat, chunkData : [Nat8]) : async ?()
  {
    do ? {
      state.chunks.put(chunkId(songId, chunkNum), chunkData);
    }
  };

  public query(msg) func getSongChunk(songId : SongId, chunkNum : Nat) : async ?[Nat8] {
    do ? {
      state.chunks.get(chunkId(songId, chunkNum))!
    }
  };

  func createTestData_(users : [UserId], songs : [(UserId, SongId)]) : ?() {
    do ? {
      for (u in users.vals()) {
        createProfile_(u, null, null)!;
      };
      for ((u, v) in songs.vals()) {
        let _ = createSong_(
          {userId = u ;
           name = v ;
           createdAt = timeNow_() ;
           chunkCount = 0;
           caption = "";
           tags = [ ];})!;
      };
    }
  };

  public shared(msg) func createTestData(users : [UserId], songs : [(UserId, SongId)]) : async ?() {
    do ? {
      createTestData_(users, songs)!
    }
  };

  public shared(msg) func putTestFollows(follows : [(UserId, UserId)]) : async ?() {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      for ((u, v) in follows.vals()) {
        let _ = putProfileFollow_(u, v, true)!;
      }
    }
  };
 

 

  func doDemo_(script : [Demo.Command]) : Demo.Trace {
    let trace = Buffer.Buffer<Demo.TraceCommand>(0);
    let r = do ? {
      for (cmd in script.vals()) {
        switch cmd {
        case (#reset(tm)) {
               reset_(tm); // discards trace
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#createTestData(td)) {
               let _ = createTestData_(td.users, td.songs)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#putSuperLike(sl)) {
               let _ = putSuperLike_(sl.userId, sl.songId, sl.superLikes)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#putProfileFollow(pf)) {
               let _ = putProfileFollow_(pf.userId, pf.toFollow, pf.follows)!;
               trace.add({ command = cmd ;
                           result = #ok });
             };
        case (#assertSongFeed(vp)) {
               let vs : [SongResult] = getFeedSongs_(vp.userId, vp.limit)!;
               let ids = Array.map<SongResult, SongId>
               (vs, func(vr : SongResult) : SongId { vr.0.songId });
               let b = switch (vp.songsPred) {
                 case (#equals(expected)) {
                        Array.equal<SongId>(ids, expected, Text.equal)
                      };
                 case (#containsAll(members)) {
                        Base.Array.containsAll<SongId>(ids, members, Text.equal)
                      };
               };
               if b {
                 trace.add({ command = cmd ;
                             result = #ok });
               } else {
                 trace.add({ command = cmd ;
                             result = #err "song feed assertion failed"});
               }
             };
        case (#assertSongVirality(avv)) {
               if (songIsViral(avv.songId) == avv.isViral) {
                 trace.add({ command = cmd ;
                             result = #ok });
               } else {
                 trace.add({ command = cmd ;
                             result = #err "viral assertion failed"});
               }
             };
        case (#putRewardTransfer(sra)) {
              switch (putRewardTransfer_(sra.sender, sra.receiver, sra.amount)) {
                case null {
                   trace.add({ command = cmd ;
                               result = #err "insufficient rewards"});
                };
                case (?()) {
                   trace.add({ command = cmd ;
                               result = #ok });
                }
              }
           };
        };
      };
    };
    // from option monad (above) to trace monad (below)
    let t = trace.toArray();
    switch r {
    case null { { status = #err ; trace = t } };
    case _ { { status = #ok ; trace = t } };
    }
  };


  //HTTP
  type HeaderField = (Text, Text);
  type HttpResponse = {
    status_code: Nat16;
    headers: [HeaderField];
    body: Blob;
  };
  type HttpRequest = {
    method : Text;
    url : Text;
    headers : [HeaderField];
    body : Blob;
  };

  public query func http_request(request : HttpRequest) : async HttpResponse {
        return {
          status_code = 200;
          headers = [("content-type", "text/plain")];
          body = Text.encodeUtf8 (
            "SoundNodes NFT Music Cycle Balance:                            ~" # debug_show (Cycles.balance()/1000000000000) # "T" 
          )
        };
    };

  public shared(msg) func doDemo(script : [Demo.Command]) : async ?Demo.Trace {
    do ? {
      accessCheck(msg.caller, #admin, #all)!;
      doDemo_(script)
    }
  };
}
