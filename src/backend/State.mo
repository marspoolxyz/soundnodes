import Hash "mo:base/Hash";
import Prelude "mo:base/Prelude";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";

// import non-base primitives
import Access "Access";
import Role "Role";
import Rel "Rel";
import RelObj "RelObj";

// types in separate file
import Types "./Types";

/// Internal CanCan canister state.
module {

  // Our representation of (binary) relations.
  public type RelShared<X, Y> = Rel.RelShared<X, Y>;
  public type Rel<X, Y> = RelObj.RelObj<X, Y>;

  // Our representation of finite mappings.
  public type MapShared<X, Y> = Trie.Trie<X, Y>;
  public type Map<X, Y> = TrieMap.TrieMap<X, Y>;

  public type ChunkId = Types.ChunkId;
  public type ChunkData = Types.ChunkData;

  public module Event {

    public type CreateProfile = {
      userName : Text;
      pic: ?Types.ProfilePic;
    };

    public type CreateSong = {
      info : Types.SongInit;
    };

    public type LikeSong = {
      source : Types.UserId;
      target : Types.SongId;
      likes : Bool; // false for an "unlike" event
    };

    public type SuperLikeSong = {
      source : Types.UserId;
      target : Types.SongId;
      superLikes : Bool; // false for an "un-Super-like" event
    };

    public type RewardPointTransfer = {
      sender : Types.UserId;
      receiver : Types.UserId;
      amount : Nat;
    };

    public type SuperLikeSongFail = {
      source : Types.UserId;
      target : Types.SongId;
    };

    /// A viral song signal.
    public type ViralSong = {
      song : Types.SongId;
      uploader : Types.UserId;
      superLikers : [ViralSongSuperLiker];
    };

    /// A viral song signal query.
    public type ViralSongQuery = {
      song : Types.SongId;
    };

    /// A viral song's super liker is credited
    // based on time relative to other super likers.
    public type ViralSongSuperLiker = {
      user : Types.UserId ;
      time : Int ;
    };

    /// A signal precipitates further autonomous events.
    /// (Like an "event continuation" within the DSL of events).
    public type Signal = {
      #viralSong : ViralSong;
    };

    public type SignalQuery = {
      #viralSong : ViralSongQuery
    };

    /// An abuse flag event occurs when a reporting user
    /// sets or clears the abuse toggle in their UI for a song or user.
    public type AbuseFlag = {
      reporter : Types.UserId;
      target : {
        #song : Types.SongId;
        #user : Types.UserId;
      };
      flag : Bool;
    };

    public type EventKind = {
      #reset : Types.TimeMode;
      #createProfile : CreateProfile;
      #createSong : CreateSong;
      #likeSong : LikeSong;
      #superLikeSong : SuperLikeSong;
      #superLikeSongFail : SuperLikeSongFail;
      #rewardPointTransfer : RewardPointTransfer;
      #emitSignal : Signal;
      #abuseFlag : AbuseFlag;
    };

    public type Event = {
      id : Nat; // unique ID, to avoid using time as one (not always unique)
      time : Int; // using mo:base/Time and Time.now() : Int
      kind : EventKind;
    };

    public func equal(x:Event, y:Event) : Bool { x == y };
  };

  /// State (internal CanCan use only).
  ///
  /// Not a shared type because of OO containers and HO functions.
  /// So, cannot send in messages or store in stable memory.
  ///
  public type State = {
    access : Access.Access;

    /// event log.
    var eventCount : Nat;

    /// all profiles.
    profiles : Map<Types.UserId, Profile>;

    /// all profile pictures (aka thumbnails).
    profilePics : Map<Types.UserId, Types.ProfilePic>;

    rewards: Map<Types.UserId, Nat>;

    messages: Rel<Types.UserId, Types.Message>;

    /// all songs.
    songs : Map<Types.SongId, Song>;

    /// all song pictures (aka thumbnails).
    songPics : Map<Types.SongId, Types.SongPic>;

    /// follows relation: relates profiles and profiles.
    follows : Rel<Types.UserId, Types.UserId>;

    /// likes relation: relates profiles and songs.
    likes : Rel<Types.UserId, Types.SongId>;

    /// super likes relation: relates profiles and songs.
    superLikes : Rel<Types.UserId, Types.SongId>;

    /// uploaded relation: relates profiles and songs.
    uploaded : Rel<Types.UserId, Types.SongId>;

    /// all chunks.
    chunks : Map<Types.ChunkId, ChunkData>;

    /// Users may place an abuse flag on songs and other users.
    abuseFlagUsers : Rel<Types.UserId, Types.UserId>;
    abuseFlagSongs : Rel<Types.UserId, Types.SongId>;
  };

  // (shared) state.
  //
  // All fields have stable types.
  // This type can be stored in stable memory, for upgrades.
  //
  // All fields have shared types.
  // This type can be sent in messages.
  // (But messages may not benefit from tries; should instead use arrays).
  //
  public type StateShared = {
    /// all profiles.
    profiles : MapShared<Types.UserId, Profile>;

    /// all users. see andrew for disambiguation
    users : MapShared<Principal, Types.UserId>;

    /// all songs.
    songs : MapShared<Types.SongId, Song>;

    rewards: MapShared<Types.UserId, Nat>;

    /// follows relation: relates profiles and profiles.
    follows : RelShared<Types.UserId, Types.UserId>;

    /// likes relation: relates profiles and songs.
    likes : RelShared<Types.UserId, Types.SongId>;

    /// uploaded relation: relates profiles and songs.
    uploaded : RelShared<Types.UserId, Types.SongId>;

    /// all chunks.
    chunks : MapShared<Types.ChunkId, ChunkData>;
  };

  /// User profile.
  public type Profile = {
    userName : Text ;
    createdAt : Types.Timestamp;
  };

  /// Song.
  public type Song = {
    userId : Types.UserId;
    createdAt : Types.Timestamp;
    uploadedAt : Types.Timestamp;
    viralAt: ?Types.Timestamp;
    caption: Text;
    tags: [Text];
    listenCount: Nat;
    name: Text;
    chunkCount: Nat;
  };

  public func empty (init : { admin : Principal }) : State {
    let equal = (Text.equal, Text.equal);
    let hash = (Text.hash, Text.hash);
    func messageEqual(a: Types.Message, b: Types.Message) : Bool = a == b;
    func messageHash(m: Types.Message) : Hash.Hash = Int.hash(m.id); // id is unique, so hash is unique
    let uploaded_ = RelObj.RelObj<Types.UserId, Types.SongId>(hash, equal);
    let st : State = {
      access = Access.Access({ admin = init.admin ; uploaded = uploaded_ });
      profiles = TrieMap.TrieMap<Types.UserId, Profile>(Text.equal, Text.hash);
      rewards = TrieMap.TrieMap<Types.UserId, Nat>(Text.equal, Text.hash);
      messages = RelObj.RelObj((Text.hash, messageHash), (Text.equal, messageEqual));
      chunks = TrieMap.TrieMap<ChunkId, ChunkData>(Text.equal, Text.hash);
      profilePics = TrieMap.TrieMap<Types.UserId, Types.ProfilePic>(Text.equal, Text.hash);
      songs = TrieMap.TrieMap<Types.SongId, Song>(Text.equal, Text.hash);
      songPics = TrieMap.TrieMap<Types.SongId, Types.SongPic>(Text.equal, Text.hash);
      follows = RelObj.RelObj(hash, equal);
      likes = RelObj.RelObj(hash, equal);
      superLikes = RelObj.RelObj(hash, equal);
      uploaded = uploaded_;
      var eventCount = 0;
      abuseFlagSongs = RelObj.RelObj(hash, equal);
      abuseFlagUsers = RelObj.RelObj(hash, equal);
    };
    st
  };

  public func share(state : State) : StateShared {
    Prelude.nyi() // to do -- for testing / upgrades sub-story
  };

  public func fromShared(share : StateShared) : State {
    Prelude.nyi() // to do -- for testing / upgrades sub-story
  };

}
