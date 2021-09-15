/// Public-facing types.
module {

public type Timestamp = Int; // See mo:base/Time and Time.now()

public type SongId = Text; // chosen by createSong
public type UserId = Text; // chosen by createUser
public type ChunkId = Text; // SongId # (toText(ChunkNum))

public type ProfilePic = [Nat8]; // encoded as a PNG file
public type SongPic = [Nat8]; // encoded as a PNG file
public type ChunkData = [Nat8]; // encoded as ???

/// Role for a caller into the service API.
/// Common case is #user.
public type Role = {
  // caller is a user
  #user;
  // caller is the admin
  #admin;
  // caller is not yet a user; just a guest
  #guest
};

/// Action is an API call classification for access control logic.
public type UserAction = {
  /// Create a new user name, associated with a principal and role #user.
  #create;
  /// Update an existing profile, or add to its songs, etc.
  #update;
  /// View an existing profile, or its songs, etc.
  #view;
  /// Admin action, e.g., getting a dump of logs, etc
  #admin
};

/// An ActionTarget identifies the target of a UserAction.
public type ActionTarget = {
  /// User's profile or songs are all potential targets of action.
  #user : UserId ;
  /// Exactly one song is the target of the action.
  #song : SongId ;
  /// Everything is a potential target of the action.
  #all;
  /// Everything public is a potential target (of viewing only)
  #pubView
};

/// profile information provided by service to front end views -- Pic is separate query
public type ProfileInfo = {
 userName: Text;
 following: [UserId];
 followers: [UserId];
 uploadedSongs: [SongId];
 likedSongs: [SongId];
 hasPic: Bool;
 rewards: Nat;
 abuseFlagCount: Nat; // abuseFlags counts other users' flags on this profile, for possible blurring.
};

public type AllowanceBalance = {
  /// Non-zero balance of the given amount (the allowance unit varies by use).
  #nonZero : Nat;
  /// Zero now, and will be zero until the IC reaches the given time.
  #zeroUntil : Timestamp;
  /// No allowance at all, ever.
  #zeroForever
};

/// "Deeper" version of ProfileInfo.
///
/// Gives Song- and ProfileInfos instead of merely Ids in the results.
public type ProfileInfoPlus = {
  userName: Text;
 following: [ProfileInfo];
 followers: [ProfileInfo];
 uploadedSongs: [SongInfo];
 likedSongs: [SongInfo];
 hasPic: Bool;
 rewards: Nat;
 abuseFlagCount: Nat; // abuseFlags counts other users' flags on this profile, for possible blurring.
 /// viewerHasFlagged is
 /// ?true if we (the User requesting this profile) has flagged this profile for abuse.
 /// ?false if not, and
 /// null if no specific requesting user is defined by context.
 viewerHasFlagged: ?Bool;
 /// null if not giving a self view of the profile, otherwise, gives UserAllowances for userName.
 allowances: ?UserAllowances;
};

/// Some user actions may not occur more than X number of times per 24 hours.
/// Equivalently, these actions are limited by "allowances" that are replenished every 24 hours.
/// These allowances are quasi-private information, since they leak user data, indirectly.
public type UserAllowances = {
  abuseFlags : AllowanceBalance ;
  superLikes : AllowanceBalance ;
};

/// song information provided by front end to service, upon creation.
public type SongInit = {
 userId : UserId;
 name: Text;
 createdAt : Timestamp;
 caption: Text;
 tags: [Text];
 chunkCount: Nat;
};

/// song information provided by service to front end views -- Pic is separate query
public type SongInfo = {
 songId : SongId;
 userId : UserId;
 pic: ?SongPic;
 createdAt : Timestamp;
 uploadedAt : Timestamp;
 viralAt: ?Timestamp;
 caption: Text;
 tags: [Text];
 likes: [UserId];
 superLikes: [UserId];
 listenCount: Nat;
 name: Text;
 chunkCount: Nat;
 abuseFlagCount: Nat; // abuseFlags counts other users' flags on this profile, for possible blurring.
 /// viewerHasFlagged is
 /// ?true if we (the User requesting this profile) has flagged this profile for abuse.
 /// ?false if not, and
 /// null if no specific requesting user is defined by context.
 viewerHasFlagged: ?Bool; // true if we (the User requesting this profile) has flagged this profile for abuse.
};

public type SongResult = (SongInfo, ?SongPic);
public type SongResults = [SongResult];

/// Notification messages
public type Message = {
  id: Nat;
    time: Timestamp;
    event: Event;
};
public type Event = {
    #uploadReward: { rewards: Nat; songId: SongId };
    #superlikerReward: { rewards: Nat; songId: SongId };
    #transferReward: { rewards: Nat };
};

/// For test scripts, the script controls how time advances, and when.
/// For real deployment, the service uses the IC system as the time source.
public type TimeMode = { #ic ; #script : Int };

/// CanCan canister's service type.
///
/// #### Conventions
///
/// - The service (not front end) generates unique ids for new profiles and songs.
/// - (On behalf of the user, the front end chooses the created profile's `userName`, not `userId`).
/// - Shared functions return `null` when given invalid IDs, or when they suffer other failures.
/// - The `Pic` param for putting Songs and Profiles is optional, and can be put separately from the rest of the info.
///   This de-coupled design is closer to how the front end used BigMap in its initial (current) design.
///
/// #### Naming conventions:
///
///  - three prefixes: `create`, `get` and `put`.
///  - `create`- prefix only for id-generating functions (only two).
///  - `get`- prefix for (query) calls that only ready data.
///  - `put`- prefix for (update) calls that overwrite data.
///
public type Service = actor {

  createProfile : (userName : Text, pic : ?ProfilePic) -> async ?UserId;
  getProfileInfo : query (userId : UserId) -> async ?ProfileInfo;
  getProfilePlus : query (userId : UserId) -> async ?ProfileInfoPlus;
  getProfilePic : query (userId : UserId) -> async ?ProfilePic;
  putProfilePic : (userId : UserId, pic : ?ProfilePic) -> async ?();

  getFeedSongs : /*query*/ (userId : UserId, limit : ?Nat) -> async ?SongResults;
  getProfileSongs : /*query*/ (userId : UserId, limit : ?Nat) -> async ?SongResults;
  getSearchSongs : query (userId : UserId, terms : [Text], limit : ?Nat) -> async ?SongResults;

  putProfileSongLike : (userId : UserId, songId : SongId, likes : Bool) -> async ?();
  putProfileFollow : (userId : UserId, toFollow : UserId, follow : Bool) -> async ?();

  createSong : (songInfo : SongInfo) -> async ?SongId;

  getSongInfo : query (songId : SongId) -> async ?SongInfo;
  getSongPic  : query (songId : SongId) -> async ?SongPic;

  putSongInfo : (songId : SongId, songInfo : SongInfo) -> async ?();
  putSongPic  : (songId : SongId, pic : ?SongPic) -> async ?();

  putSongChunk : (songId : SongId, chunkNum : Nat, chunkData : ChunkData) -> async ?();
  getSongChunk : query (songId : SongId, chunkNum : Nat) -> async ?ChunkData;

};

}
